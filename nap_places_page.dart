// Provides access to Firebase Firestore so the app can read nap-place data.
import 'package:cloud_firestore/cloud_firestore.dart';

// Provides Flutter UI widgets such as Scaffold, AppBar, ListView, and Card.
import 'package:flutter/material.dart';

// Imports the page that lets the user set a selected nap location
// as their current nap spot.
import 'current_nap_spot_page.dart';

// Imports the page where users can rate a selected nap place.
import 'screens/rating_screen.dart';

// Imports the separate University of Auckland City Campus map screen.
import 'screens/campus_map_screen.dart';

/// Displays the list of nap places stored in Firestore.
///
/// This page reads documents from the "nap_places" Firestore collection
/// and displays each document as a NapPlaceCard.
class NapPlacesPage extends StatelessWidget {
  const NapPlacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar shown on the Napping Places page.
      appBar: AppBar(
        title: const Text('Napping Places'),

        // Widgets placed on the right-hand side of the AppBar.
        actions: [
          IconButton(
            // Opens the separate campus map page when the map icon is tapped.
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Creates and opens the campus map screen.
                  builder: (context) => const CampusMapScreen(),
                ),
              );
            },

            // The icon shown in the top-right corner of the page.
            icon: const Icon(Icons.map),

            // Helpful text shown when hovering on desktop or long-pressing
            // the icon on a mobile device.
            tooltip: 'Open campus map',
          ),
        ],
      ),

      // StreamBuilder listens for live changes in the Firestore collection.
      body: StreamBuilder<QuerySnapshot>(
        // Gets all documents from the "nap_places" collection.
        //
        // snapshots() automatically updates the app if Firestore data changes.
        stream: FirebaseFirestore.instance
            .collection('nap_places')
            .snapshots(),

        builder: (context, snapshot) {
          // Shows a loading spinner while Firestore is retrieving data.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Shows an error message if Firestore cannot load the data.
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          // Shows a message if the collection has no nap-place documents.
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No nap places found.'),
            );
          }

          // Stores the Firestore documents after confirming data exists.
          final documents = snapshot.data!.docs;

          // Creates a scrollable card for every nap-place document.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              // Gets the current document from Firestore.
              final document = documents[index];

              // Converts document data into a map that Dart can read.
              final data = document.data() as Map<String, dynamic>;

              // Reads the nap place's name, with a fallback if it is missing.
              final String name = data['name'] ?? 'Unknown place';

              // Reads the location description, with a fallback if missing.
              final String location =
                  data['location'] ?? 'Unknown location';

              // Reads the number of available seats.
              //
              // The conversion allows Firestore values stored as either an int
              // or double to safely become an integer.
              final int availableSeats =
                  (data['availableSeats'] as num?)?.toInt() ?? 0;

              // Reads optional GPS latitude from Firestore.
              final double? latitude =
                  (data['latitude'] as num?)?.toDouble();

              // Reads optional GPS longitude from Firestore.
              final double? longitude =
                  (data['longitude'] as num?)?.toDouble();

              // Shows the nap-place information in a reusable card widget.
              return NapPlaceCard(
                name: name,
                location: location,
                availableSeats: availableSeats,
                latitude: latitude,
                longitude: longitude,

                // Opens the rating page when the user taps the main card area.
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RatingScreen(
                        // Uses the Firestore document ID to identify the place.
                        locationId: document.id,

                        // Passes the location name to display on the rating page.
                        locationName: name,
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

/// A reusable card that displays one nap place from Firestore.
class NapPlaceCard extends StatelessWidget {
  // Name of the nap place, for example "General Library".
  final String name;

  // Description of where the nap place is located.
  final String location;

  // Number of seats currently available.
  final int availableSeats;

  // Optional coordinate used when setting the current nap spot.
  final double? latitude;

  // Optional coordinate used when setting the current nap spot.
  final double? longitude;

  // Function called when the main ListTile is tapped.
  final VoidCallback? onTap;

  const NapPlaceCard({
    super.key,
    required this.name,
    required this.location,
    required this.availableSeats,
    required this.latitude,
    required this.longitude,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Adds spacing below each card in the scrolling list.
      margin: const EdgeInsets.only(bottom: 12),

      child: Column(
        children: [
          // The primary tappable information section of the card.
          ListTile(
            // Bed icon represents a napping location.
            leading: const Icon(Icons.bed),

            // Displays the nap-place name.
            title: Text(name),

            // Displays its location and number of available seats.
            subtitle: Text(
              '$location\nAvailable seats: $availableSeats',
            ),

            // Allows the subtitle to use up to three lines of space.
            isThreeLine: true,

            // Indicates that tapping opens another page.
            trailing: const Icon(Icons.chevron_right),

            // Opens the RatingScreen passed in from NapPlacesPage.
            onTap: onTap,
          ),

          // Adds horizontal and bottom spacing around the action button.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

            child: SizedBox(
              // Makes the button stretch across the width of the card.
              width: double.infinity,

              child: ElevatedButton.icon(
                // Location icon shown before the button label.
                icon: const Icon(Icons.location_on),

                // Text displayed on the button.
                label: const Text('Set as Current Spot'),

                // Runs when the user taps the button.
                onPressed: () {
                  // The CurrentNapSpotPage requires valid coordinates.
                  //
                  // Do not open it when this Firestore document has no
                  // latitude or longitude fields.
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

                  // Opens the current-nap-spot page and sends the selected
                  // nap place's details and coordinates to it.
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