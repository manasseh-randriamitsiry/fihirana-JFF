import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/hymn_service.dart';
import '../../widgets/hymn_list_item.dart';

class FirebaseHymnsScreen extends StatefulWidget {
  const FirebaseHymnsScreen({super.key});

  @override
  State<FirebaseHymnsScreen> createState() => _FirebaseHymnsScreenState();
}

class _FirebaseHymnsScreenState extends State<FirebaseHymnsScreen> {
  final HymnService _hymnService = Get.find<HymnService>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (colorController) => Scaffold(
        backgroundColor: colorController.backgroundColor.value,
        appBar: AppBar(
          backgroundColor: colorController.backgroundColor.value,
          title: Text(
            'Fihirana Fanampiny',
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorController.iconColor.value),
            onPressed: () => Get.back(),
          ),
        ),
        body: StreamBuilder<List<Hymn>>(
          stream: _hymnService.getFirebaseHymnsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Nisy olana: ${snapshot.error}',
                  style: TextStyle(color: colorController.textColor.value),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final hymns = snapshot.data ?? [];
            if (hymns.isEmpty) {
              return Center(
                child: Text(
                  'Tsy misy hira fanampiny',
                  style: TextStyle(color: colorController.textColor.value),
                ),
              );
            }

            return ListView.builder(
              itemCount: hymns.length,
              itemBuilder: (context, index) {
                final hymn = hymns[index];
                return StreamBuilder<Map<String, String>>(
                  stream: _hymnService.getFavoriteStatusStream(),
                  builder: (context, snapshot) {
                    return HymnListItem(
                      hymn: hymn,
                      textColor: colorController.textColor.value,
                      backgroundColor: colorController.backgroundColor.value,
                      onFavoritePressed: () => _hymnService.toggleFavorite(hymn),
                      isFirebaseHymn: true,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
