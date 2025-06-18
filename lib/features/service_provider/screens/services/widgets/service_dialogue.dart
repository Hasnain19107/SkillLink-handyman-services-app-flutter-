import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceFormDialog extends StatefulWidget {
  final String? serviceId;
  final Map<String, dynamic>? initialData;
  final String providerCategory;
  final VoidCallback onSaved;

  const ServiceFormDialog({
    Key? key,
    this.serviceId,
    this.initialData,
    required this.providerCategory,
    required this.onSaved,
  }) : super(key: key);

  @override
  _ServiceFormDialogState createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;

  // Category-specific service suggestions
  Map<String, List<String>> categoryServices = {
    'Electrical': [
      'Electrical Installation',
      'Wiring Repair',
      'Circuit Breaker Installation',
      'Outlet Installation',
      'Light Fixture Installation',
      'Electrical Panel Upgrade',
      'Ceiling Fan Installation',
      'Emergency Electrical Repair',
      'Smart Home Wiring',
      'Electrical Inspection'
    ],
    'Plumbing': [
      'Pipe Repair',
      'Drain Cleaning',
      'Toilet Installation',
      'Faucet Repair',
      'Water Heater Installation',
      'Leak Detection',
      'Bathroom Plumbing',
      'Kitchen Plumbing',
      'Emergency Plumbing',
      'Pipe Installation'
    ],
    'Cleaning': [
      'House Cleaning',
      'Deep Cleaning',
      'Office Cleaning',
      'Carpet Cleaning',
      'Window Cleaning',
      'Post-Construction Cleaning',
      'Move-in/Move-out Cleaning',
      'Pressure Washing',
      'Upholstery Cleaning',
      'Commercial Cleaning'
    ],
    'Painting': [
      'Interior Painting',
      'Exterior Painting',
      'Wall Painting',
      'Ceiling Painting',
      'Furniture Painting',
      'Cabinet Painting',
      'Fence Painting',
      'Deck Staining',
      'Drywall Repair & Paint',
      'Commercial Painting'
    ],
    'Carpentry': [
      'Furniture Assembly',
      'Custom Cabinets',
      'Deck Building',
      'Door Installation',
      'Window Installation',
      'Trim Work',
      'Shelving Installation',
      'Flooring Installation',
      'Framing',
      'Home Repairs'
    ],
    'Gardening': [
      'Lawn Maintenance',
      'Garden Design',
      'Tree Trimming',
      'Landscaping',
      'Irrigation Installation',
      'Weed Control',
      'Fertilization',
      'Seasonal Cleanup',
      'Hedge Trimming',
      'Garden Installation'
    ],
    'Moving': [
      'Local Moving',
      'Long Distance Moving',
      'Packing Services',
      'Furniture Moving',
      'Office Moving',
      'Piano Moving',
      'Storage Services',
      'Moving Supplies',
      'Unpacking Services',
      'Heavy Item Moving'
    ],
    'Appliance Repair': [
      'Washing Machine Repair',
      'Dryer Repair',
      'Refrigerator Repair',
      'Dishwasher Repair',
      'Oven Repair',
      'Microwave Repair',
      'Air Conditioner Repair',
      'Water Heater Repair',
      'Garbage Disposal Repair',
      'Small Appliance Repair'
    ],
    'Computer Repair': [
      'Laptop Repair',
      'Desktop Repair',
      'Virus Removal',
      'Data Recovery',
      'Hardware Installation',
      'Software Installation',
      'Network Setup',
      'System Optimization',
      'Screen Replacement',
      'Tech Support'
    ],
    'Home Maintenance': [
      'General Handyman',
      'Home Inspection',
      'Gutter Cleaning',
      'Roof Repair',
      'HVAC Maintenance',
      'Weatherproofing',
      'Lock Installation',
      'Tile Repair',
      'Caulking',
      'General Repairs'
    ]
  };

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
      _priceController.text = (widget.initialData!['price'] ?? 0).toString();
      _durationController.text =
          (widget.initialData!['durationMinutes'] ?? 60).toString();

      final tags = widget.initialData!['tags'] as List<dynamic>?;
      if (tags != null && tags.isNotEmpty) {
        _tagsController.text = tags.join(', ');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serviceSuggestions = categoryServices[widget.providerCategory] ?? [];

    return Dialog(
      insetPadding: EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF2A9D8F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.work, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.serviceId == null
                              ? 'Add New Service'
                              : 'Edit Service',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Category: ${widget.providerCategory}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service suggestions section
                      if (serviceSuggestions.isNotEmpty) ...[
                        Text(
                          'Popular ${widget.providerCategory} Services:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: serviceSuggestions.length,
                            itemBuilder: (context, index) {
                              final service = serviceSuggestions[index];
                              return GestureDetector(
                                onTap: () {
                                  _nameController.text = service;
                                  // Auto-fill some basic info based on service type
                                  _setDefaultValuesForService(service);
                                },
                                child: Container(
                                  width: 140,
                                  margin: EdgeInsets.only(right: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF2A9D8F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Color(0xFF2A9D8F).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        _getServiceIcon(service),
                                        color: Color(0xFF2A9D8F),
                                        size: 24,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        service,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2A9D8F),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Spacer(),
                                      Text(
                                        'Tap to use',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Divider(),
                        SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Service Name *',
                          hintText:
                              'e.g., ${serviceSuggestions.isNotEmpty ? serviceSuggestions[0] : 'Enter service name'}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a service name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Category display (read-only)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category, color: Color(0xFF2A9D8F)),
                            SizedBox(width: 12),
                            Text(
                              'Category: ${widget.providerCategory}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2A9D8F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description *',
                          hintText:
                              'Describe your ${widget.providerCategory.toLowerCase()} service in detail...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: 'Price (\Rs) *',
                                hintText: '50.00',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a price';
                                }
                                try {
                                  double price = double.parse(value);
                                  if (price <= 0) {
                                    return 'Price must be greater than 0';
                                  }
                                } catch (e) {
                                  return 'Please enter a valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: InputDecoration(
                                labelText: 'Duration (min) *',
                                hintText: '60',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: Icon(Icons.timer),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter duration';
                                }
                                try {
                                  int duration = int.parse(value);
                                  if (duration <= 0) {
                                    return 'Duration must be greater than 0';
                                  }
                                } catch (e) {
                                  return 'Please enter a valid duration';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: 'Tags (optional)',
                          hintText: _getCategoryTags(widget.providerCategory),
                          helperText: 'Separate tags with commas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.local_offer),
                        ),
                      ),
                      SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveService,
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(widget.serviceId == null
                                      ? 'Add Service'
                                      : 'Update Service'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2A9D8F),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setDefaultValuesForService(String serviceName) {
    // Set default duration and suggested price based on service type
    Map<String, Map<String, dynamic>> serviceDefaults = {
      'Electrical Installation': {'duration': '120', 'price': '75.00'},
      'Wiring Repair': {'duration': '90', 'price': '85.00'},
      'House Cleaning': {'duration': '180', 'price': '100.00'},
      'Deep Cleaning': {'duration': '240', 'price': '150.00'},
      'Pipe Repair': {'duration': '60', 'price': '80.00'},
      'Drain Cleaning': {'duration': '45', 'price': '65.00'},
      'Interior Painting': {'duration': '480', 'price': '200.00'},
      'Exterior Painting': {'duration': '600', 'price': '300.00'},
      'Furniture Assembly': {'duration': '90', 'price': '50.00'},
      'Lawn Maintenance': {'duration': '120', 'price': '40.00'},
      'Local Moving': {'duration': '240', 'price': '120.00'},
      'Washing Machine Repair': {'duration': '60', 'price': '70.00'},
      'Laptop Repair': {'duration': '90', 'price': '80.00'},
    };

    final defaults = serviceDefaults[serviceName];
    if (defaults != null) {
      _durationController.text = defaults['duration'];
      _priceController.text = defaults['price'];
    }
  }

  IconData _getServiceIcon(String service) {
    if (service.contains('Installation')) return Icons.build;
    if (service.contains('Repair')) return Icons.handyman;
    if (service.contains('Cleaning')) return Icons.cleaning_services;
    if (service.contains('Painting')) return Icons.format_paint;
    if (service.contains('Moving')) return Icons.local_shipping;
    return Icons.work;
  }

  String _getCategoryTags(String category) {
    Map<String, String> categoryTagSuggestions = {
      'Electrical': 'e.g., licensed, emergency, 24/7, certified',
      'Plumbing': 'e.g., emergency, licensed, leak detection, 24/7',
      'Cleaning': 'e.g., eco-friendly, deep clean, reliable, insured',
      'Painting': 'e.g., interior, exterior, professional, quality',
      'Carpentry': 'e.g., custom, handmade, quality, experienced',
      'Gardening': 'e.g., organic, landscaping, seasonal, maintenance',
      'Moving': 'e.g., careful, insured, packing, local',
      'Appliance Repair': 'e.g., warranty, experienced, parts included',
      'Computer Repair': 'e.g., data recovery, virus removal, fast',
    };
    return categoryTagSuggestions[category] ??
        'e.g., professional, reliable, quality';
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final serviceData = {
        'providerId': user.uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': widget.providerCategory, // Use the provider's category
        'price': double.parse(_priceController.text),
        'durationMinutes': int.parse(_durationController.text),
        'tags': tags,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.serviceId == null) {
        // Add new service
        serviceData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('provider_services')
            .add(serviceData);
      } else {
        // Update existing service
        await FirebaseFirestore.instance
            .collection('provider_services')
            .doc(widget.serviceId!)
            .update(serviceData);
      }

      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving service: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
