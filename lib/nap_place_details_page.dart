
import 'package:flutter/material.dart';
import 'screens/rating_screen.dart';

class NapPlaceDetailsPage extends StatelessWidget {
  final String locationId;
  final String name;
  final String location;
  final int availableSeats;
  final bool? hasPowerSocket;
  final String seatingType;

  const NapPlaceDetailsPage({
    super.key,
    required this.locationId,
    required this.name,
    required this.location,
    required this.availableSeats,
    this.hasPowerSocket,
    this.seatingType = 'Not specified',
  });

  @override
  Widget build(BuildContext context) {
    final String socketText = hasPowerSocket == null
        ? 'Not specified'
        : hasPowerSocket!
            ? 'Available'
            : 'Not available';

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
          const SizedBox(height: 30),
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
