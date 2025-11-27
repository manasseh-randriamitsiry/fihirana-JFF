import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController _searchController = TextEditingController();
  MaplibreMapController? mapController;
  LatLng? _selectedLocation;
  Circle? _selectedCircle;
  List<Map<String, dynamic>> _searchResults = [];

  // Default to Antananarivo, Madagascar if no location provided
  static const LatLng _defaultLocation = LatLng(-18.8792, 47.5079);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$encodedQuery&limit=5',
        ),
        headers: {'User-Agent': 'FihiranaApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        setState(() {
          _searchResults = results.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    final newLocation = LatLng(lat, lon);

    setState(() {
      _selectedLocation = newLocation;
      _searchResults = [];
      _searchController.clear();
    });

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newLocation, 15),
    );
    _addMarker(newLocation);
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                prefixIcon:
                    Icon(Icons.search, color: colorController.iconColor.value),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: colorController.iconColor.value),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorController.backgroundColor.value,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: colorController.primaryColor.value, width: 2),
                ),
              ),
              style: TextStyle(color: colorController.textColor.value),
              onChanged: (value) {
                setState(() {});
                _searchPlace(value);
              },
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colorController.backgroundColor.value,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
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
                    onTap: () => _selectSearchResult(result),
                  );
                },
              ),
            ),
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
