import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../messages/chat_screen.dart';

class SeekerAvatar extends StatelessWidget {
  final String seekerId;
  final String customerName;

  const SeekerAvatar({
    Key? key,
    required this.seekerId,
    required this.customerName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getSeekerImageUrl(),
      builder: (context, snapshot) {
        final seekerImageUrl = snapshot.data ?? '';
        return OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProviderChatScreen(
                  seekerId: seekerId,
                  seekerName: customerName,
                  seekerImage: seekerImageUrl,
                  providerId: FirebaseAuth.instance.currentUser!.uid,
                ),
              ),
            );
          },
          icon: const Icon(Icons.chat_outlined, size: 16),
          label: const Text(
            'Chat',
            style: TextStyle(fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: const BorderSide(color: Colors.blue),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Future<String> _getSeekerImageUrl() async {
    try {
      final seekerDoc = await FirebaseFirestore.instance
          .collection('service_seekers')
          .doc(seekerId)
          .get();

      if (seekerDoc.exists) {
        final imageUrl = seekerDoc.data()?['imageUrl'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('seeker_profile_images')
          .child('$seekerId.jpg');

      return await ref.getDownloadURL();
    } catch (e) {
      print('Error loading seeker image: $e');
      return '';
    }
  }
}
