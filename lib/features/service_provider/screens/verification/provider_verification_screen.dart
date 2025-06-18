import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'verification_service.dart';
import 'widgets/document_uploader.dart';
import 'widgets/verification_status_banner.dart';
import 'widgets/form_fields.dart';

class ProviderVerificationScreen extends StatefulWidget {
  const ProviderVerificationScreen({Key? key}) : super(key: key);

  @override
  State<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends State<ProviderVerificationScreen> {
  // Services
  final VerificationService _verificationService = VerificationService();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Selected category
  String? _selectedCategory;
  final List<String> _categories = [
    'Electrical',
    'Plumbing',
    'Carpentry',
    'Cleaning',
    'Painting',
    'Gardening',
    'Moving',
    'Appliance Repair',
    'Computer Repair',
    'Beauty & Wellness',
    'Tutoring',
    'Other'
  ];

  // Document files
  File? _facePhoto;
  File? _cnicFront;
  File? _cnicBack;
  List<File> _certificates = [];

  // Verification status
  String _verificationStatus = 'unverified';
  String? _rejectionReason;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProviderData() async {
    try {
      final data = await _verificationService.getProviderData();

      if (data.isNotEmpty) {
        setState(() {
          _verificationStatus = data['verificationStatus'] ?? 'unverified';
          _rejectionReason = data['rejectionReason'];
          _fullNameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';

          // Handle category mapping for backward compatibility
          String? savedCategory = data['category'];
          if (savedCategory != null && _categories.contains(savedCategory)) {
            _selectedCategory = savedCategory;
          } else if (savedCategory != null) {
            // Handle legacy category names
            if (savedCategory == 'Computer & IT') {
              _selectedCategory = 'Computer Repair';
            } else {
              _selectedCategory =
                  null; // Reset to null if category doesn't exist
            }
          }
        });
      }

      // Load rejection reason specifically in case of rejection
      if (_verificationStatus == 'rejected') {
        await _loadRejectionReason();
      }
    } catch (e) {
      print('Error loading provider data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRejectionReason() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('provider_verification')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _rejectionReason = data['rejectionReason'];
          });
        }
      }
    } catch (e) {
      print('Error loading rejection reason: $e');
    }
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (type == 'face') {
            _facePhoto = File(pickedFile.path);
          } else if (type == 'cnicFront') {
            _cnicFront = File(pickedFile.path);
          } else if (type == 'cnicBack') {
            _cnicBack = File(pickedFile.path);
          } else if (type == 'certificate') {
            _certificates.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(String type) {
    setState(() {
      if (type == 'face') {
        _facePhoto = null;
      } else if (type == 'cnicFront') {
        _cnicFront = null;
      } else if (type == 'cnicBack') {
        _cnicBack = null;
      } else if (type.startsWith('certificate_')) {
        final index = int.parse(type.split('_')[1]);
        if (index < _certificates.length) {
          _certificates.removeAt(index);
        }
      }
    });
  }

  Future<void> _submitVerification() async {
    // Validate form fields
    if (_fullNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate required documents
    if (_facePhoto == null || _cnicFront == null || _cnicBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Submit verification data
      final success = await _verificationService.submitVerification(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        category: _selectedCategory!,
        facePhoto: _facePhoto,
        cnicFront: _cnicFront,
        cnicBack: _cnicBack,
        certificates: _certificates,
      );

      if (success) {
        setState(() {
          _verificationStatus = 'pending';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification documents submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to submit verification');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF2A9D8F),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VerificationStatusBanner(
              status: _verificationStatus,
              rejectionReason: _rejectionReason,
            ),
            const SizedBox(height: 24),
            if (_verificationStatus == 'verified')
              _buildVerifiedContent(isDark)
            else if (_verificationStatus == 'pending')
              _buildPendingContent(isDark)
            else
              _buildVerificationForm(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedContent(bool isDark) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.verified,
            color: isDark ? Colors.green[300] : Colors.green,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Your account is verified!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have full access to all features of the app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingContent(bool isDark) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.pending_actions,
            color: isDark ? Colors.orange[300] : Colors.orange,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Verification in Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your documents are being reviewed. This usually takes 1-2 business days.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? Colors.blue[300] : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Limited Access',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'While your verification is pending, you have limited access to some features. You can still browse the app, but messaging and booking features are restricted until verification is complete.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please provide your personal information for verification. This information will be visible to clients.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 24),

        // Personal information form
        FormTextField(
          controller: _fullNameController,
          label: 'Full Name',
          icon: Icons.person,
          hint: 'Enter your full name',
        ),
        FormTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
        ),
        FormTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on,
          hint: 'Enter your full address',
        ),
        CategoryDropdown(
          selectedCategory: _selectedCategory,
          categories: _categories,
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),

        const SizedBox(height: 32),
        Text(
          'Verification Documents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please upload the following documents to verify your identity and qualifications. This helps build trust with potential clients.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 24),

        // Document uploaders
        DocumentUploader(
          title: 'Face Photo',
          description:
              'Upload a clear photo of your face. This should be a recent photo with good lighting.',
          file: _facePhoto,
          type: 'face',
          onPickImage: _pickImage,
          onRemoveImage: _removeImage,
        ),
        DocumentUploader(
          title: 'CNIC Front',
          description: 'Upload the front side of your CNIC (National ID Card).',
          file: _cnicFront,
          type: 'cnicFront',
          onPickImage: _pickImage,
          onRemoveImage: _removeImage,
        ),
        DocumentUploader(
          title: 'CNIC Back',
          description: 'Upload the back side of your CNIC (National ID Card).',
          file: _cnicBack,
          type: 'cnicBack',
          onPickImage: _pickImage,
          onRemoveImage: _removeImage,
        ),

        // Certificates section
        _buildCertificatesSection(isDark),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Submit for Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCertificatesSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Professional Certificates',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  ' (Optional)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload any professional certificates or qualifications related to your services. This can help you get more clients.',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),

                // Display uploaded certificates
                if (_certificates.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _certificates.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Stack(
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: FileImage(_certificates[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  _removeImage('certificate_$index');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                // Add certificate button
                InkWell(
                  onTap: () => _pickImage(ImageSource.gallery, 'certificate'),
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Certificate',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
