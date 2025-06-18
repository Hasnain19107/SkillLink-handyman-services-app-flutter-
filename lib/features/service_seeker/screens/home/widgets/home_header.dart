import 'package:flutter/material.dart';
import '../../notifications/notifications_screen.dart';

class HomeHeader extends StatelessWidget {
  final String name;
  final String imageUrl;
  final bool isLoading;
  final bool isRefreshing;
  final int unreadNotificationCount;

  const HomeHeader({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.isLoading,
    required this.isRefreshing,
    required this.unreadNotificationCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hello, $name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRefreshing)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isRefreshing ? 'Refreshing...' : 'Welcome back!',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildNotificationButton(context),
              const SizedBox(width: 8),
              _buildProfileImage(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            unreadNotificationCount > 0
                ? Icons.notifications_active
                : Icons.notifications_outlined,
            size: 22,
            color: unreadNotificationCount > 0 ? Colors.orange : null,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          tooltip: 'Notifications',
          padding: const EdgeInsets.all(8),
        ),
        if (unreadNotificationCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadNotificationCount > 99
                    ? '99+'
                    : unreadNotificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (isLoading) {
      return const CircularProgressIndicator(strokeWidth: 2);
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[200],
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
      onBackgroundImageError: imageUrl.isNotEmpty
          ? (exception, stackTrace) {
              print('Error loading profile image: $exception');
            }
          : null,
    );
  }
}
