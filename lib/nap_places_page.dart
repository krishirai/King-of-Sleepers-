import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'current_nap_spot_page.dart';

class NapPlacesPage extends StatelessWidget {
  const NapPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Napping Places'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('nap_places')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No nap places found.'),
            );
          }

          final documents = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];

              final data =
                  document.data() as Map<String, dynamic>;

              final String name =
                  data['name'] ?? 'Unknown place';

              final String location =
                  data['location'] ?? 'Unknown location';

              final int availableSeats =
                  (data['availableSeats'] as num?)?.toInt() ?? 0;

              final double? latitude =
                  (data['latitude'] as num?)?.toDouble();

              final double? longitude =
                  (data['longitude'] as num?)?.toDouble();

              return NapPlaceCard(
                name: name,
                location: location,
                availableSeats: availableSeats,
                latitude: latitude,
                longitude: longitude,
              );
            },
          );
        },
      ),
    );
  }
}

class NapPlaceCard extends StatelessWidget {
  final String name;
  final String location;
  final int availableSeats;
  final double? latitude;
  final double? longitude;

  const NapPlaceCard({
    super.key,
    required this.name,
    required this.location,
    required this.availableSeats,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bed),
            title: Text(name),
            subtitle: Text(
              '$location\nAvailable seats: $availableSeats',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.location_on),
                label: const Text('Set as Current Spot'),
                onPressed: () {
                  if (latitude == null || longitude == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Location coordinates are missing.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CurrentNapSpotPage(
                        name: name,
                        location: location,
                        latitude: latitude!,
                        longitude: longitude!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}