import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManualConnectDialog extends StatefulWidget {
  final Function(String ip, String port, String? token) onConnect;

  const ManualConnectDialog({super.key, required this.onConnect});

  @override
  State<ManualConnectDialog> createState() => _ManualConnectDialogState();
}

class _ManualConnectDialogState extends State<ManualConnectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController(text: '127.0.0.1');
  final _portController = TextEditingController(text: '8080');
  final _tokenController = TextEditingController();
  String? _urlParseError;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;

    if (text.startsWith('localloop://pair')) {
      try {
        final uri = Uri.parse(text);
        final ip = uri.queryParameters['ip'];
        final port = uri.queryParameters['port'];
        final token = uri.queryParameters['token'];

        setState(() {
          if (ip != null) _ipController.text = ip;
          if (port != null) _portController.text = port;
          if (token != null) _tokenController.text = token;
          _urlParseError = null;
        });
      } catch (e) {
        setState(() => _urlParseError = 'Invalid pairing URI format');
      }
    } else {
      // Treat as raw token or IP
      if (text.contains('.')) {
        setState(() => _ipController.text = text);
      } else {
        setState(() => _tokenController.text = text);
      }
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final ip = _ipController.text.trim();
      final port = _portController.text.trim();
      final token = _tokenController.text.trim().isEmpty ? null : _tokenController.text.trim();

      Navigator.of(context).pop();
      widget.onConnect(ip, port, token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF13161C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF222733)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.settings_ethernet, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Manual Connection',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_urlParseError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0D0D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _urlParseError!,
                    style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
                  ),
                ),
              // Paste URI banner button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.content_paste, size: 16),
                  label: const Text('Paste Pairing URL / Token'),
                  onPressed: _pasteFromClipboard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF90CAF9),
                    side: const BorderSide(color: Color(0xFF1E3A5F)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Host IP
              TextFormField(
                controller: _ipController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Workstation IP Address',
                  hintText: '192.168.1.X or 127.0.0.1',
                  prefixIcon: Icon(Icons.wifi, size: 18, color: Color(0xFF8A94A6)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'IP Address is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Port
              TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8080',
                  prefixIcon: Icon(Icons.numbers, size: 18, color: Color(0xFF8A94A6)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Port is required';
                  final p = int.tryParse(val.trim());
                  if (p == null || p <= 0 || p > 65535) return 'Valid port (1-65535)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Pairing Secret Token
              TextFormField(
                controller: _tokenController,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: 'Pairing Secret (Optional for reconnect)',
                  hintText: 'One-time token from desktop QR',
                  prefixIcon: Icon(Icons.key, size: 18, color: Color(0xFF8A94A6)),
                ),
              ),
              const SizedBox(height: 14),
              // Quick Localhost button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.developer_board, size: 16, color: Color(0xFF8A94A6)),
                  label: const Text(
                    'Quick Connect: 127.0.0.1:8080',
                    style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                  ),
                  onPressed: () {
                    _ipController.text = '127.0.0.1';
                    _portController.text = '8080';
                    _submit();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A94A6))),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF090A0C),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
