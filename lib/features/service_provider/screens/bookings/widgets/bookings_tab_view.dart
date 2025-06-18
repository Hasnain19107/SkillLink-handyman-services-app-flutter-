import 'package:flutter/material.dart';
import 'bookings_list.dart';

class BookingsTabView extends StatelessWidget {
  final TabController tabController;

  const BookingsTabView({
    Key? key,
    required this.tabController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: const [
        BookingsList(status: 'pending'),
        BookingsList(status: 'confirmed'),
        BookingsList(status: 'pending_confirmation'),
        BookingsList(status: 'completed'),
        BookingsList(status: 'cancelled'),
      ],
    );
  }
}