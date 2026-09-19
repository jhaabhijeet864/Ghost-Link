import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';

class PairingFlowScreen extends StatefulWidget {
  const PairingFlowScreen({super.key});

  @override
  State<PairingFlowScreen> createState() => _PairingFlowScreenState();
}

class _PairingFlowScreenState extends State<PairingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pair Machine',
      showBackButton: true,
      onBack: _prevStep,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: [
          _buildStep1SelectMethod(),
          _buildStep2Scan(),
          _buildStep3Verify(),
          _buildStep4Permission(),
          _buildStep5Complete(),
        ],
      ),
    );
  }

  // Step 1: Select Method
  Widget _buildStep1SelectMethod() {
    return _buildStepContainer(
      title: 'Add a Windows machine',
      subtitle: 'Scan a QR code from the LocalLoop companion, or enter a short pairing code.',
      content: Column(
        children: [
          _buildLargeButton(
            icon: Icons.qr_code_scanner,
            title: 'Scan QR code',
            onTap: _nextStep,
          ),
          const SizedBox(height: AppSpacing.standard),
          _buildLargeButton(
            icon: Icons.keyboard,
            title: 'Enter pairing code',
            onTap: () {
              // Not implemented in mock
            },
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  // Step 2: Scan (Mocked)
  Widget _buildStep2Scan() {
    return _buildStepContainer(
      title: 'Scan QR Code',
      subtitle: 'Point your camera at the LocalLoop desktop app.',
      content: Column(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.camera_alt, size: 64, color: AppColors.textMuted),
                Positioned(
                  bottom: AppSpacing.standard,
                  child: ElevatedButton(
                    onPressed: _nextStep, // Mock successful scan
                    child: const Text('Mock: Scan Success'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          TextButton(
            onPressed: _prevStep,
            child: const Text('Enter code manually instead'),
          ),
        ],
      ),
    );
  }

  // Step 3: Verify Identity
  Widget _buildStep3Verify() {
    return _buildStepContainer(
      title: 'Confirm this is your machine',
      subtitle: 'Confirm the same phrase is shown on Windows.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.standard),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Machine: Rajesh-Workstation', style: AppTypography.body),
                const SizedBox(height: AppSpacing.small),
                Text('Connection: Local network', style: AppTypography.body),
                const SizedBox(height: AppSpacing.large),
                Text('Verification phrase:', style: AppTypography.caption),
                const SizedBox(height: 4),
                Text('BLUE RIVER 482', style: AppTypography.screenTitle.copyWith(color: AppColors.accent, letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.standard),
            ),
            child: const Text('Confirm and pair'),
          ),
        ],
      ),
    );
  }

  // Step 4: Permission Mode
  Widget _buildStep4Permission() {
    return _buildStepContainer(
      title: 'Choose initial access',
      subtitle: 'You can change this later in settings.',
      content: Column(
        children: [
          _buildPermissionCard(
            title: 'Observe only',
            description: 'View sessions, logs, tests, and diffs.',
            icon: Icons.visibility,
            onTap: _nextStep,
          ),
          const SizedBox(height: AppSpacing.standard),
          _buildPermissionCard(
            title: 'Observe and control',
            description: 'Send instructions and manage sessions.',
            icon: Icons.terminal,
            onTap: _nextStep,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  // Step 5: Completion
  Widget _buildStep5Complete() {
    return _buildStepContainer(
      title: 'Machine paired',
      subtitle: 'Rajesh-Workstation is ready.',
      icon: Icons.check_circle_outline,
      iconColor: AppColors.success,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Back to where we came from
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(AppSpacing.standard),
            ),
            child: const Text('Go to home'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget content,
    IconData? icon,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.standard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 64, color: iconColor ?? AppColors.textPrimary),
            const SizedBox(height: AppSpacing.large),
          ],
          Text(title, style: AppTypography.screenTitle),
          const SizedBox(height: AppSpacing.small),
          Text(subtitle, style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.large * 2),
          content,
        ],
      ),
    );
  }

  Widget _buildLargeButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.transparent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSecondary ? AppColors.border : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.textPrimary),
            const SizedBox(width: AppSpacing.standard),
            Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.standard),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDanger ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: isDanger ? AppColors.warning : AppColors.accent),
            const SizedBox(width: AppSpacing.standard),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
