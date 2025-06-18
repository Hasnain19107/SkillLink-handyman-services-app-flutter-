import 'package:flutter/material.dart';

class ProviderHeader extends StatelessWidget {
  final String providerName;
  final String imageUrl;
  final Stream<int> unreadNotificationCountStream;
  final VoidCallback onNotificationPressed;

  const ProviderHeader({
    Key? key,
    required this.providerName,
    required this.imageUrl,
    required this.unreadNotificationCountStream,
    required this.onNotificationPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $providerName',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            StreamBuilder<int>(
              stream: unreadNotificationCountStream,
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      onPressed: onNotificationPressed,
                      icon: Icon(
                        unreadCount > 0
                            ? Icons.notifications_active
                            : Icons.notifications_outlined,
                        color: unreadCount > 0
                            ? const Color(0xFF2A9D8F)
                            : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.grey[600]),
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: unreadCount > 0
                            ? const Color(0xFF2A9D8F).withOpacity(0.1)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
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
              },
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
                  ? ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person,
                              size: 24, color: Colors.grey[600]);
                        },
                      ),
                    )
                  : Icon(Icons.person, size: 24, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
