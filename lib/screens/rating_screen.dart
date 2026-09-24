import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen that lets the current user rate a specific location (1-5 stars
/// + optional comment) and stores/updates the aggregate rating for that
/// location in Firestore.
///
/// Firestore shape:
///   nap_places/{locationId}
///     - name
///     - avgRating   (double)
///     - ratingCount (int)
///     nap_places/{locationId}/ratings/{userId}
///       - rating    (int, 1-5)
///       - comment   (String)
///       - userEmail (String)
///       - timestamp (Timestamp)
class RatingScreen extends StatefulWidget {
  final String locationId;
  final String locationName;

  const RatingScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _commentController = TextEditingController();

  int _selectedStars = 0;
  bool _isLoading = false;
  bool _isFetchingExisting = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // LOAD EXISTING RATING (if the user already rated this location)
  // ---------------------------------------------------------------
  Future<void> _loadExistingRating() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isFetchingExisting = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('nap_places')
          .doc(widget.locationId)
          .collection('ratings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _selectedStars = (data['rating'] as num?)?.toInt() ?? 0;
          _commentController.text = data['comment'] as String? ?? '';
        });
      }
    } catch (e) {
      // Non-fatal: user can still submit a fresh rating.
    } finally {
      if (mounted) {
        setState(() => _isFetchingExisting = false);
      }
    }
  }

  // ---------------------------------------------------------------
  // SUBMIT RATING
  // ---------------------------------------------------------------
  Future<void> _submitRating() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _errorMessage = 'You need to be signed in to rate a location.';
      });
      return;
    }

    if (_selectedStars == 0) {
      setState(() {
        _errorMessage = 'Please select a star rating.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final locationRef =
        _firestore.collection('nap_places').doc(widget.locationId);
    final ratingRef = locationRef.collection('ratings').doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final ratingSnap = await transaction.get(ratingRef);
        final locationSnap = await transaction.get(locationRef);

        final previousRating =
            ratingSnap.exists ? (ratingSnap.data()?['rating'] as num?)?.toInt() : null;

        final currentCount = locationSnap.exists
            ? (locationSnap.data()?['ratingCount'] as num?)?.toInt() ?? 0
            : 0;
        final currentAvg = locationSnap.exists
            ? (locationSnap.data()?['avgRating'] as num?)?.toDouble() ?? 0.0
            : 0.0;

        int newCount;
        double newAvg;

        if (previousRating != null) {
          // User is updating their existing rating: adjust the sum, keep count.
          final currentSum = currentAvg * currentCount;
          final newSum = currentSum - previousRating + _selectedStars;
          newCount = currentCount;
          newAvg = currentCount == 0 ? 0.0 : newSum / newCount;
        } else {
          // Brand new rating from this user.
          final currentSum = currentAvg * currentCount;
          newCount = currentCount + 1;
          newAvg = (currentSum + _selectedStars) / newCount;
        }

        transaction.set(ratingRef, {
          'rating': _selectedStars,
          'comment': _commentController.text.trim(),
          'userEmail': user.email,
          'timestamp': FieldValue.serverTimestamp(),
        });

        transaction.set(
          locationRef,
          {
            'name': widget.locationName,
            'avgRating': newAvg,
            'ratingCount': newCount,
          },
          SetOptions(merge: true),
        );
      });

      setState(() {
        _successMessage = 'Thanks for rating this location!';
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Could not save your rating (${e.code}).';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------
  Widget _buildStarSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = starIndex <= _selectedStars;
        return IconButton(
          iconSize: 36,
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled ? Colors.amber : Colors.grey,
          ),
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _selectedStars = starIndex;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ${widget.locationName}'),
      ),
      body: SafeArea(
        child: _isFetchingExisting
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'How was your experience?',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      _buildStarSelector(),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _commentController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Comment (optional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (_successMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Rating'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}