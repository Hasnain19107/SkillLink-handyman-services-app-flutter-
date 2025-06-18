import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class VerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload file to Firebase Storage
  Future<String?> uploadFile(File file, String folder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final fileName =
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('verification/$folder/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Submit verification data
  Future<bool> submitVerification({
    required String fullName,
    required String phone,
    required String address,
    required String category,
    required File? facePhoto,
    required File? cnicFront,
    required File? cnicBack,
    required List<File> certificates,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Upload all files
      final facePhotoUrl =
          facePhoto != null ? await uploadFile(facePhoto, 'face_photos') : null;
      final cnicFrontUrl =
          cnicFront != null ? await uploadFile(cnicFront, 'cnic_front') : null;
      final cnicBackUrl =
          cnicBack != null ? await uploadFile(cnicBack, 'cnic_back') : null;

      List<String> certificateUrls = [];
      for (var certificate in certificates) {
        final url = await uploadFile(certificate, 'certificates');
        if (url != null) {
          certificateUrls.add(url);
        }
      }

      // Verification data to save
      final verificationData = {
        'userId': user.uid,
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'category': category,
        'verificationStatus': 'pending',
        'facePhotoUrl': facePhotoUrl,
        'cnicFrontUrl': cnicFrontUrl,
        'cnicBackUrl': cnicBackUrl,
        'certificateUrls': certificateUrls,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      };

      // Create or update verification document in provider_verification collection
      await _firestore
          .collection('provider_verification')
          .doc(user.uid)
          .set(verificationData);

      // Update only the essential verification fields in service_providers collection
      await _firestore.collection('service_providers').doc(user.uid).update({
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'category': category,
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });

      // Also update the users collection
      await _firestore.collection('users').doc(user.uid).update({
        'fullName': fullName,
        'phone': phone,
      });

      return true;
    } catch (e) {
      print('Error submitting verification: $e');
      return false;
    }
  }

  // Get provider verification data
  Future<Map<String, dynamic>> getProviderData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Get provider data
      final providerDoc =
          await _firestore.collection('service_providers').doc(user.uid).get();

      // Check if there's verification data in the dedicated collection
      final verificationDoc = await _firestore
          .collection('provider_verification')
          .doc(user.uid)
          .get();

      Map<String, dynamic> result = {};

      if (providerDoc.exists) {
        final data = providerDoc.data() as Map<String, dynamic>;
        result = {
          'verificationStatus': data['verificationStatus'] ?? 'unverified',
          'fullName': data['fullName'] ?? '',
          'phone': data['phone'] ?? '',
          'address': data['address'] ?? '',
          'category': data['category'] ?? '',
          'rejectionReason': data['rejectionReason'],
        };
      }

      // If verification exists, load more detailed data from there
      if (verificationDoc.exists) {
        final vData = verificationDoc.data() as Map<String, dynamic>;
        result['fullName'] = vData['fullName'] ?? result['fullName'];
        result['phone'] = vData['phone'] ?? result['phone'];
        result['address'] = vData['address'] ?? result['address'];
        result['category'] = vData['category'] ?? result['category'];
        result['hasFacePhoto'] = vData['facePhotoUrl'] != null;
        result['hasCnicFront'] = vData['cnicFrontUrl'] != null;
        result['hasCnicBack'] = vData['cnicBackUrl'] != null;
        result['certificateCount'] =
            (vData['certificateUrls'] as List?)?.length ?? 0;
      }

      return result;
    } catch (e) {
      print('Error loading provider data: $e');
      return {};
    }
  }
}
