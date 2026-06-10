import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class AppToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? subtitle;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool enabled;

  const AppToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.subtitle,
    this.activeColor,
    this.inactiveColor,
    this.enabled = true,
  });

  @override
  State<AppToggle> createState() => _AppToggleState();
}

class _AppToggleState extends State<AppToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDimensions.normal,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _updateAnimation();
  }

  @override
  void didUpdateWidget(AppToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.value) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return GestureDetector(
      onTap: widget.enabled && widget.onChanged != null
          ? () => widget.onChanged!(!widget.value)
          : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.label != null || widget.subtitle != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.label != null)
                              Text(
                                widget.label!,
                                style: TextStyle(
                                  color: colorController.textColor.value,
                                  fontSize: AppDimensions.fontMd,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (widget.subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  widget.subtitle!,
                                  style: TextStyle(
                                    color: colorController.textColor.value
                                        .withValues(alpha: 0.7),
                                    fontSize: AppDimensions.fontSm,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Container(
                      width: 52,
                      height: 32,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: widget.value
                            ? (widget.activeColor ??
                                    colorController.primaryColor.value)
                                .withValues(alpha: 0.2)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AnimatedAlign(
                        duration: AppDimensions.normal,
                        curve: Curves.easeInOut,
                        alignment: widget.value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: widget.value
                                ? (widget.activeColor ??
                                    colorController.primaryColor.value)
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.value ? Icons.check : Icons.close,
                            size: 16,
                            color: widget.value
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
