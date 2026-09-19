import 'dart:async';
import 'dart:convert';
import '../../../core/network/websocket_client.dart';
import '../domain/approval_intent.dart';

class ApprovalRepository {
  final WebSocketClient _client = WebSocketClient();
  final _approvalsController = StreamController<List<ApprovalIntent>>.broadcast();
  
  final List<ApprovalIntent> _activeApprovals = [];

  ApprovalRepository() {
    _client.approvalStream.listen(_handleApprovalMessage);
  }

  Stream<List<ApprovalIntent>> get pendingApprovals => _approvalsController.stream;

  void _handleApprovalMessage(Map<String, dynamic> payload) {
    try {
      final rawData = payload['data'];
      Map<String, dynamic> intentMap;
      if (rawData is String) {
        intentMap = jsonDecode(rawData) as Map<String, dynamic>;
      } else if (rawData is Map<String, dynamic>) {
        intentMap = rawData;
      } else {
        return;
      }
      final intent = ApprovalIntent.fromJson(intentMap);
      
      // Check if it already exists
      final index = _activeApprovals.indexWhere((a) => a.intentId == intent.intentId);
      if (index == -1) {
        _activeApprovals.add(intent);
        _approvalsController.add(List.unmodifiable(_activeApprovals));
      }
    } catch (e) {
      // Ignored
    }
  }

  void removeApproval(String intentId) {
    _activeApprovals.removeWhere((a) => a.intentId == intentId);
    _approvalsController.add(List.unmodifiable(_activeApprovals));
  }

  Future<void> sendApprovalResponse(String intentId, bool approved) async {
    await _client.sendApprovalResponse({
      'intentId': intentId,
      'approved': approved,
    });
    removeApproval(intentId);
  }
}
