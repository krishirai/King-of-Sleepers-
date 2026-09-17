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

  Position? _currentPosition;
  double? _distanceInMeters;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission was denied.';
          _isLoadingLocation = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission is permanently denied. Please enable it in settings.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.latitude,
        widget.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _distanceInMeters = distance;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationError = 'Could not get current location.';
        _isLoadingLocation = false;
      });
    }
  }

  void _findCurrentSpot() {
    _mapController.move(
      LatLng(widget.latitude, widget.longitude),
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
                  Text(
                    _locationError!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
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

                ElevatedButton.icon(
                  onPressed: _findCurrentSpot,
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Find My Current Spot'),
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