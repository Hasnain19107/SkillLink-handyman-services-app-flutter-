import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/booking_model.dart';

import '../../../notification/notification_fcm.dart';
import '../ratings/rating_reviews.dart';
import 'booking_service.dart';
import 'booking_report.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with TickerProviderStateMixin {
  // State variables
  bool isLoading = false;
  String searchQuery = '';
  List<BookingModel> allBookings = [];
  Map<String, Map<String, dynamic>> providerDataCache = {};
  Map<String, String> providerImageCache = {};

  // Controllers
  late TabController tabController;
  final TextEditingController searchController = TextEditingController();

  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 5, vsync: this);
    _setupSearchListener();
  }

  @override
  void dispose() {
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream for bookings
  Stream<QuerySnapshot> getBookingsStream(String status) {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('booking_service')
        .where('seekerId', isEqualTo: currentUserId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Filter bookings based on search query
  List<BookingModel> filterBookings(List<QueryDocumentSnapshot> docs) {
    final bookings = docs
        .map((doc) {
          try {
            return BookingModel.fromFirestore(doc);
          } catch (e) {
            print('Error parsing booking document ${doc.id}: $e');
            return null;
          }
        })
        .where((booking) => booking != null)
        .cast<BookingModel>()
        .toList();

    if (searchQuery.isEmpty) return bookings;

    return bookings.where((booking) {
      return booking.providerName.toLowerCase().contains(searchQuery) ||
          (booking.providerProfession?.toLowerCase().contains(searchQuery) ??
              false) ||
          booking.serviceName.toLowerCase().contains(searchQuery) ||
          booking.address.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Get provider image URL with caching
  Future<String> getProviderImageUrl(
      String providerId, String? existingUrl) async {
    // Check cache first
    if (providerImageCache.containsKey(providerId)) {
      return providerImageCache[providerId]!;
    }

    if (existingUrl != null && existingUrl.isNotEmpty) {
      providerImageCache[providerId] = existingUrl;
      return existingUrl;
    }

    try {
      final providerDoc = await _firestore
          .collection('service_providers')
          .doc(providerId)
          .get();

      if (providerDoc.exists) {
        final profileImageUrl = providerDoc.data()?['profileImageUrl'];
        if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
          final url = profileImageUrl.toString();
          providerImageCache[providerId] = url;
          return url;
        }
      }

      final ref =
          _storage.ref().child('profile_images').child('$providerId.jpg');

      final url = await ref.getDownloadURL().timeout(
            const Duration(seconds: 5),
            onTimeout: () => '',
          );

      final finalUrl = url.isNotEmpty
          ? url
          : 'https://randomuser.me/api/portraits/lego/1.jpg';
      providerImageCache[providerId] = finalUrl;
      return finalUrl;
    } catch (e) {
      const defaultUrl = 'https://randomuser.me/api/portraits/lego/1.jpg';
      providerImageCache[providerId] = defaultUrl;
      return defaultUrl;
    }
  }

  // Get provider data with caching
  Future<Map<String, dynamic>> getProviderData(String providerId) async {
    // Check cache first
    if (providerDataCache.containsKey(providerId)) {
      return providerDataCache[providerId]!;
    }

    try {
      final providerDoc = await _firestore
          .collection('service_providers')
          .doc(providerId)
          .get();

      Map<String, dynamic> data;
      if (providerDoc.exists) {
        final docData = providerDoc.data()!;
        data = {
          'fullName': docData['fullName'] ?? 'Name not available',
          'category': docData['category'] ?? 'Category not set',
          'profileImageUrl': docData['profileImageUrl'] ?? '',
        };
      } else {
        data = {
          'fullName': 'Name not available',
          'category': 'Category not set',
          'profileImageUrl': '',
        };
      }

      providerDataCache[providerId] = data;
      return data;
    } catch (e) {
      final errorData = {
        'fullName': 'Error loading name',
        'category': 'Error loading category',
        'profileImageUrl': '',
      };
      providerDataCache[providerId] = errorData;
      return errorData;
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final bookingDoc =
          await _firestore.collection('booking_service').doc(bookingId).get();

      final booking = BookingModel.fromFirestore(bookingDoc);

      await _firestore.collection('booking_service').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      await NotificationService().notifyBookingCancelled(
        recipientId: booking.providerId,
        bookingId: bookingId,
        cancellerId: _auth.currentUser!.uid,
        cancellerName: booking.seekerName,
        serviceName: booking.serviceName,
        isCancelledByProvider: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Confirm completion
  Future<void> confirmCompletion(String bookingId, String providerId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final bookingDoc =
          await _firestore.collection('booking_service').doc(bookingId).get();

      final booking = BookingModel.fromFirestore(bookingDoc);

      await _firestore.collection('booking_service').doc(bookingId).update({
        'status': 'completed',
        'isSeekerConfirmed': true,
        'seekerConfirmedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService().notifyBookingConfirmed(
        providerId: providerId,
        bookingId: bookingId,
        seekerName: booking.seekerName,
        serviceName: booking.serviceName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service confirmed as completed'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to rating screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RatingReviewScreen(
              bookingId: bookingId,
              providerId: providerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming completion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = '';
    });
  }

  // Get status data
  Map<String, dynamic> getStatusData(String status) {
    switch (status) {
      case 'pending':
        return {
          'color': Colors.orange,
          'icon': Icons.hourglass_empty,
          'label': 'Pending'
        };
      case 'confirmed':
        return {
          'color': Colors.purple,
          'icon': Icons.check_circle,
          'label': 'Confirmed'
        };
      case 'pending_confirmation':
        return {
          'color': Colors.amber,
          'icon': Icons.pending_actions,
          'label': 'To Confirm'
        };
      case 'completed':
        return {
          'color': Colors.green,
          'icon': Icons.task_alt,
          'label': 'Completed'
        };
      case 'cancelled':
        return {
          'color': Colors.red,
          'icon': Icons.cancel,
          'label': 'Cancelled'
        };
      case 'disputed':
        return {
          'color': Colors.deepOrange,
          'icon': Icons.gavel,
          'label': 'Disputed'
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help_outline,
          'label': 'Unknown'
        };
    }
  }

  // Show cancel confirmation dialog
  Future<void> showCancelDialog(String bookingId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result == true) {
      await cancelBooking(bookingId);
    }
  }

  // Handle menu actions
  void handleMenuAction(String action, BookingModel booking) {
    switch (action) {
      case 'cancel':
        showCancelDialog(booking.id!);
        break;
      case 'report':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportIssueScreen(
              bookingId: booking.id!,
              bookingData: booking.toMap(),
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _SearchBar(),
                _TabBar(),
                Expanded(
                  child: currentUserId == null
                      ? const Center(
                          child: Text('Please sign in to view your bookings'))
                      : TabBarView(
                          controller: tabController,
                          children: [
                            _BookingsList(status: 'pending'),
                            _BookingsList(status: 'confirmed'),
                            _BookingsList(status: 'pending_confirmation'),
                            _BookingsList(status: 'completed'),
                            _BookingsList(status: 'cancelled'),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _SearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search bookings...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: clearSearch,
                )
              : null,
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _TabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Ongoing'),
          Tab(text: 'To Confirm'),
          Tab(text: 'Completed'),
          Tab(text: 'Cancelled'),
        ],
      ),
    );
  }

  Widget _BookingsList({required String status}) {
    return StreamBuilder<QuerySnapshot>(
      stream: getBookingsStream(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allBookings = snapshot.data?.docs ?? [];
        final bookings = filterBookings(allBookings);

        if (bookings.isEmpty) {
          return _EmptyState(status: status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) =>
              _BookingCard(booking: bookings[index]),
        );
      },
    );
  }

  Widget _EmptyState({required String status}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty
                ? Icons.search_off
                : Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No bookings match your search'
                : 'No $status bookings found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: clearSearch,
                child: const Text('Clear Search'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _BookingCard({required BookingModel booking}) {
    final formattedDate = booking.bookingDate != null
        ? DateFormat('MMM dd, yyyy').format(booking.bookingDate!)
        : 'Date not available';

    final statusData = getStatusData(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(booking: booking, statusData: statusData),
            if (booking.autoConfirmText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 52.0),
                child: Text(
                  booking.autoConfirmText,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _CardInfo(booking: booking, formattedDate: formattedDate),
            const SizedBox(height: 8),
            _CardActions(booking: booking),
          ],
        ),
      ),
    );
  }

  Widget _CardHeader(
      {required BookingModel booking,
      required Map<String, dynamic> statusData}) {
    return Row(
      children: [
        FutureBuilder<String>(
          future:
              getProviderImageUrl(booking.providerId, booking.providerImage),
          builder: (context, snapshot) {
            final imageUrl = snapshot.data ??
                'https://randomuser.me/api/portraits/lego/1.jpg';
            return CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(imageUrl),
              child: snapshot.hasError || imageUrl.isEmpty
                  ? Icon(Icons.person, size: 20, color: Colors.grey[600])
                  : null,
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(child: _ProviderCardInfo(booking: booking)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: statusData['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                statusData['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusData['color'],
                ),
              ),
            ),
            if (!booking.isCancelled) _MenuButton(booking: booking),
          ],
        ),
      ],
    );
  }

  Widget _ProviderCardInfo({required BookingModel booking}) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getProviderData(booking.providerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final providerData = snapshot.data ??
            {
              'fullName': 'Name not available',
              'category': 'Category not set',
            };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              providerData['fullName'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              providerData['category'],
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        );
      },
    );
  }

  Widget _MenuButton({required BookingModel booking}) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey, size: 24),
      onSelected: (value) => handleMenuAction(value, booking),
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        if (booking.isPending || booking.isConfirmed) {
          items.add(const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text('Cancel Booking'),
              ],
            ),
          ));
        }

        items.add(const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Report'),
            ],
          ),
        ));

        return items;
      },
    );
  }

  Widget _CardInfo(
      {required BookingModel booking, required String formattedDate}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              booking.time ?? 'Not specified',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _CardActions({required BookingModel booking}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          booking.formattedBudget,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Row(
          children: [
            TextButton(
              onPressed: () => _showBookingDetails(context, booking),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('View Details'),
            ),
            if (booking.isPendingConfirmation)
              TextButton(
                onPressed: () =>
                    confirmCompletion(booking.id!, booking.providerId),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Confirm'),
              )
            else if (booking.isCompleted)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingServiceScreen(providerId: booking.providerId),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Book Again'),
              ),
          ],
        ),
      ],
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _BookingDetailSheet(booking: booking),
    );
  }

  Widget _BookingDetailSheet({required BookingModel booking}) {
    final formattedDate = booking.bookingDate != null
        ? DateFormat('MMMM dd, yyyy').format(booking.bookingDate!)
        : 'Date not available';

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Booking Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _buildProviderInfo(booking),
                const SizedBox(height: 16),
                _buildBasicServiceInfo(booking),
                const SizedBox(height: 16),
                _buildDetailItem('Status', _getStatusWidget(booking.status)),
                if (booking.autoConfirmText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      booking.autoConfirmText,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _buildDetailItem(
                    'Job Description', Text(booking.jobDescription)),
                _buildDetailItem('Service Address', Text(booking.address)),
                _buildDetailItem(
                  'Date & Time',
                  Text('$formattedDate at ${booking.time ?? 'Not specified'}'),
                ),
                _buildDetailItem('Budget', Text(booking.formattedBudget)),
                if (booking.notes?.isNotEmpty == true)
                  _buildDetailItem('Notes', Text(booking.notes!)),
                if (booking.rating != null)
                  _buildDetailItem(
                    'Rating',
                    Text('${booking.rating!.toStringAsFixed(1)} / 5.0'),
                  ),
                if (booking.review?.isNotEmpty == true)
                  _buildDetailItem('Review', Text(booking.review!)),
                const SizedBox(height: 24),
                _buildActionButtons(booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderInfo(BookingModel booking) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: FutureBuilder<String>(
        future: getProviderImageUrl(booking.providerId, booking.providerImage),
        builder: (context, snapshot) {
          final imageUrl =
              snapshot.data ?? 'https://randomuser.me/api/portraits/lego/1.jpg';
          return CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(imageUrl),
            backgroundColor: Colors.grey[200],
            child: snapshot.hasError || imageUrl.isEmpty
                ? Icon(Icons.person, size: 20, color: Colors.grey[600])
                : null,
          );
        },
      ),
      title: Text(
        booking.providerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(booking.providerProfession ?? 'Service Provider'),
    );
  }

  Widget _buildActionButtons(BookingModel booking) {
    if (booking.isPendingConfirmation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The service provider has marked this job as completed.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('Please confirm if you are satisfied with the work:'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                confirmCompletion(booking.id!, booking.providerId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Completion'),
            ),
          ),
        ],
      );
    } else if (!booking.isCompleted &&
        !booking.isCancelled &&
        booking.status != 'disputed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            showCancelDialog(booking.id!);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancel Booking'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetailItem(String label, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          content,
        ],
      ),
    );
  }

  Widget _getStatusWidget(String status) {
    final statusData = getStatusData(status);
    return Row(
      children: [
        Icon(statusData['icon'], color: statusData['color'], size: 18),
        const SizedBox(width: 4),
        Text(
          statusData['label'],
          style: TextStyle(
            color: statusData['color'],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicServiceInfo(BookingModel booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Service Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.serviceName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'General ${booking.providerProfession ?? 'Service'} request',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
