import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/workspace.dart';
import '../data/workspace_repository.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  return WorkspaceRepository();
});

final workspacesControllerProvider = AsyncNotifierProvider<WorkspacesController, List<Workspace>>(() {
  return WorkspacesController();
});

class WorkspacesController extends AsyncNotifier<List<Workspace>> {
  @override
  Future<List<Workspace>> build() async {
    final repo = ref.read(workspaceRepositoryProvider);
    
    final sub = repo.workspaceUpdates.listen((updatedWorkspace) {
      final currentList = state.valueOrNull;
      if (currentList != null) {
        final index = currentList.indexWhere((w) => w.id == updatedWorkspace.id);
        if (index != -1) {
          final newList = List<Workspace>.from(currentList);
          newList[index] = updatedWorkspace;
          state = AsyncData(newList);
        } else {
          state = AsyncData([...currentList, updatedWorkspace]);
        }
      }
    });
    
    ref.onDispose(() => sub.cancel());

    return repo.getWorkspaces();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(workspaceRepositoryProvider).getWorkspaces());
  }
}
