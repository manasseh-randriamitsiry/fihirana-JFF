import 'package:flutter/material.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';

class HymnSearchPopup extends StatefulWidget {
  final ColorController colorController;
  final Function(Hymn) onHymnSelected;

  const HymnSearchPopup({
    super.key,
    required this.colorController,
    required this.onHymnSelected,
  });

  @override
  State<HymnSearchPopup> createState() => _HymnSearchPopupState();
}

class _HymnSearchPopupState extends State<HymnSearchPopup> {
  final HymnService _hymnService = HymnService();
  List<Hymn> _hymns = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _searchController.addListener(() {
      setState(() {
        _hasText = _searchController.text.isNotEmpty;
      });
    });
    _loadHymns();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHymns() async {
    try {
      final hymns = await _hymnService.searchHymns('');
      if (!mounted) return;
      setState(() {
        _hymns = hymns;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchHymns(String query) {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () async {
      try {
        final hymns = await _hymnService.searchHymns(query);
        if (!mounted) return;
        setState(() {
          _hymns = hymns;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Use dynamic colors or fallback to controller values if needed
    final surfaceColor = widget.colorController.backgroundColor.value;
    final onSurfaceColor = widget.colorController.textColor.value;
    
    // M3 Search Bar Colors
    // We want a "soft elevated container". 
    // Using Surface Container High (or similar) from M3.
    // If not available, mix primary with surface.
    final searchBarColor = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.08),
      surfaceColor,
    );


    return Dialog(
      backgroundColor: surfaceColor,
      elevation: 0, // We handle internal elevation
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Search Bar Component ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _isFocused 
                    ? searchBarColor 
                    : searchBarColor.withValues(alpha: 0.8), // Slightly transparent when unfocused
                borderRadius: BorderRadius.circular(28), // Fully rounded pill shape
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: onSurfaceColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: onSurfaceColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: l10n.searchHymns, // "Search hymns"
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: onSurfaceColor.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: onSurfaceColor,
                      ),
                      onChanged: _searchHymns,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_hasText)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _searchHymns('');
                        // Keep focus
                        _focusNode.requestFocus();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                         decoration: BoxDecoration(
                          color: onSurfaceColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: onSurfaceColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // --- List Results ---
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                  : _hymns.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 48, color: onSurfaceColor.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noHymnsFound,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: onSurfaceColor.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16), // Rounded list corners
                          child: ListView.builder(
                            key: const PageStorageKey('hymn_search_list'),
                            itemCount: _hymns.length,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final hymn = _hymns[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => widget.onHymnSelected(hymn),
                                  borderRadius: BorderRadius.circular(12),
                                  splashColor: colorScheme.primary.withValues(alpha: 0.1),
                                  highlightColor: colorScheme.primary.withValues(alpha: 0.05),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: onSurfaceColor.withValues(alpha: 0.05),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            hymn.hymnNumber,
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              color: colorScheme.onSecondaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                hymn.title,
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  color: onSurfaceColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              // Optional: Show snippet if search matched content?
                                              // For now, simple list.
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 20,
                                          color: onSurfaceColor.withValues(alpha: 0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
