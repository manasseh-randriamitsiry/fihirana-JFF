import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final ColorController colorController = Get.find<ColorController>();
  MaplibreMapController? mapController;
  LatLng? _selectedLocation;
  Circle? _selectedCircle;

  // Default to Antananarivo, Madagascar if no location provided
  static const LatLng _defaultLocation = LatLng(-18.8792, 47.5079);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  void _onMapCreated(MaplibreMapController controller) {
    mapController = controller;
    if (_selectedLocation != null) {
      _addMarker(_selectedLocation!);
    }
  }

  void _onMapClick(Point<double> point, LatLng coordinates) {
    setState(() {
      _selectedLocation = coordinates;
    });
    _addMarker(coordinates);
  }

  Future<void> _addMarker(LatLng coordinates) async {
    if (mapController == null) return;

    if (_selectedCircle != null) {
      await mapController!.removeCircle(_selectedCircle!);
    }

    _selectedCircle = await mapController!.addCircle(
      CircleOptions(
        geometry: coordinates,
        circleColor: "#FF0000",
        circleRadius: 10,
        circleStrokeWidth: 2,
        circleStrokeColor: "#FFFFFF",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactLocation ?? 'Pick Location'),
        backgroundColor: colorController.backgroundColor.value,
        foregroundColor: colorController.textColor.value,
      ),
      body: Column(
        children: [
          Expanded(
            child: MaplibreMap(
              styleString: "https://tiles.openfreemap.org/styles/liberty",
              initialCameraPosition: CameraPosition(
                target: _selectedLocation ?? _defaultLocation,
                zoom: 13.0,
              ),
              onMapCreated: _onMapCreated,
              onMapClick: _onMapClick,
              myLocationEnabled: false,
              compassEnabled: true,
              attributionButtonMargins: const Point(-100, -100),
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer()),
                Factory<HorizontalDragGestureRecognizer>(
                    () => HorizontalDragGestureRecognizer()),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: colorController.backgroundColor.value,
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _selectedLocation == null
                    ? null
                    : () {
                        Navigator.pop(context, _selectedLocation);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorController.primaryColor.value,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
            ),
          ),
        ],
      ),
    );
  }
}
