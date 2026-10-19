import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'current_nap_spot_page.dart';
import 'nap_place_details_page.dart';
import 'package:share_plus/share_plus.dart';

class NapPlacesPage extends StatelessWidget {
  const NapPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Napping Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
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
              child: Text('Error: ${snapshot.error}'),
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

              final raw = document.data() as Map<String, dynamic>;
              final data = {for (final e in raw.entries) e.key.trim(): e.value};

              final String name = data['name']?.toString() ?? 'Unknown place';

              final String location =
                  data['location']?.toString() ?? 'Unknown location';

              final int availableSeats =
                  (data['availableSeats'] as num?)?.toInt() ?? 0;

              final dynamic powerSocketValue = data['hasPowerSocket'];

              final bool? hasPowerSocket =
                  powerSocketValue is bool ? powerSocketValue : null;

              final String seatingType =
                  data['seatingType']?.toString() ?? 'Not specified';

              double? latitude;
              double? longitude;

              final dynamic latValue = data['latitude'];
              if (latValue is GeoPoint) {
                latitude = latValue.latitude;
                longitude = latValue.longitude;
              } else {
                latitude = (latValue as num?)?.toDouble();
                longitude = (data['longitude'] as num?)?.toDouble();
              }

              return NapPlaceCard(
                name: name,
                location: location,
                availableSeats: availableSeats,
                hasPowerSocket: hasPowerSocket,
                seatingType: seatingType,
                latitude: latitude,
                longitude: longitude,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NapPlaceDetailsPage(
                        locationId: document.id,
                        name: name,
                        location: location,
                        availableSeats: availableSeats,
                        hasPowerSocket: hasPowerSocket,
                        seatingType: seatingType,
                      ),
                    ),
                  );
                },
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
  final VoidCallback? onTap;
  final bool? hasPowerSocket;
  final String seatingType;

  const NapPlaceCard({
    super.key,
    required this.name,
    required this.location,
    required this.availableSeats,
    required this.latitude,
    required this.longitude,
    this.onTap,
    this.hasPowerSocket,
    this.seatingType = 'Not specified',
  });

  void _shareSpot() {
    final mapsLink = (latitude != null && longitude != null)
        ? '\nhttps://www.google.com/maps/search/?api=1&query=$latitude,$longitude'
        : '';

    SharePlus.instance.share(
      ShareParams(
        text: 'Check out this nap spot: $name ($location)$mapsLink'
            '\n\nShared from King of Sleepers',
      ),
    );
  }

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
              '$location\nAvailable seats: $availableSeats\n'
              'Power socket: ${hasPowerSocket == null ? "Not specified" : hasPowerSocket! ? "Available" : "Not available"}\n'
              'Seating type: $seatingType',
            ),
            isThreeLine: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share',
                  onPressed: _shareSpot,
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: onTap,
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