import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: title != null
          ? AppBar(
              backgroundColor: AppColors.background,
              title: Text(
                title!,
                style: AppTypography.screenTitle,
              ),
              actions: actions,
              elevation: 0,
              automaticallyImplyLeading: showBackButton,
              leading: showBackButton 
                  ? BackButton(
                      color: AppColors.textPrimary,
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                    )
                  : null,
            )
          : null,
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
