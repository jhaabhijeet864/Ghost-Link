import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import 'widgets/machine_card.dart';
import '../application/machines_controller.dart';

class MachinesListScreen extends ConsumerWidget {
  final Function(int) onNavigateTab;

  const MachinesListScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machinesAsyncValue = ref.watch(machinesControllerProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.standard),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Machines', style: AppTypography.screenTitle),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textPrimary),
                onPressed: () {
                  context.push('/pairing');
                },
                tooltip: 'Pair new machine',
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: machinesAsyncValue.when(
            data: (machines) {
              if (machines.isEmpty) {
                return Center(
                  child: Text('No machines found', style: AppTypography.secondary),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(machinesControllerProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard),
                  itemCount: machines.length,
                  itemBuilder: (context, index) {
                    final machine = machines[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.standard),
                      child: MachineCard(
                        name: machine.name,
                        isOnline: machine.status == 'Healthy' || machine.status == 'Active',
                        isBridgeReady: true,
                        activeSessions: 0,
                        lastSync: 'Updated just now',
                        onTap: () {
                          context.push('/machine/${machine.id}');
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => ErrorState(message: error.toString()),
          ),
        ),
      ],
    );
  }
}

