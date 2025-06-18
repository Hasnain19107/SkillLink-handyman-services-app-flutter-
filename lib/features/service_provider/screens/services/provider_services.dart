import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/service_dialogue.dart';

class ProviderServicesscreen extends StatefulWidget {
  @override
  _ProviderServicesScreenState createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesscreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _providerCategory = '';

  @override
  void initState() {
    super.initState();
    _loadProviderCategory();
  }

  Future<void> _loadProviderCategory() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('service_providers')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _providerCategory = doc.data()?['category'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading provider category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My ${_providerCategory} Services',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Color(0xFF2A9D8F),
            ),
            onPressed: () => _showAddServiceDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildServicesList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF2A9D8F),
        onPressed: () => _showAddServiceDialog(),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildServicesList() {
    final user = _auth.currentUser;
    if (user == null) return Center(child: Text('Please log in'));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('provider_services')
          .where('providerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final services = snapshot.data?.docs ?? [];

        if (services.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final serviceDoc = services[index];
            final serviceData = serviceDoc.data() as Map<String, dynamic>;

            return _buildServiceCard(serviceDoc.id, serviceData);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No ${_providerCategory} Services Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first ${_providerCategory.toLowerCase()} service to start\nreceiving bookings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddServiceDialog(),
            icon: Icon(Icons.add),
            label: Text('Add ${_providerCategory} Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String serviceId, Map<String, dynamic> serviceData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = serviceData['isActive'] ?? true;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isDark ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    serviceData['name'] ?? 'Unnamed Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showEditServiceDialog(serviceId, serviceData);
                            break;
                          case 'toggle':
                            _toggleServiceStatus(serviceId, !isActive);
                            break;
                          case 'delete':
                            _showDeleteConfirmation(serviceId);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(isActive ? Icons.pause : Icons.play_arrow,
                                  size: 16),
                              SizedBox(width: 8),
                              Text(isActive ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              serviceData['description'] ?? 'No description',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.category,
                  label: serviceData['category'] ?? 'No category',
                  color: Color(0xFF2A9D8F),
                ),
                SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.attach_money,
                  label: '\Rs${(serviceData['price'] ?? 0).toStringAsFixed(2)}',
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.timer,
                  label: '${serviceData['durationMinutes'] ?? 60} min',
                  color: Colors.blue,
                ),
              ],
            ),
            if (serviceData['tags'] != null &&
                (serviceData['tags'] as List).isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (serviceData['tags'] as List<dynamic>)
                      .take(3)
                      .map((tag) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF2A9D8F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF2A9D8F).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              tag.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2A9D8F),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    _showServiceDialog();
  }

  void _showEditServiceDialog(
      String serviceId, Map<String, dynamic> serviceData) {
    _showServiceDialog(serviceId: serviceId, initialData: serviceData);
  }

  void _showServiceDialog(
      {String? serviceId, Map<String, dynamic>? initialData}) {
    showDialog(
      context: context,
      builder: (context) => ServiceFormDialog(
        serviceId: serviceId,
        initialData: initialData,
        providerCategory: _providerCategory,
        onSaved: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(serviceId == null
                  ? 'Service added successfully!'
                  : 'Service updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleServiceStatus(String serviceId, bool newStatus) async {
    try {
      await _firestore.collection('provider_services').doc(serviceId).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Service ${newStatus ? 'activated' : 'deactivated'} successfully!'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating service: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String serviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Service'),
        content: Text(
            'Are you sure you want to delete this service? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteService(serviceId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteService(String serviceId) async {
    try {
      await _firestore.collection('provider_services').doc(serviceId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting service: $e')),
      );
    }
  }
}
