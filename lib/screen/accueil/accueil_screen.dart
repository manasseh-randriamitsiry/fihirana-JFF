import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/hymn_controller.dart';
import '../../widgets/hymn_list_item.dart';
import '../../widgets/hymn_search_field.dart';
import '../../utility/navigation_utility.dart';
import '../../services/version_check_service.dart';
import '../../models/hymn.dart';

class AccueilScreen extends StatefulWidget {
  final Function() openDrawer;

  const AccueilScreen({
    super.key,
    required this.openDrawer,
  });

  @override
  AccueilScreenState createState() => AccueilScreenState();
}

class AccueilScreenState extends State<AccueilScreen> {
  final HymnController _hymnController = Get.put(HymnController());
  bool _updateAvailable = false;
  
  // Cache expensive objects
  late final NeumorphicThemeData _lightTheme;
  late final NeumorphicThemeData _darkTheme;
  late TextStyle _defaultTextStyle;
  Color? _cachedTextColor;
  Color? _cachedBackgroundColor;
  Color? _cachedIconColor;

  @override
  void initState() {
    super.initState();
    _initializeThemes();

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    });
  }

  void _initializeThemes() {
    final colorController = Get.find<ColorController>();
    _lightTheme = colorController.getNeumorphicLightTheme();
    _darkTheme = colorController.getNeumorphicDarkTheme();
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateAvailable =
          await VersionCheckService.checkForUpdateManually();
      if (mounted) {
        setState(() {
          _updateAvailable = updateAvailable;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tsy afaka mijery rindrambaiko'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) {
        // Only update cached values when colors actually change
        final textColor = colorController.textColor.value;
        final backgroundColor = colorController.backgroundColor.value;
        final iconColor = colorController.iconColor.value;
        
        if (_cachedTextColor != textColor || 
            _cachedBackgroundColor != backgroundColor || 
            _cachedIconColor != iconColor) {
          _cachedTextColor = textColor;
          _cachedBackgroundColor = backgroundColor;
          _cachedIconColor = iconColor;
          _defaultTextStyle = TextStyle(color: textColor, inherit: true);
        }

        return NeumorphicTheme(
          themeMode: colorController.themeMode,
          theme: _lightTheme,
          darkTheme: _darkTheme,
          child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: AppBar(
              backgroundColor: backgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(Icons.menu, color: iconColor),
                onPressed: widget.openDrawer,
              ),
              title: Text(
                'JFF',
                style: _defaultTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
              actions: [
                if (_updateAvailable)
                  IconButton(
                    icon: const Icon(Icons.system_update, color: Colors.orange),
                    onPressed: _checkForUpdates,
                  ),
                IconButton(
                  icon: Icon(Icons.favorite, color: iconColor),
                  onPressed: () => NavigationUtility.navigateToFavorites(),
                ),
              ],
            ),
            body: Column(
              children: [
                HymnSearchField(
                  controller: _hymnController.searchController,
                  defaultTextStyle: _defaultTextStyle,
                  textColor: textColor,
                  iconColor: iconColor,
                  backgroundColor: backgroundColor,
                  onChanged: () {
                    _hymnController.update();
                    setState(() {});
                  },
                ),
                Expanded(
                  child: GetBuilder<HymnController>(
                    builder: (controller) {
                      final hymns = controller.filterHymnList([]);
                      if (hymns.isEmpty) {
                        return Center(
                          child: Text(
                            'Mandatsa ny data...',
                            style: _defaultTextStyle,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: hymns.length,
                        itemBuilder: (context, index) {
                          final hymn = hymns[index];
                          return HymnListItem(
                            hymn: hymn,
                            textColor: textColor,
                            backgroundColor: backgroundColor,
                            onFavoritePressed: () =>
                                controller.toggleFavorite(hymn),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
