
import 'dart:async';
 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
 
class CurrentNapSpotPage extends StatefulWidget {
  final String name;
  final String location;
  final double latitude;
  final double longitude;
 
  const CurrentNapSpotPage({
    super.key,
    required this.name,
    required this.location,
    required this.latitude,
    required this.longitude,
  });
 
  @override
  State<CurrentNapSpotPage> createState() => _CurrentNapSpotPageState();
}
 
class _CurrentNapSpotPageState extends State<CurrentNapSpotPage> {
  final MapController _mapController = MapController();
 
  // CHANGE 1: a subscription to the live position stream.
  StreamSubscription<Position>? _positionSubscription;
 
  Position? _currentPosition;
  double? _distanceInMeters;
  bool _isLoadingLocation = true;
  String? _locationError;
 
  // CHANGE 2: only auto-zoom to show both pins on the very first fix,
  // so the map doesn't keep jumping while the user is panning around.
  bool _hasFittedCamera = false;
 
  @override
  void initState() {
    super.initState();
    _startLiveLocation();
  }
 
  // CHANGE 3: stop listening when the page closes (saves battery, avoids leaks).
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }
 
  // CHANGE 4: replaces _getCurrentLocation(). Same permission checks as
  // before, but ends by subscribing to a stream instead of a one-off read.
  Future<void> _startLiveLocation() async {
    if (!mounted) return;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
 
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
 
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are turned off.');
        return;
      }
 
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
 
      if (permission == LocationPermission.denied) {
        _setError('Location permission was denied.');
        return;
      }
 
      if (permission == LocationPermission.deniedForever) {
        _setError(
          'Location permission is permanently denied. Please enable it in settings.',
        );
        return;
      }
 
      if (!mounted) return;
 
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // Only send an update after the device moves 5 metres.
          distanceFilter: 5,
        ),
      ).listen(
        _onPositionUpdate,
        onError: (_) => _setError('Could not get current location.'),
      );
    } catch (e) {
      _setError('Could not get current location.');
    }
  }
 
  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _locationError = message;
      _isLoadingLocation = false;
    });
  }
 
  // CHANGE 5: called every time the device moves.
  void _onPositionUpdate(Position position) {
    if (!mounted) return;
 
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.latitude,
      widget.longitude,
    );
 
    setState(() {
      _currentPosition = position;
      _distanceInMeters = distance;
      _isLoadingLocation = false;
      _locationError = null;
    });
 
    // On the first fix, zoom so both the user and the nap spot are visible.
    if (!_hasFittedCamera) {
      _hasFittedCamera = true;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(position.latitude, position.longitude),
            LatLng(widget.latitude, widget.longitude),
          ),
          padding: const EdgeInsets.all(60),
          maxZoom: 18,
        ),
      );
    }
  }
 
  void _findCurrentSpot() {
    _mapController.move(
      LatLng(widget.latitude, widget.longitude),
      18,
    );
  }
 
  // CHANGE 6: new helper so the user can re-centre on themselves.
  void _centreOnMe() {
    final position = _currentPosition;
    if (position == null) return;
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      18,
    );
  }
 
  Future<void> _openDirections() async {
    final Uri url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.latitude},${widget.longitude}',
    );
 
    final bool opened = await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
 
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open directions.'),
        ),
      );
    }
  }
 
  String _formatDistance() {
    if (_distanceInMeters == null) {
      return 'Distance unavailable';
    }
 
    if (_distanceInMeters! < 1000) {
      return '${_distanceInMeters!.round()} m away';
    }
 
    final kilometres = _distanceInMeters! / 1000;
 
    return '${kilometres.toStringAsFixed(2)} km away';
  }
 
  @override
  Widget build(BuildContext context) {
    final napSpot = LatLng(
      widget.latitude,
      widget.longitude,
    );
 
    return Scaffold(
      appBar: AppBar(
        // Explicit back button: returns to the previous page.
        leading: const BackButton(),
        title: const Text('Current Nap Spot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: napSpot,
                initialZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sleeping_king',
                ),
 
                // CHANGE 7: light-blue circle showing GPS accuracy. Indoors
                // this can be 10-50 m, so it's honest feedback for users.
                if (_currentPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        radius: _currentPosition!.accuracy,
                        useRadiusInMeter: true,
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderColor: Colors.blue.withValues(alpha: 0.4),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
 
                MarkerLayer(
                  markers: [
                    Marker(
                      point: napSpot,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.bed,
                        size: 42,
                        color: Colors.red,
                      ),
                    ),
 
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.my_location,
                          size: 38,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
 
                // Required by OpenStreetMap's tile usage policy.
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
 
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
 
                const SizedBox(height: 6),
 
                Text(
                  widget.location,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
 
                const SizedBox(height: 12),
 
                if (_isLoadingLocation)
                  const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Finding your location...'),
                    ],
                  )
                else if (_locationError != null)
                  // CHANGE 8: error text plus a Retry button.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _locationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: _startLiveLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else
                  Text(
                    _formatDistance(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
 
                const SizedBox(height: 16),
 
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _findCurrentSpot,
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Nap Spot'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _currentPosition == null ? null : _centreOnMe,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Me'),
                      ),
                    ),
                  ],
                ),
 
                const SizedBox(height: 8),
 
                ElevatedButton.icon(
                  onPressed: _openDirections,
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}