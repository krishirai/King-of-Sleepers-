
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'screens/rating_screen.dart';

class NapPlaceDetailsPage extends StatelessWidget {
  final String locationId;
  final String name;
  final String location;
  final int availableSeats;
  final bool? hasPowerSocket;
  final String seatingType;
  final double? latitude;
  final double? longitude;

  const NapPlaceDetailsPage({
    super.key,
    required this.locationId,
    required this.name,
    required this.location,
    required this.availableSeats,
    this.hasPowerSocket,
    this.seatingType = 'Not specified',
    this.latitude,
    this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final String socketText = hasPowerSocket == null
        ? 'Not specified'
        : hasPowerSocket!
            ? 'Available'
            : 'Not available';

    final String? mapsLink = latitude != null && longitude != null
        ? Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': '$latitude,$longitude',
          }).toString()
        : null;
    final mapsSuffix = mapsLink == null ? '' : '\nMap: $mapsLink';
    final shareText = 'Check out this nap spot on campus!\n'
        '$name\n'
        'Location: $location\n'
        'Available seats: $availableSeats\n'
        'Power socket: $socketText\n'
        'Seating type: $seatingType$mapsSuffix';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.bed,
            size: 64,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Location'),
            subtitle: Text(location),
          ),
          ListTile(
            leading: const Icon(Icons.event_seat),
            title: const Text('Available Seats'),
            subtitle: Text('$availableSeats'),
          ),
          ListTile(
            leading: const Icon(Icons.power),
            title: const Text('Power Socket'),
            subtitle: Text(socketText),
          ),
          ListTile(
            leading: const Icon(Icons.chair),
            title: const Text('Seating Type'),
            subtitle: Text(seatingType),
          ),
          const SizedBox(height: 18),
          Builder(
            builder: (shareContext) => OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share This Location'),
              onPressed: () async {
                final box = shareContext.findRenderObject() as RenderBox?;
                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      text: shareText,
                      subject: 'Campus nap spot: $name',
                      sharePositionOrigin: box == null
                          ? null
                          : box.localToGlobal(Offset.zero) & box.size,
                    ),
                  );
                } catch (_) {
                  if (shareContext.mounted) {
                    ScaffoldMessenger.of(shareContext).showSnackBar(
                      const SnackBar(content: Text('Unable to share this location.')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.star),
            label: const Text('Rate This Location'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                    locationId: locationId,
                    locationName: name,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
