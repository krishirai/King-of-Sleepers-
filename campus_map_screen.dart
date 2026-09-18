// Provides Flutter user-interface widgets such as Scaffold and AppBar.
import 'package:flutter/material.dart';

// Provides Google Map widgets, marker objects, and LatLng coordinates.
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Displays a Google Map of the University of Auckland City Campus.
class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

/// Holds the state and map data for the CampusMapScreen.
class _CampusMapScreenState extends State<CampusMapScreen> {
  // Lets the app control the map after it has loaded.
  //
  // This can later be used to zoom to a nap spot or centre the map
  // on a selected location.
  GoogleMapController? mapController;

  // Starting centre point for the University of Auckland City Campus.
  //
  // LatLng format: LatLng(latitude, longitude).
  static const LatLng cityCampusCentre = LatLng(
    -36.8517,
    174.7695,
  );

  // Pins displayed on the map.
  //
  // This must be "final", not "const", because a Set of Marker objects
  // cannot be evaluated as a compile-time constant by Dart.
  //
  // The ClockTower marker is based on a published coordinate for the
  // Old Arts / ClockTower building. The other starter locations should
  // be confirmed against the official UoA interactive map before submission.
  static final Set<Marker> campusMarkers = {
    // ClockTower / Old Arts Building marker.
    Marker(
      markerId: const MarkerId('clocktower'),
      position: const LatLng(-36.85028, 174.76944),
      infoWindow: const InfoWindow(
        title: 'ClockTower',
        snippet: 'Old Arts Building / Building 105',
      ),
    ),

    // Central City Campus reference marker.
    Marker(
      markerId: const MarkerId('city_campus'),
      position: cityCampusCentre,
      infoWindow: const InfoWindow(
        title: 'University of Auckland',
        snippet: 'City Campus',
      ),
    ),

    // General Library starter marker.
    Marker(
      markerId: const MarkerId('general_library'),
      position: const LatLng(-36.85165, 174.76890),
      infoWindow: const InfoWindow(
        title: 'General Library',
        snippet: 'City Campus library facilities',
      ),
    ),

    // Engineering starter marker.
    Marker(
      markerId: const MarkerId('engineering'),
      position: const LatLng(-36.85280, 174.76990),
      infoWindow: const InfoWindow(
        title: 'Engineering',
        snippet: 'Teaching and laboratory area',
      ),
    ),

    // Business School starter marker.
    Marker(
      markerId: const MarkerId('business_school'),
      position: const LatLng(-36.85345, 174.76845),
      infoWindow: const InfoWindow(
        title: 'Business School',
        snippet: 'Sir Owen G Glenn Building',
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar shown on the map screen.
      appBar: AppBar(
        title: const Text('UoA City Campus Map'),
      ),

      // Shows the interactive Google Map.
      body: GoogleMap(
        // Position displayed when the map screen first opens.
        initialCameraPosition: const CameraPosition(
          target: cityCampusCentre,
          zoom: 16,
        ),

        // Adds the campus building pins to the map.
        markers: campusMarkers,

        // Stores the map controller after the map has finished loading.
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
      ),
    );
  }
}