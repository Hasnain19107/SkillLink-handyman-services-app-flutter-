import 'package:SkillLink/services/location_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import '../../../../data/models/booking_model.dart';
import 'booking_summary.dart';

class BookingServiceScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? providerData;
  final Map<String, dynamic>? selectedService;

  const BookingServiceScreen({
    Key? key,
    required this.providerId,
    this.providerData,
    this.selectedService,
  }) : super(key: key);

  @override
  State<BookingServiceScreen> createState() => _BookingServiceScreenState();
}

class _BookingServiceScreenState extends State<BookingServiceScreen> {
  // State variables
  bool isLoading = true;
  Map<String, dynamic> providerData = {};
  String seekerName = '';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = TimeOfDay.now();
  List<File> selectedImages = [];

  // Form controllers
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController jobDescriptionController =
      TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    jobDescriptionController.dispose();
    addressController.dispose();
    budgetController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Initialize with parameters
  void _initialize() {
    if (widget.providerData != null) {
      setState(() {
        providerData = widget.providerData!;
        isLoading = false;
      });
    } else {
      _fetchProviderData();
    }

    // Pre-fill budget if service is selected
    if (widget.selectedService != null &&
        widget.selectedService!['price'] != null) {
      final price = _formatPrice(widget.selectedService!['price']);
      budgetController.text = price;
    }

    _fetchSeekerData();
  }

  // Fetch provider data
  Future<void> _fetchProviderData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final doc = await _firestore
          .collection('service_providers')
          .doc(widget.providerId)
          .get();

      if (doc.exists) {
        setState(() {
          providerData = doc.data()!;
          isLoading = false;
        });
      } else {
        _showError('Provider not found');
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch seeker data
  Future<void> _fetchSeekerData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore.collection('service_seekers').doc(user.uid).get();

        if (doc.exists) {
          setState(() {
            seekerName = doc.data()?['fullName'] ?? 'Unknown User';
            phoneController.text = doc.data()?['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      setState(() {
        seekerName = 'Unknown User';
      });
    }
  }

  // Date selection
  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Time selection
  Future<void> selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  // Image picker
  Future<void> pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          selectedImages
              .addAll(images.map((image) => File(image.path)).toList());
        });
      }
    } catch (e) {
      _showError('Error picking images: $e');
    }
  }

  // Remove image
  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // Show location selector
  Future<void> showLocationSelector() async {
    final selectedAddress = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const LocationSelector()),
    );

    if (selectedAddress != null) {
      setState(() {
        addressController.text = selectedAddress;
      });
    }
  }

  // Create booking model
  BookingModel createBookingModel() {
    return BookingModel(
      seekerId: _auth.currentUser?.uid ?? '',
      seekerName: seekerName,
      seekerPhone: phoneController.text.trim(),
      providerId: widget.providerId,
      providerName: providerData['fullName'] ?? '',
      providerProfession: providerData['category'] ?? '',
      providerImage: providerData['imageUrl'] ?? '',
      serviceName: widget.selectedService?['name'] ??
          providerData['category'] ??
          'Service',
      serviceId: widget.selectedService?['id']?.toString(),
      servicePrice: widget.selectedService?['price'] != null
          ? double.tryParse(widget.selectedService!['price'].toString())
          : null,
      serviceDuration: widget.selectedService?['durationMinutes'] != null
          ? widget.selectedService!['durationMinutes'].toString()
          : null,
      jobDescription: jobDescriptionController.text,
      address: addressController.text,
      bookingDate: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
      time:
          '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
      budget: double.parse(budgetController.text),
      status: 'pending',
      imageUrls: [],
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // Proceed to summary
  void proceedToSummary() {
    if (formKey.currentState!.validate()) {
      final booking = createBookingModel();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSummaryScreen(
            booking: booking,
            images: selectedImages,
            bookingData: {},
          ),
        ),
      );
    }
  }

  // Format price helper
  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    if (price is double) return price.toStringAsFixed(2);
    if (price is int) return price.toDouble().toStringAsFixed(2);
    final parsed = double.tryParse(price.toString());
    return parsed?.toStringAsFixed(2) ?? '0.00';
  }

  // Format duration helper
  String formatDuration(dynamic duration) {
    if (duration == null) return '60';
    if (duration is int) return duration.toString();
    if (duration is double) return duration.toInt().toString();
    final parsed = int.tryParse(duration.toString());
    return parsed?.toString() ?? '60';
  }

  // Format price for display
  String formatPrice(dynamic price) {
    return _formatPrice(price);
  }

  // Show error
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedService != null
            ? 'Book ${widget.selectedService!['name']}'
            : 'Book Service'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Provider Card
                    _ProviderCard(),

                    // Selected Service Card
                    if (widget.selectedService != null) ...[
                      const SizedBox(height: 16),
                      _SelectedServiceCard(service: widget.selectedService!),
                    ],

                    const SizedBox(height: 24),

                    // Job Description
                    _JobDescriptionField(),

                    const SizedBox(height: 24),

                    // Images
                    _ImageSection(),

                    const SizedBox(height: 24),

                    // Address
                    _AddressField(),

                    const SizedBox(height: 24),

                    // Date & Time
                    _DateTimeSection(),

                    const SizedBox(height: 24),

                    // Budget
                    _BudgetField(),

                    const SizedBox(height: 24),

                    // Phone
                    _PhoneField(),

                    const SizedBox(height: 32),

                    // Submit Button
                    _SubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _ProviderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                providerData['imageUrl'] ??
                    'https://randomuser.me/api/portraits/lego/1.jpg',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerData['fullName'] ?? 'Provider Name',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(providerData['category'] ?? 'Profession'),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                          ' ${providerData['rating']?.toStringAsFixed(1) ?? '0.0'} (${providerData['review'] ?? '0'} review)'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _SelectedServiceCard({required Map<String, dynamic> service}) {
    return Card(
      color: const Color(0xFF2A9D8F).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF2A9D8F),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2A9D8F),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Selected Service',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              service['name']?.toString() ?? 'Unnamed Service',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              service['description']?.toString() ?? 'No description',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ServiceInfoChip(
                  Icons.attach_money,
                  '\$${formatPrice(service['price'])}',
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _ServiceInfoChip(
                  Icons.timer,
                  '${formatDuration(service['durationMinutes'])} min',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ServiceInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _JobDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Job Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: jobDescriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe the job you need done...',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a job description' : null,
        ),
      ],
    );
  }

  Widget _ImageSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upload Images (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add'),
            ),
          ],
        ),
        if (selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _AddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: addressController,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Choose location on map',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.location_on),
          ),
          onTap: showLocationSelector,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please select a location' : null,
        ),
      ],
    );
  }

  Widget _DateTimeSection() {
    return Row(
      children: [
        Expanded(child: _DateSelector()),
        const SizedBox(width: 16),
        Expanded(child: _TimeSelector()),
      ],
    );
  }

  Widget _DateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preferred Date',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _TimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preferred Time',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedTime.format(context)),
                const Icon(Icons.access_time),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _BudgetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Budget',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter your budget',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter your budget';
            if (double.tryParse(value!) == null)
              return 'Please enter a valid amount';
            return null;
          },
        ),
      ],
    );
  }

  Widget _PhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Number',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter your phone number',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter your phone number' : null,
        ),
      ],
    );
  }

  Widget _SubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: proceedToSummary,
        child: const Text('Proceed',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
