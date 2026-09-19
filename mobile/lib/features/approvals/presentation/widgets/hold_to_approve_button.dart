import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HoldToApproveButton extends StatefulWidget {
  final VoidCallback onApproved;
  final Duration holdDuration;

  const HoldToApproveButton({
    super.key,
    required this.onApproved,
    this.holdDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<HoldToApproveButton> createState() => _HoldToApproveButtonState();
}

class _HoldToApproveButtonState extends State<HoldToApproveButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isApproved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.holdDuration);
    _controller.addListener(() {
      setState(() {});
      if (_controller.value == 1.0 && !_isApproved) {
        _isApproved = true;
        widget.onApproved();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isApproved) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isApproved) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (!_isApproved) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _isApproved ? AppColors.success : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isApproved ? AppColors.success : AppColors.border,
          ),
        ),
        child: Stack(
          children: [
            // Progress Bar
            if (!_isApproved)
              FractionallySizedBox(
                widthFactor: _controller.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            // Text
            Center(
              child: Text(
                _isApproved ? 'Approved' : 'Hold to Approve',
                style: AppTypography.button.copyWith(
                  color: _isApproved ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
