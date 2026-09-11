import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

              return NapPlaceCard(
                name: name,
                location: location,
                availableSeats: availableSeats,
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

  const NapPlaceCard({
    super.key,
    required this.name,
    required this.location,
    required this.availableSeats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.bed),
        title: Text(name),
        subtitle: Text(
          '$location\nAvailable seats: $availableSeats',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}