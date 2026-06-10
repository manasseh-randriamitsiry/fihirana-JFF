import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class AppSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final String? label;
  final String? subtitle;
  final String? valueDisplay;
  final bool showIncrementDecrement;
  final bool enabled;

  const AppSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.onChanged,
    this.onChangeEnd,
    this.label,
    this.subtitle,
    this.valueDisplay,
    this.showIncrementDecrement = false,
    this.enabled = true,
  });

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDimensions.fast,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _increment() {
    if (!widget.enabled || widget.onChanged == null) return;
    final newValue = (widget.value +
            (widget.divisions != null
                ? (widget.max - widget.min) / widget.divisions!
                : 0.1))
        .clamp(widget.min, widget.max);
    widget.onChanged!(newValue);
    widget.onChangeEnd?.call(newValue);
  }

  void _decrement() {
    if (!widget.enabled || widget.onChanged == null) return;
    final newValue = (widget.value -
            (widget.divisions != null
                ? (widget.max - widget.min) / widget.divisions!
                : 0.1))
        .clamp(widget.min, widget.max);
    widget.onChanged!(newValue);
    widget.onChangeEnd?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.label != null ||
                        widget.subtitle != null ||
                        widget.valueDisplay != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                    padding: const EdgeInsets.only(top: 2),
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
                          if (widget.valueDisplay != null)
                            Text(
                              widget.valueDisplay!,
                              style: TextStyle(
                                color: colorController.primaryColor.value,
                                fontSize: AppDimensions.fontMd,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      children: [
                        if (widget.showIncrementDecrement)
                          IconButton(
                            onPressed: widget.enabled ? _decrement : null,
                            icon: Icon(
                              Icons.remove_circle_outline,
                              color: widget.enabled
                                  ? colorController.primaryColor.value
                                  : colorController.textColor.value
                                      .withValues(alpha: 0.3),
                            ),
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 4,
                              activeTrackColor:
                                  colorController.primaryColor.value,
                              inactiveTrackColor: colorController
                                  .primaryColor.value
                                  .withValues(alpha: 0.2),
                              thumbColor: colorController.primaryColor.value,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                                elevation: 4,
                                pressedElevation: 8,
                              ),
                              overlayColor: colorController.primaryColor.value
                                  .withValues(alpha: 0.2),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 24),
                              valueIndicatorColor:
                                  colorController.primaryColor.value,
                              valueIndicatorTextStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Slider(
                              value: widget.value,
                              min: widget.min,
                              max: widget.max,
                              divisions: widget.divisions,
                              onChanged:
                                  widget.enabled ? widget.onChanged : null,
                              onChangeEnd: widget.onChangeEnd,
                            ),
                          ),
                        ),
                        if (widget.showIncrementDecrement)
                          IconButton(
                            onPressed: widget.enabled ? _increment : null,
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: widget.enabled
                                  ? colorController.primaryColor.value
                                  : colorController.textColor.value
                                      .withValues(alpha: 0.3),
                            ),
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                      ],
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
