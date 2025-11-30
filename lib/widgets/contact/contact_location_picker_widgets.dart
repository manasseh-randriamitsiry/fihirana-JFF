import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';

class LocationSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<Map<String, dynamic>> searchResults;
  final Function(Map<String, dynamic>) onResultSelected;
  final VoidCallback onClear;

  const LocationSearchWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.searchResults,
    required this.onResultSelected,
    required this.onClear,
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchForAPlace,
              prefixIcon: Icon(Icons.search, color: colorController.iconColor.value),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: colorController.iconColor.value),
                      onPressed: widget.onClear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: colorController.textColor.value),
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: colorController.backgroundColor.value.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.searchResults.length,
              itemBuilder: (context, index) {
                final result = widget.searchResults[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    result['display_name'],
                    style: TextStyle(
                        color: colorController.textColor.value, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: Icon(Icons.location_on,
                      color: colorController.primaryColor.value, size: 20),
                  onTap: () => widget.onResultSelected(result),
                );
              },
            ),
          ),
      ],
    );
  }
}

class LocationConfirmButtonWidget extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const LocationConfirmButtonWidget({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorController.primaryColor.value,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Confirm Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}