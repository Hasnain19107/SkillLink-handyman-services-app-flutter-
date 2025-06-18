import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../verification/provider_verification_screen.dart';
import 'chat_screen.dart';

class ProviderMessagesScreen extends StatefulWidget {
  final VoidCallback? onNavigateHome;

  const ProviderMessagesScreen({Key? key, this.onNavigateHome})
      : super(key: key);

  @override
  State<ProviderMessagesScreen> createState() => _ProviderMessagesScreenState();
}

class _ProviderMessagesScreenState extends State<ProviderMessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String _verificationStatus = 'unverified';

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final providerDoc = await _firestore
            .collection('service_providers')
            .doc(user.uid)
            .get();

        if (providerDoc.exists) {
          setState(() {
            _verificationStatus =
                providerDoc.data()?['verificationStatus'] ?? 'unverified';
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error checking verification status: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Messages'),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2A9D8F),
          ),
        ),
      );
    }

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Messages'),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view your messages'),
        ),
      );
    }

    // Show verification required screen if not verified
    if (_verificationStatus != 'verified' && _verificationStatus != 'pending') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Messages'),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: _buildVerificationRequiredScreen(),
      );
    }

    // Show limited access screen if pending verification
    if (_verificationStatus == 'pending') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Messages'),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
        ),
        body: _buildPendingVerificationScreen(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Messages'),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.grey[400] : Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Chat list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2A9D8F),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter chats where the current user is the provider
                final allChats = snapshot.data!.docs;
                final providerChats = allChats.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['providerId'] == currentUserId;
                }).toList();

                if (providerChats.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter chats based on search query if needed
                final filteredChats = _searchQuery.isEmpty
                    ? providerChats
                    : providerChats.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final lastMessage =
                            (data['lastMessage'] ?? '').toLowerCase();
                        return lastMessage.contains(_searchQuery);
                      }).toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations found',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final chatData =
                        filteredChats[index].data() as Map<String, dynamic>;
                    final chatId = filteredChats[index].id;

                    final seekerId = chatData['seekerId'] as String?;

                    if (seekerId == null) {
                      return const SizedBox.shrink();
                    }

                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getSeekerData(seekerId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            leading: CircleAvatar(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            title: Text('Loading...'),
                          );
                        }

                        final userData = userSnapshot.data ?? {};
                        final userName = userData['fullName'] ?? 'Seeker';
                        final userImage = userData['imageUrl'] ?? '';

                        final lastMessage = chatData['lastMessage'] ?? '';
                        final lastMessageTime =
                            chatData['lastMessageTime'] as Timestamp?;
                        final formattedTime = _formatChatTime(lastMessageTime);

                        // Check for unread messages
                        return StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('chats')
                              .doc(chatId)
                              .collection('messages')
                              .where('senderId', isNotEqualTo: currentUserId)
                              .where('isRead', isEqualTo: false)
                              .snapshots(),
                          builder: (context, unreadSnapshot) {
                            int unreadCount = 0;
                            bool hasUnread = false;

                            if (unreadSnapshot.hasData &&
                                !unreadSnapshot.hasError) {
                              unreadCount = unreadSnapshot.data!.docs.length;
                              hasUnread = unreadCount > 0;
                            }

                            return _buildChatTile(
                              chatId: chatId,
                              name: userName,
                              imageUrl: userImage,
                              lastMessage: lastMessage,
                              time: formattedTime,
                              hasUnread: hasUnread,
                              unreadCount: unreadCount,
                              seekerId: seekerId,
                              seekerName: userName,
                              seekerImage: userImage,
                              providerId: currentUserId,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRequiredScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.shade900.withOpacity(0.3)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.red.shade800 : Colors.red.shade200,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lock,
                    size: 80,
                    color: isDark ? Colors.red.shade300 : Colors.red,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verification Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You need to verify your account before you can access messages.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProviderVerificationScreen(),
                        ),
                      ).then((_) {
                        // Refresh verification status when returning
                        _checkVerificationStatus();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Verify Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingVerificationScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.orange.shade900.withOpacity(0.3)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? Colors.orange.shade800 : Colors.orange.shade200,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 80,
                    color: isDark ? Colors.orange.shade300 : Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verification in Progress',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your account verification is currently being reviewed. Messaging will be available once your account is verified.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProviderVerificationScreen(),
                        ),
                      ).then((_) {
                        // Refresh verification status when returning
                        _checkVerificationStatus();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Verification Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getSeekerData(String seekerId) async {
    try {
      // Get data from service_seekers collection
      final seekerDoc =
          await _firestore.collection('service_seekers').doc(seekerId).get();

      if (seekerDoc.exists) {
        final data = seekerDoc.data() as Map<String, dynamic>;
        final fullName = data['fullName'] as String?;
        final imageUrl = data['imageUrl'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          return {
            'fullName': fullName ?? 'Seeker',
            'imageUrl': imageUrl,
          };
        }
      }

      // If no valid image URL, try Firebase Storage
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('seeker_profile_images')
            .child('$seekerId.jpg');

        final imageUrl = await storageRef.getDownloadURL();

        return {
          'fullName': seekerDoc.exists && seekerDoc.data() != null
              ? seekerDoc.data()!['fullName'] ?? 'Seeker'
              : 'Seeker',
          'imageUrl': imageUrl,
        };
      } catch (storageError) {
        print('Storage error: $storageError');
        // Return data without image if storage fetch fails
        return {
          'fullName': seekerDoc.exists && seekerDoc.data() != null
              ? seekerDoc.data()!['fullName'] ?? 'Seeker'
              : 'Seeker',
          'imageUrl': '',
        };
      }
    } catch (e) {
      print('Error getting seeker data: $e');
      return {
        'fullName': 'Seeker',
        'imageUrl': '',
      };
    }
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No seeker messages yet',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'When seekers message you, they will appear here',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile({
    required String chatId,
    required String name,
    required String imageUrl,
    required String lastMessage,
    required String time,
    required bool hasUnread,
    required int unreadCount,
    required String seekerId,
    required String seekerName,
    required String seekerImage,
    required String providerId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderChatScreen(
              seekerId: seekerId,
              seekerName: seekerName,
              seekerImage: seekerImage,
              providerId: providerId,
            ),
          ),
        ).then((_) {
          // Refresh the messages list when returning from chat
          setState(() {});
        });
      },
      leading: _buildUserAvatar(seekerId, imageUrl),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        lastMessage.isEmpty ? 'No messages yet' : lastMessage,
        style: TextStyle(
          color: hasUnread
              ? (isDark ? Colors.white70 : Colors.black87)
              : (isDark ? Colors.grey[500] : Colors.grey[600]),
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: hasUnread
                  ? const Color(0xFF2A9D8F)
                  : (isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF2A9D8F),
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(String userId, String imageUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (imageUrl.isEmpty || !Uri.parse(imageUrl).isAbsolute) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
        child: Icon(Icons.person,
            size: 28, color: isDark ? Colors.grey[500] : Colors.grey[600]),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading avatar: $error');
            return Icon(Icons.person,
                size: 28, color: isDark ? Colors.grey[500] : Colors.grey[600]);
          },
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
        ),
      ),
    );
  }

  String _formatChatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      // Today, show time
      return DateFormat('h:mm a').format(messageTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // Within a week, show day name
      return DateFormat('EEEE').format(messageTime);
    } else {
      // Older, show date
      return DateFormat('MM/dd/yy').format(messageTime);
    }
  }
}
