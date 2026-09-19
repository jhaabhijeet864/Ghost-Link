import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/approval_intent.dart';
import '../data/approval_repository.dart';

final approvalRepositoryProvider = Provider((ref) => ApprovalRepository());

final approvalsControllerProvider = AsyncNotifierProvider<ApprovalsController, List<ApprovalIntent>>(() {
  return ApprovalsController();
});

class ApprovalsController extends AsyncNotifier<List<ApprovalIntent>> {
  @override
  Future<List<ApprovalIntent>> build() async {
    final repository = ref.read(approvalRepositoryProvider);
    
    // Listen to stream for future updates
    repository.pendingApprovals.listen((approvals) {
      state = AsyncValue.data(approvals);
    });
    
    return [];
  }

  Future<void> respondToApproval(String intentId, bool approved) async {
    final repository = ref.read(approvalRepositoryProvider);
    await repository.sendApprovalResponse(intentId, approved);
  }
}
