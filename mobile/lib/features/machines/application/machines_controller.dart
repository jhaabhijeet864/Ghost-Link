import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/machine.dart';
import '../data/machine_repository.dart';

final machineRepositoryProvider = Provider<MachineRepository>((ref) {
  return MachineRepository();
});

final machinesControllerProvider = AsyncNotifierProvider<MachinesController, List<Machine>>(() {
  return MachinesController();
});

class MachinesController extends AsyncNotifier<List<Machine>> {
  @override
  Future<List<Machine>> build() async {
    // Also listen to real-time updates to invalidate or update the list
    final repo = ref.read(machineRepositoryProvider);
    
    // We can listen to machine updates and update state dynamically
    final sub = repo.machineUpdates.listen((updatedMachine) {
      final currentList = state.valueOrNull;
      if (currentList != null) {
        final index = currentList.indexWhere((m) => m.id == updatedMachine.id);
        if (index != -1) {
          final newList = List<Machine>.from(currentList);
          newList[index] = updatedMachine;
          state = AsyncData(newList);
        } else {
          state = AsyncData([...currentList, updatedMachine]);
        }
      }
    });
    
    ref.onDispose(() => sub.cancel());

    return repo.getMachines();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(machineRepositoryProvider).getMachines());
  }
}
