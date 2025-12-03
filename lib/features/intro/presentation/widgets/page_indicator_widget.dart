import 'package:flutter/material.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const PageIndicatorWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: currentPage == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}