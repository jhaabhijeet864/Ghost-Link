import 'dart:io';
import '../security/crypto_manager.dart';
import '../../data/database/isolate_worker.dart';
import 'signed_envelope.dart';
import 'dart:convert';
import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';

enum ConnectionStatus { disconnected, connecting, authenticating, connected }

class WebSocketClient {
  WebSocket? _socket;
  final CryptoManager _cryptoManager = CryptoManager();
  late final SignedEnvelope _signedEnvelope = SignedEnvelope(_cryptoManager);

  ConnectionStatus _status = ConnectionStatus.disconnected;
  ConnectionStatus get status => _status;

  final StreamController<ConnectionStatus> _statusController = StreamController.broadcast();
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _approvalController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get approvalStream => _approvalController.stream;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  String? _lastIp;
  String? _lastPort;
  String? _lastPairingSecret;
  void Function(String newIp, String newPort)? _onEndpointResolved;

  Future<({String ip, String port, String? machineName})?> _discoverEndpoint(String serviceName) async {
    const String name = '_localloop._tcp.local';
    final MDnsClient client = MDnsClient();
    await client.start();

    try {
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target))) {
            return (ip: ip.address.address, port: srv.port.toString(), machineName: ptr.domainName);
          }
        }
      }
    } catch (_) {
      // Ignore discovery errors
    } finally {
      client.stop();
    }
    return null;
  }

  Future<void> connect(
    String ip,
    String port, [
    String? pairingSecret,
    void Function(String newIp, String newPort)? onEndpointResolved,
  ]) async {
    _lastIp = ip;
    _lastPort = port;
    _lastPairingSecret = pairingSecret;
    _onEndpointResolved = onEndpointResolved;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    await _initiateConnection();
  }

  Future<void> _initiateConnection() async {
    if (_status == ConnectionStatus.connecting || _status == ConnectionStatus.connected) return;
    _setStatus(ConnectionStatus.connecting);

    final publicKey = await _cryptoManager.getPublicKeyBase64();
    String targetIp = _lastIp ?? '127.0.0.1';
    String targetPort = _lastPort ?? '8080';
    Uri? uri;
    bool resolvedViaMdns = false;

    // Attempt connecting to cached IP first
    try {
      uri = _buildUri(targetIp, targetPort, publicKey, _lastPairingSecret);
      _socket = await WebSocket.connect(uri.toString()).timeout(const Duration(seconds: 2));
    } catch (_) {
      // If direct connection fails, try mDNS discovery
      final endpoint = await _discoverEndpoint('_localloop._tcp.local');
      if (endpoint != null) {
        targetIp = endpoint.ip;
        targetPort = endpoint.port;
        resolvedViaMdns = true;
        uri = _buildUri(targetIp, targetPort, publicKey, _lastPairingSecret);
        try {
          _socket = await WebSocket.connect(uri.toString()).timeout(const Duration(seconds: 5));
        } catch (e) {
          _scheduleReconnect();
          throw Exception("Could not connect to discovered LocalLoop endpoint.");
        }
      } else {
        _scheduleReconnect();
        throw Exception("Could not discover or connect to LocalLoop on the local network.");
      }
    }

    if (resolvedViaMdns && _onEndpointResolved != null) {
      _onEndpointResolved!(targetIp, targetPort);
    }

    _setStatus(ConnectionStatus.authenticating);
    final Completer<void> authCompleter = Completer<void>();

    _socket!.listen(
      (message) async {
        try {
          final Map<String, dynamic> data = jsonDecode(message);
          final type = data['type'] as String?;

          if (type == 'auth_challenge') {
            final challenge = data['challenge'] as String;
            final signature = await _cryptoManager.signToken(challenge);
            _socket!.add(jsonEncode({
              'type': 'auth_response',
              'signature': signature,
            }));
          } else if (type == 'auth_ack') {
            _setStatus(ConnectionStatus.connected);
            _reconnectAttempts = 0;
            _startHeartbeat();
            if (!authCompleter.isCompleted) {
              authCompleter.complete();
            }
          } else if (type == 'pong') {
            // Heartbeat response
          } else {
            // Normal message routing
            if (type == 'approval_request') {
              _approvalController.add(data);
            } else {
              _messageController.add(data);
              TelemetryIngestQueue().enqueue(data);
            }
          }
        } catch (_) {}
      },
      onDone: _handleSocketClosed,
      onError: (_) => _handleSocketClosed(),
      cancelOnError: true,
    );

    // Wait for the server to acknowledge authentication
    await authCompleter.future.timeout(const Duration(seconds: 5), onTimeout: () {
      _handleSocketClosed();
      throw Exception("Authentication timeout.");
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_status == ConnectionStatus.connected && _socket != null) {
        try {
          _socket!.add(jsonEncode({
            'type': 'ping',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));
        } catch (_) {
          _handleSocketClosed();
        }
      }
    });
  }

  void _handleSocketClosed() {
    _heartbeatTimer?.cancel();
    _socket?.close();
    _socket = null;
    _setStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final delaySeconds = (1 << _reconnectAttempts).clamp(1, 16);
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (_status == ConnectionStatus.disconnected && _lastIp != null) {
        _initiateConnection().catchError((_) {});
      }
    });
  }

  void _setStatus(ConnectionStatus s) {
    _status = s;
    _statusController.add(s);
  }

  Uri _buildUri(String ip, String port, String publicKey, String? pairingSecret) {
    var uriStr = 'ws://$ip:$port?publicKey=${Uri.encodeQueryComponent(publicKey)}';
    if (pairingSecret != null) {
      uriStr += '&pairingSecret=${Uri.encodeQueryComponent(pairingSecret)}';
    }
    return Uri.parse(uriStr);
  }

  Future<void> sendCommand(Map<String, dynamic> command) async {
    final envelope = await _signedEnvelope.seal('command_request', command);
    _socket?.add(jsonEncode(envelope));
  }

  Future<void> sendApprovalResponse(Map<String, dynamic> response) async {
    final envelope = await _signedEnvelope.seal('approval_response', response);
    _socket?.add(jsonEncode(envelope));
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _socket?.close();
    _setStatus(ConnectionStatus.disconnected);
    _messageController.close();
    _approvalController.close();
    _statusController.close();
    TelemetryIngestQueue().flush();
  }
}
