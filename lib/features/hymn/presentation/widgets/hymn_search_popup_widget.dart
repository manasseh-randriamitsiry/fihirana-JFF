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

  @override
  void initState() {
    super.initState();
    _loadHymns();
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
    return AlertDialog(
      backgroundColor: widget.colorController.backgroundColor.value,
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHymns,
                hintStyle: TextStyle(
                  color: widget.colorController.textColor.value
                      .withValues(alpha: 0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: widget.colorController.textColor.value,
                ),
              ),
              style: TextStyle(
                color: widget.colorController.textColor.value,
              ),
              onChanged: _searchHymns,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hymns.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noHymnsFound,
                            style: TextStyle(
                              color: widget.colorController.textColor.value,
                            ),
                          ),
                        )
                      : ListView.builder(
                          key: const PageStorageKey('hymn_search_list'),
                          itemCount: _hymns.length,
                          itemBuilder: (context, index) {
                            final hymn = _hymns[index];
                            return ListTile(
                              key: ValueKey(hymn.id),
                              title: Text(
                                '${hymn.hymnNumber} - ${hymn.title}',
                                style: TextStyle(
                                  color: widget.colorController.textColor.value,
                                ),
                              ),
                              onTap: () {
                                widget.onHymnSelected(hymn);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
