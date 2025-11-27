import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../controller/color_controller.dart';
import '../../widgets/contact/location_picker_widgets.dart';


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
  MapLibreMapController? mapController;
  LatLng? _selectedLocation;
  Circle? _selectedCircle;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearchExpanded = false;

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

  void _onMapCreated(MapLibreMapController controller) {
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

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _searchResults = [];
      }
    });
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: colorController.textColor.value),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorController.backgroundColor.value.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _isSearchExpanded ? Icons.close : Icons.search,
                color: colorController.textColor.value,
              ),
              onPressed: _toggleSearch,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map fills entire screen
          MapLibreMap(
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
          
          // Search overlay
          if (_isSearchExpanded)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: LocationSearchWidget(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  _searchPlace(value);
                },
                searchResults: _searchResults,
                onResultSelected: _selectSearchResult,
                onClear: () {
                  setState(() {
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
              ),
            ),
          
          // Confirm button overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: LocationConfirmButtonWidget(
              isEnabled: _selectedLocation != null,
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
            ),
          ),
          
          
        ],
      ),
    );
  }
}
