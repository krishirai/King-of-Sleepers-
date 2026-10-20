import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Google Map of AUT City Campus that shows every nap spot stored in the
/// Firestore `nap_places` collection, plus the student's live location.
///
/// Needs a Google Maps API key. On Android it is read from
/// android/local.properties (MAPS_API_KEY), see AndroidManifest.xml.
class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  // Approximate centre of AUT City Campus (55 Wellesley Street East).
  // LatLng format: LatLng(latitude, longitude).
  // TODO: confirm against MazeMap (mazemap.aut.ac.nz) or by dropping a pin
  // on the middle of campus in Google Maps.
  static const LatLng _campusCentre = LatLng(-36.8534, 174.7658);
  static const double _defaultZoom = 17;

  // Lets the app move the camera after the map has loaded.
  GoogleMapController? _mapController;

  // Created once, so rebuilds don't open a new Firestore listener each time.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _napPlacesStream;

  // Live location state. The map still works if location is unavailable.
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  bool _locationGranted = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _napPlacesStream =
        FirebaseFirestore.instance.collection('nap_places').snapshots();
    _startLiveLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startLiveLocation() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (mounted) setState(() => _locationError = null);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationError('Location services are turned off.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _setLocationError('Location permission was denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _setLocationError(
          'Location permission is permanently denied. Enable it in settings.',
        );
        return;
      }

      if (!mounted) return;

      // Permission granted: lets the map draw Google's own live blue dot.
      setState(() => _locationGranted = true);

      // This stream is used for the "X m away" text on each nap spot.
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Only send an update after the device moves 5 metres.
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          if (!mounted) return;
          setState(() => _currentPosition = position);
        },
        onError: (_) => _setLocationError('Could not get current location.'),
      );
    } catch (_) {
      _setLocationError('Could not get current location.');
    }
  }

  void _setLocationError(String message) {
    if (!mounted) return;
    setState(() => _locationError = message);
  }

  void _moveCamera(LatLng target) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(target, _defaultZoom),
    );
  }

  void _recentreOnCampus() => _moveCamera(_campusCentre);

  void _centreOnMe() {
    final position = _currentPosition;
    if (position == null) return;
    _moveCamera(LatLng(position.latitude, position.longitude));
  }

  /// Opens a URL outside the app (Google Maps app, or the browser if the
  /// app isn't installed) and shows a message if that fails.
  Future<void> _openExternally(Uri url) async {
    var opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Falls through to the error message below.
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  /// Opens AUT City Campus in the Google Maps app, which shows the user's
  /// own live location (blue dot) automatically.
  Future<void> _openCampusInGoogleMaps() {
    return _openExternally(
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': 'AUT City Campus, 55 Wellesley Street East, Auckland',
      }),
    );
  }

  /// Opens turn-by-turn directions to a nap spot in Google Maps.
  Future<void> _openDirectionsTo(_NapSpot spot) {
    return _openExternally(
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${spot.point.latitude},${spot.point.longitude}',
      }),
    );
  }

  void _showSpotDetails(_NapSpot spot) {
    final position = _currentPosition;
    final distance = position == null
        ? null
        : Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            spot.point.latitude,
            spot.point.longitude,
          );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spot.name,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(spot.location)),
              ],
            ),
            if (distance != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_walk, size: 20),
                  const SizedBox(width: 8),
                  Text(_formatDistance(distance)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Directions in Google Maps'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _openDirectionsTo(spot);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('AUT City Campus Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Centre on campus',
            onPressed: _recentreOnCampus,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            // heroTag must be null when a screen has more than one FAB.
            heroTag: null,
            tooltip: 'My location',
            // Disabled until the first location fix arrives.
            onPressed: _currentPosition == null ? null : _centreOnMe,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: null,
            onPressed: _openCampusInGoogleMaps,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in Google Maps'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _napPlacesStream,
        builder: (context, snapshot) {
          // Spots with missing or invalid coordinates are skipped.
          final spots = (snapshot.data?.docs ?? [])
              .map((doc) => _NapSpot.fromData(doc.id, doc.data()))
              .whereType<_NapSpot>()
              .toList();

          final markers = <Marker>{
            for (final spot in spots)
              Marker(
                markerId: MarkerId(spot.id),
                position: spot.point,
                onTap: () => _showSpotDetails(spot),
              ),
          };

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _campusCentre,
                  zoom: _defaultZoom,
                ),
                markers: markers,
                // Google's own live blue dot + accuracy circle. Only
                // switched on once location permission has been granted.
                myLocationEnabled: _locationGranted,
                // We use our own "My location" button instead.
                myLocationButtonEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),

              // Loading / error / empty feedback on top of the map.
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator(),
                    if (snapshot.hasError)
                      const _StatusBanner(
                        message:
                            'Could not load nap spots. Please try again later.',
                      )
                    else if (snapshot.hasData && spots.isEmpty)
                      const _StatusBanner(message: 'No nap spots to show yet.'),
                    if (_locationError != null)
                      _StatusBanner(
                        message: _locationError!,
                        actionLabel: 'Retry',
                        onAction: _startLiveLocation,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDistance(double metres) {
  if (metres < 1000) return '${metres.round()} m away';
  return '${(metres / 1000).toStringAsFixed(2)} km away';
}

/// A nap spot that has valid map coordinates.
class _NapSpot {
  const _NapSpot({
    required this.id,
    required this.name,
    required this.location,
    required this.point,
  });

  final String id;
  final String name;
  final String location;
  final LatLng point;

  /// Builds a spot from a Firestore document, or returns null when the
  /// document has no usable coordinates.
  ///
  /// Supports the two shapes already used in nap_places_page.dart:
  /// a GeoPoint stored in `latitude`, or separate numeric
  /// `latitude` / `longitude` fields.
  static _NapSpot? fromData(String id, Map<String, dynamic> raw) {
    // Some documents have stray whitespace in their field names.
    final data = {for (final e in raw.entries) e.key.trim(): e.value};

    final latValue = data['latitude'];
    final lngValue = data['longitude'];

    double? latitude;
    double? longitude;

    if (latValue is GeoPoint) {
      latitude = latValue.latitude;
      longitude = latValue.longitude;
    } else if (latValue is num && lngValue is num) {
      latitude = latValue.toDouble();
      longitude = lngValue.toDouble();
    }

    if (latitude == null || longitude == null) return null;

    return _NapSpot(
      id: id,
      name: data['name']?.toString() ?? 'Unknown place',
      location: data['location']?.toString() ?? 'Unknown location',
      point: LatLng(latitude, longitude),
    );
  }
}

/// Small message bar shown at the top of the map, with an optional action.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(child: Text(message)),
              if (actionLabel != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}