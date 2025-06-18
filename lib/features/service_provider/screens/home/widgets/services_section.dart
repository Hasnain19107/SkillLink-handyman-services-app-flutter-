import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/widgets/service_card.dart';

class ServicesSection extends StatelessWidget {
  final VoidCallback onManagePressed;

  const ServicesSection({
    Key? key,
    required this.onManagePressed,
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
              'Your Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: onManagePressed,
              child: Text(
                'Manage',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Color(0xFF2A9D8F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('provider_services')
              .where('providerId', isEqualTo: _auth.currentUser?.uid)
              .where('isActive', isEqualTo: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading services: ${snapshot.error}',
                      style: TextStyle(color: Colors.red)));
            }

            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No active services found.',
                        style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600]),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: onManagePressed,
                        icon: Icon(Icons.add),
                        label: Text('Add Your First Service'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2A9D8F),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>?;

                if (data == null) {
                  return Container(
                      child: Text('Invalid service data for ${doc.id}',
                          style: TextStyle(color: Colors.orange)));
                }

                final serviceName =
                    data['name']?.toString() ?? 'Unnamed Service';
                final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                final duration = (data['durationMinutes'] as int?) ?? 60;
                final category = data['category']?.toString() ?? 'General';

                return ServiceCard(
                  serviceName: serviceName,
                  price: price,
                  duration: duration,
                  category: category,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
