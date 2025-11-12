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

  @override
  void initState() {
    super.initState();

    VersionCheckService.setOnUpdateAvailableCallback(() {
      if (mounted) {
        setState(() {
          _updateAvailable = true;
        });
      }
    });
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
      builder: (colorController) => Obx(() {
        final textColor = colorController.textColor.value;
        final accentColor = colorController.accentColor.value;
        final backgroundColor = colorController.backgroundColor.value;
        final iconColor = colorController.iconColor.value;
        final defaultTextStyle = TextStyle(color: textColor, inherit: true);

return NeumorphicTheme(
          themeMode: colorController.themeMode,
          theme: colorController.getNeumorphicLightTheme(),
          darkTheme: colorController.getNeumorphicDarkTheme(),
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
              style: defaultTextStyle.copyWith(
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
                defaultTextStyle: defaultTextStyle,
                textColor: textColor,
                iconColor: iconColor,
                backgroundColor: backgroundColor,
                onChanged: () => setState(() {}),
              ),
              Expanded(
                child: StreamBuilder<List<Hymn>>(
                  stream: _hymnController.hymnsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Nisy olana: ${snapshot.error}',
                          style: defaultTextStyle,
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final hymns =
                        _hymnController.filterHymnList(snapshot.data ?? []);
                    if (hymns.isEmpty) {
                      return Center(
                        child: Text(
                          'Tsy misy hira',
                          style: defaultTextStyle,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: hymns.length,
                      itemBuilder: (context, index) {
                        final hymn = hymns[index];
                        return StreamBuilder<Map<String, String>>(
                          stream: _hymnController.getFavoriteStatusStream(),
                          builder: (context, snapshot) {
                            return HymnListItem(
                              hymn: hymn,
                              textColor: textColor,
                              backgroundColor: backgroundColor,
                              onFavoritePressed: () =>
                                  _hymnController.toggleFavorite(hymn),
                            );
                          },
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
      }),
    );
  }
}
