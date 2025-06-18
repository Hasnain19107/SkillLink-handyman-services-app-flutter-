import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_request_card.dart';

class BookingRequestsSection extends StatelessWidget {
  final VoidCallback onViewAllPressed;

  const BookingRequestsSection({
    Key? key,
    required this.onViewAllPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'New Booking Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: onViewAllPressed,
              child: Text(
                'View All',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('booking_service')
              .where('providerId', isEqualTo: _auth.currentUser?.uid)
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                child: Text('Error loading bookings: ${snapshot.error}',
                    style: TextStyle(color: Colors.red)),
              );
            }

            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.docs.isEmpty) {
              return Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]!
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'No pending booking requests',
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600]),
                ),
              );
            }

            return Container(
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>?;

                  if (data == null) {
                    return Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Error: Invalid data for booking ${doc.id}',
                          style: TextStyle(color: Colors.orange)),
                    );
                  }

                  DateTime bookingDateTime;
                  try {
                    final bookingDate = data['bookingDate'];
                    if (bookingDate is Timestamp) {
                      bookingDateTime = bookingDate.toDate();
                    } else {
                      bookingDateTime = DateTime.now();
                    }
                  } catch (e) {
                    bookingDateTime = DateTime.now();
                  }

                  final customerName =
                      data['seekerName']?.toString() ?? 'Customer';
                  final serviceName =
                      data['serviceName']?.toString() ?? 'Service';
                  final price = (data['budget'] as num?)?.toDouble() ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BookingRequestCard(
                      bookingId: doc.id,
                      customerName: customerName,
                      serviceName: serviceName,
                      dateTime: bookingDateTime,
                      price: price,
                      onAccept: () async {
                        try {
                          await _firestore
                              .collection('booking_service')
                              .doc(doc.id)
                              .update({'status': 'confirmed'});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Booking accepted')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to accept booking: $e')),
                          );
                        }
                      },
                      onDecline: () async {
                        try {
                          await _firestore
                              .collection('booking_service')
                              .doc(doc.id)
                              .update({'status': 'cancelled'});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Booking declined')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Failed to decline booking: $e')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
