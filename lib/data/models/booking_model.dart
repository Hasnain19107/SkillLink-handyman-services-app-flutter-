import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String? id;
  final String seekerId;
  final String seekerName;
  final String? seekerPhone;
  final String providerId;
  final String providerName;
  final String? providerProfession;
  final String? providerImage;
  final String serviceName;
  final String jobDescription;
  final String address;
  final DateTime? date;
  final String? time;
  final DateTime? bookingDate;
  final double budget;
  final String status;
  final List<String> imageUrls;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  // New fields
  final String? serviceId;
  final double? servicePrice;
  final String? serviceDuration;

  // Completion related fields
  final bool? isProviderCompleted;
  final DateTime? providerCompletedAt;
  final bool? isSeekerConfirmed;
  final DateTime? seekerConfirmedAt;
  final DateTime? autoConfirmDeadline;

  // Change request fields
  final String? changeRequest;
  final DateTime? changeRequestedAt;
  final bool? changeRequestAcknowledged;
  final DateTime? changeRequestAcknowledgedAt;

  // Rating and review fields
  final double? rating;
  final String? review;
  final DateTime? reviewedAt;

  // Report related fields
  final bool? hasReport;
  final DateTime? reportedAt;

  // Cancellation fields
  final DateTime? cancelledAt;
  final String? cancellationReason;

  BookingModel({
    this.id,
    required this.seekerId,
    required this.seekerName,
    this.seekerPhone,
    required this.providerId,
    required this.providerName,
    this.providerProfession,
    this.providerImage,
    required this.serviceName,
    required this.jobDescription,
    required this.address,
    this.date,
    this.time,
    this.bookingDate,
    required this.budget,
    required this.status,
    this.imageUrls = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.serviceId,
    this.servicePrice,
    this.serviceDuration,
    this.isProviderCompleted,
    this.providerCompletedAt,
    this.isSeekerConfirmed,
    this.seekerConfirmedAt,
    this.autoConfirmDeadline,
    this.changeRequest,
    this.changeRequestedAt,
    this.changeRequestAcknowledged,
    this.changeRequestAcknowledgedAt,
    this.rating,
    this.review,
    this.reviewedAt,
    this.hasReport,
    this.reportedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  // Create from Firestore document
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BookingModel(
      id: doc.id,
      seekerId: data['seekerId']?.toString() ?? '',
      seekerName: data['seekerName']?.toString() ?? '',
      seekerPhone: data['seekerPhone']?.toString(),
      providerId: data['providerId']?.toString() ?? '',
      providerName: data['providerName']?.toString() ?? '',
      providerProfession: data['providerProfession']?.toString(),
      providerImage: data['providerImage']?.toString(),
      serviceName: data['serviceName']?.toString() ?? '',
      jobDescription: data['jobDescription']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
      time: data['time']?.toString(),
      bookingDate: data['bookingDate'] != null
          ? (data['bookingDate'] as Timestamp).toDate()
          : null,
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'pending',
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      notes: data['notes']?.toString(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
      serviceId: data['serviceId']?.toString(),
      servicePrice: (data['servicePrice'] as num?)?.toDouble(),
      serviceDuration: data['serviceDuration']?.toString(),
      isProviderCompleted: data['isProviderCompleted'] as bool?,
      providerCompletedAt: data['providerCompletedAt'] != null
          ? (data['providerCompletedAt'] as Timestamp).toDate()
          : null,
      isSeekerConfirmed: data['isSeekerConfirmed'] as bool?,
      seekerConfirmedAt: data['seekerConfirmedAt'] != null
          ? (data['seekerConfirmedAt'] as Timestamp).toDate()
          : null,
      autoConfirmDeadline: data['autoConfirmDeadline'] != null
          ? (data['autoConfirmDeadline'] as Timestamp).toDate()
          : null,
      changeRequest: data['changeRequest']?.toString(),
      changeRequestedAt: data['changeRequestedAt'] != null
          ? (data['changeRequestedAt'] as Timestamp).toDate()
          : null,
      changeRequestAcknowledged: data['changeRequestAcknowledged'] as bool?,
      changeRequestAcknowledgedAt: data['changeRequestAcknowledgedAt'] != null
          ? (data['changeRequestAcknowledgedAt'] as Timestamp).toDate()
          : null,
      rating: (data['rating'] as num?)?.toDouble(),
      review: data['review']?.toString(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      hasReport: data['hasReport'] as bool?,
      reportedAt: data['reportedAt'] != null
          ? (data['reportedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason']?.toString(),
    );
  }

  // Create from Map with optional ID
  factory BookingModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return BookingModel(
      id: id ?? map['id'],
      seekerId: map['seekerId'] ?? '',
      seekerName: map['seekerName'] ?? '',
      seekerPhone: map['seekerPhone'],
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      providerProfession: map['providerProfession'],
      providerImage: map['providerImage'],
      serviceName: map['serviceName'] ?? '',
      jobDescription: map['jobDescription'] ?? '',
      address: map['address'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : map['date'] is DateTime
              ? map['date'] as DateTime
              : null,
      time: map['time'],
      bookingDate: map['bookingDate'] is Timestamp
          ? (map['bookingDate'] as Timestamp).toDate()
          : map['bookingDate'] is DateTime
              ? map['bookingDate'] as DateTime
              : null,
      budget: (map['budget'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      imageUrls: (map['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: map['notes'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] is DateTime
              ? map['updatedAt'] as DateTime
              : null,
      isActive: map['isActive'] ?? true,
      serviceId: map['serviceId'],
      servicePrice: map['servicePrice']?.toDouble(),
      serviceDuration: map['serviceDuration'],
      isProviderCompleted: map['isProviderCompleted'],
      providerCompletedAt: map['providerCompletedAt'] is Timestamp
          ? (map['providerCompletedAt'] as Timestamp).toDate()
          : null,
      isSeekerConfirmed: map['isSeekerConfirmed'],
      seekerConfirmedAt: map['seekerConfirmedAt'] is Timestamp
          ? (map['seekerConfirmedAt'] as Timestamp).toDate()
          : null,
      autoConfirmDeadline: map['autoConfirmDeadline'] is Timestamp
          ? (map['autoConfirmDeadline'] as Timestamp).toDate()
          : null,
      changeRequest: map['changeRequest'],
      changeRequestedAt: map['changeRequestedAt'] is Timestamp
          ? (map['changeRequestedAt'] as Timestamp).toDate()
          : null,
      changeRequestAcknowledged: map['changeRequestAcknowledged'],
      changeRequestAcknowledgedAt:
          map['changeRequestAcknowledgedAt'] is Timestamp
              ? (map['changeRequestAcknowledgedAt'] as Timestamp).toDate()
              : null,
      rating: map['rating']?.toDouble(),
      review: map['review'],
      reviewedAt: map['reviewedAt'] is Timestamp
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
      hasReport: map['hasReport'],
      reportedAt: map['reportedAt'] is Timestamp
          ? (map['reportedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: map['cancelledAt'] is Timestamp
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'seekerId': seekerId,
      'seekerName': seekerName,
      if (seekerPhone != null) 'seekerPhone': seekerPhone,
      'providerId': providerId,
      'providerName': providerName,
      if (providerProfession != null) 'providerProfession': providerProfession,
      if (providerImage != null) 'providerImage': providerImage,
      'serviceName': serviceName,
      'jobDescription': jobDescription,
      'address': address,
      if (date != null) 'date': Timestamp.fromDate(date!),
      if (time != null) 'time': time,
      if (bookingDate != null) 'bookingDate': Timestamp.fromDate(bookingDate!),
      'budget': budget,
      'status': status,
      'imageUrls': imageUrls,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'isActive': isActive,
      if (serviceId != null) 'serviceId': serviceId,
      if (servicePrice != null) 'servicePrice': servicePrice,
      if (serviceDuration != null) 'serviceDuration': serviceDuration,
      if (isProviderCompleted != null)
        'isProviderCompleted': isProviderCompleted,
      if (providerCompletedAt != null)
        'providerCompletedAt': Timestamp.fromDate(providerCompletedAt!),
      if (isSeekerConfirmed != null) 'isSeekerConfirmed': isSeekerConfirmed,
      if (seekerConfirmedAt != null)
        'seekerConfirmedAt': Timestamp.fromDate(seekerConfirmedAt!),
      if (autoConfirmDeadline != null)
        'autoConfirmDeadline': Timestamp.fromDate(autoConfirmDeadline!),
      if (changeRequest != null) 'changeRequest': changeRequest,
      if (changeRequestedAt != null)
        'changeRequestedAt': Timestamp.fromDate(changeRequestedAt!),
      if (changeRequestAcknowledged != null)
        'changeRequestAcknowledged': changeRequestAcknowledged,
      if (changeRequestAcknowledgedAt != null)
        'changeRequestAcknowledgedAt':
            Timestamp.fromDate(changeRequestAcknowledgedAt!),
      if (rating != null) 'rating': rating,
      if (review != null) 'review': review,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (hasReport != null) 'hasReport': hasReport,
      if (reportedAt != null) 'reportedAt': Timestamp.fromDate(reportedAt!),
      if (cancelledAt != null) 'cancelledAt': Timestamp.fromDate(cancelledAt!),
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
    };
  }

  // Convenience getters
  String get formattedDate {
    if (date != null) {
      return '${date!.day}/${date!.month}/${date!.year}';
    } else if (bookingDate != null) {
      return '${bookingDate!.day}/${bookingDate!.month}/${bookingDate!.year}';
    }
    return 'Date not available';
  }

  String get formattedTime {
    if (time != null) {
      return time!;
    } else if (bookingDate != null) {
      final hour = bookingDate!.hour;
      final minute = bookingDate!.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }
    return 'Time not available';
  }

  String get formattedBudget => '\$${budget.toStringAsFixed(2)}';

  bool get isPendingConfirmation {
    // Check if provider marked as completed but seeker hasn't confirmed
    return (isProviderCompleted == true && isSeekerConfirmed != true) ||
        status.toLowerCase() == 'pending_confirmation';
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';

  bool get hasChangeRequest =>
      changeRequest != null &&
      changeRequest!.isNotEmpty &&
      (changeRequestAcknowledged != true);

  String get autoConfirmText {
    if (isPendingConfirmation && autoConfirmDeadline != null) {
      final daysLeft = autoConfirmDeadline!.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        return 'Auto-confirms in $daysLeft days';
      } else {
        return 'Will auto-confirm soon';
      }
    }
    return '';
  }

  // Copy with method for easy updates
  BookingModel copyWith({
    String? id,
    String? seekerId,
    String? seekerName,
    String? seekerPhone,
    String? providerId,
    String? providerName,
    String? providerProfession,
    String? providerImage,
    String? serviceName,
    String? jobDescription,
    String? address,
    DateTime? date,
    String? time,
    DateTime? bookingDate,
    double? budget,
    String? status,
    List<String>? imageUrls,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? serviceId,
    double? servicePrice,
    String? serviceDuration,
    bool? isProviderCompleted,
    DateTime? providerCompletedAt,
    bool? isSeekerConfirmed,
    DateTime? seekerConfirmedAt,
    DateTime? autoConfirmDeadline,
    String? changeRequest,
    DateTime? changeRequestedAt,
    bool? changeRequestAcknowledged,
    DateTime? changeRequestAcknowledgedAt,
    double? rating,
    String? review,
    DateTime? reviewedAt,
    bool? hasReport,
    DateTime? reportedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    required String paymentStatus,
    required String paymentMethod,
  }) {
    return BookingModel(
      id: id ?? this.id,
      seekerId: seekerId ?? this.seekerId,
      seekerName: seekerName ?? this.seekerName,
      seekerPhone: seekerPhone ?? this.seekerPhone,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerProfession: providerProfession ?? this.providerProfession,
      providerImage: providerImage ?? this.providerImage,
      serviceName: serviceName ?? this.serviceName,
      jobDescription: jobDescription ?? this.jobDescription,
      address: address ?? this.address,
      date: date ?? this.date,
      time: time ?? this.time,
      bookingDate: bookingDate ?? this.bookingDate,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      serviceId: serviceId ?? this.serviceId,
      servicePrice: servicePrice ?? this.servicePrice,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      isProviderCompleted: isProviderCompleted ?? this.isProviderCompleted,
      providerCompletedAt: providerCompletedAt ?? this.providerCompletedAt,
      isSeekerConfirmed: isSeekerConfirmed ?? this.isSeekerConfirmed,
      seekerConfirmedAt: seekerConfirmedAt ?? this.seekerConfirmedAt,
      autoConfirmDeadline: autoConfirmDeadline ?? this.autoConfirmDeadline,
      changeRequest: changeRequest ?? this.changeRequest,
      changeRequestedAt: changeRequestedAt ?? this.changeRequestedAt,
      changeRequestAcknowledged:
          changeRequestAcknowledged ?? this.changeRequestAcknowledged,
      changeRequestAcknowledgedAt:
          changeRequestAcknowledgedAt ?? this.changeRequestAcknowledgedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      hasReport: hasReport ?? this.hasReport,
      reportedAt: reportedAt ?? this.reportedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, seekerName: $seekerName, providerName: $providerName, serviceName: $serviceName, serviceId: $serviceId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum for booking status
enum BookingStatus {
  pending,
  confirmed,
  pendingConfirmation,
  completed,
  cancelled,
  disputed,
}

extension BookingStatusExtension on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.pendingConfirmation:
        return 'pending_confirmation';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.disputed:
        return 'disputed';
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.pendingConfirmation:
        return 'To Confirm';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'pending_confirmation':
        return BookingStatus.pendingConfirmation;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'disputed':
        return BookingStatus.disputed;
      default:
        return BookingStatus.pending;
    }
  }
}
