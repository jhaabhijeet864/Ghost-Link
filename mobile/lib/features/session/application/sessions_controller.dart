import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/active_agent_session.dart';
import '../data/session_repository.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

final sessionsControllerProvider = AsyncNotifierProvider<SessionsController, List<ActiveAgentSession>>(() {
  return SessionsController();
});

class SessionsController extends AsyncNotifier<List<ActiveAgentSession>> {
  @override
  Future<List<ActiveAgentSession>> build() async {
    final repo = ref.read(sessionRepositoryProvider);
    
    final sub = repo.sessionUpdates.listen((updatedSession) {
      final currentList = state.valueOrNull;
      if (currentList != null) {
        final index = currentList.indexWhere((s) => s.sessionId == updatedSession.sessionId);
        if (index != -1) {
          final newList = List<ActiveAgentSession>.from(currentList);
          newList[index] = updatedSession;
          state = AsyncData(newList);
        } else {
          state = AsyncData([...currentList, updatedSession]);
        }
      }
    });
    
    ref.onDispose(() => sub.cancel());

    return repo.getSessions();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(sessionRepositoryProvider).getSessions());
  }
}
