import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/skeleton_admin_list.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';

class AdminHymnListWidget extends StatelessWidget {
  final List<String> selectedHymns;
  final Function(String) onSelectionChanged;

  const AdminHymnListWidget({
    super.key,
    required this.selectedHymns,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Hymn>>(
      stream: HymnService().getFirebaseHymnsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('${l10n.error}: ${snapshot.error}',
                  style: TextStyle(color: colorController.textColor.value)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonAdminList();
        }

        final hymns = snapshot.data ?? [];
        hymns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (hymns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books_outlined,
                        size: 64,
                        color: colorController.textColor.value
                            .withValues(alpha: 0.3))
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .scale(
                        duration: const Duration(seconds: 2),
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        curve: Curves.easeInOut),
                const SizedBox(height: 16),
                Text(
                  l10n.noHymns,
                  style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.7),
                      fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final hymn = hymns[index];
            final isSelected = selectedHymns.contains(hymn.id);

            return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: colorController.backgroundColor.value,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Checkbox(
                      value: isSelected,
                      activeColor: colorController.primaryColor.value,
                      side: BorderSide(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.5)),
                      onChanged: (bool? value) {
                        onSelectionChanged(hymn.id);
                      },
                    ),
                    title: Text(
                      '${hymn.hymnNumber} - ${hymn.title}',
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.createdBy}: ${hymn.createdBy}',
                          style: TextStyle(
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.7)),
                        ),
                        if (hymn.createdByEmail != null)
                          Text(
                            l10n.emailLabel(hymn.createdByEmail!),
                            style: TextStyle(
                                color: colorController.textColor.value
                                    .withValues(alpha: 0.6),
                                fontSize: 12),
                          ),
                        Text(
                          '${l10n.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt)}',
                          style: TextStyle(
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.5),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: 50 * index))
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: 50 * index),
                        curve: Curves.easeOut));
          },
        );
      },
    );
  }
}
