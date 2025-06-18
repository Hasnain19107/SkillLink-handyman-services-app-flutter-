import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportIssueScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const ReportIssueScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedIssueType = '';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _issueTypes = [
    {
      'type': 'poor_service',
      'title': 'Poor Service Quality',
      'icon': Icons.thumb_down,
      'color': Colors.orange,
    },
    {
      'type': 'no_show',
      'title': 'Provider Did Not Show Up',
      'icon': Icons.person_off,
      'color': Colors.red,
    },
    {
      'type': 'unprofessional',
      'title': 'Unprofessional Behavior',
      'icon': Icons.warning,
      'color': Colors.amber,
    },
    {
      'type': 'overcharge',
      'title': 'Overcharging',
      'icon': Icons.money_off,
      'color': Colors.deepOrange,
    },
    {
      'type': 'damage',
      'title': 'Property Damage',
      'icon': Icons.broken_image,
      'color': Colors.red[700]!,
    },
    {
      'type': 'incomplete',
      'title': 'Incomplete Work',
      'icon': Icons.incomplete_circle,
      'color': Colors.purple,
    },
    {
      'type': 'safety',
      'title': 'Safety Concerns',
      'icon': Icons.security,
      'color': Colors.red[900]!,
    },
    {
      'type': 'other',
      'title': 'Other Issue',
      'icon': Icons.more_horiz,
      'color': Colors.grey,
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _selectedIssueType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue type and provide details'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await FirebaseFirestore.instance.collection('reports').add({
        'bookingId': widget.bookingId,
        'reporterId': user.uid,
        'reporterName': user.displayName ?? 'Anonymous',
        'providerId': widget.bookingData['providerId'],
        'providerName': widget.bookingData['providerName'],
        'issueType': _selectedIssueType,
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'serviceName': widget.bookingData['serviceName'],
        'bookingDate': widget.bookingData['bookingDate'],
        'priority': _getPriority(_selectedIssueType),
      });

      // Update booking with report flag
      await FirebaseFirestore.instance
          .collection('booking_service')
          .doc(widget.bookingId)
          .update({
        'hasReport': true,
        'reportedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Report submitted successfully. We will review it shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getPriority(String issueType) {
    switch (issueType) {
      case 'safety':
      case 'damage':
        return 'high';
      case 'no_show':
      case 'unprofessional':
        return 'medium';
      default:
        return 'low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        backgroundColor: Colors.red[50],
        foregroundColor: Colors.red[800],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Booking Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.bookingData['providerName'] ??
                            'Unknown Provider'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.work, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(widget.bookingData['serviceName'] ??
                            'Unknown Service'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.attach_money,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                            '\$${widget.bookingData['budget']?.toStringAsFixed(2) ?? '0.00'}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Issue Type Selection
            const Text(
              'What type of issue are you reporting?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _issueTypes.length,
              itemBuilder: (context, index) {
                final issueType = _issueTypes[index];
                final isSelected = _selectedIssueType == issueType['type'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIssueType = issueType['type'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? issueType['color'].withOpacity(0.2)
                          : Colors.grey[100],
                      border: Border.all(
                        color:
                            isSelected ? issueType['color'] : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          issueType['icon'],
                          color: isSelected
                              ? issueType['color']
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          issueType['title'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? issueType['color']
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Description Field
            const Text(
              'Please describe the issue in detail',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Provide as much detail as possible to help us resolve this issue...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a description of the issue';
                }
                if (value.trim().length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your report will be reviewed by our team. We may contact you for additional information if needed.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
