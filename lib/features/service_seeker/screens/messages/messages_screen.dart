import 'package:SkillLink/features/service_seeker/screens/messages/chat_seeker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please log in to view your messages'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),

          // Chat list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2A9D8F),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
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
                          child: Text('Error loading chats'),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Filter chats where the current user is a participant
                      final allChats = snapshot.data!.docs;
                      final userChats = allChats.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final participants =
                            data['participants'] as List<dynamic>?;
                        return participants?.contains(currentUserId) ?? false;
                      }).toList();

                      if (userChats.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Filter chats based on search query if needed
                      final filteredChats = _searchQuery.isEmpty
                          ? userChats
                          : userChats.where((doc) {
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
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations found',
                                style: TextStyle(
                                  color: Colors.grey[600],
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
                          final chatData = filteredChats[index].data()
                              as Map<String, dynamic>;
                          final chatId = filteredChats[index].id;

                          // Determine if the current user is the seeker or provider
                          final seekerId = chatData['seekerId'] as String?;
                          final providerId = chatData['providerId'] as String?;

                          if (seekerId == null || providerId == null) {
                            return const SizedBox.shrink();
                          }

                          final bool isSeeker = currentUserId == seekerId;
                          final String otherUserId =
                              isSeeker ? providerId : seekerId;

                          // Collection to fetch user data from
                          final String userCollection = isSeeker
                              ? 'service_providers'
                              : 'service_seekers';

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection(userCollection)
                                .doc(otherUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              String userName = 'User';
                              String userImage = '';

                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                                userName = userData?['fullName'] ?? 'User';
                                userImage = userData?['profileImageUrl'] ?? '';
                              }

                              final lastMessage = chatData['lastMessage'] ?? '';
                              final lastMessageTime =
                                  chatData['lastMessageTime'] as Timestamp?;
                              final formattedTime =
                                  _formatChatTime(lastMessageTime);

                              // Check for unread messages
                              return StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('chats')
                                    .doc(chatId)
                                    .collection('messages')
                                    .where('senderId',
                                        isNotEqualTo: currentUserId)
                                    .where('isRead', isEqualTo: false)
                                    .snapshots(),
                                builder: (context, unreadSnapshot) {
                                  final hasUnread = unreadSnapshot.hasData &&
                                      unreadSnapshot.data!.docs.isNotEmpty;
                                  final unreadCount = unreadSnapshot.hasData
                                      ? unreadSnapshot.data!.docs.length
                                      : 0;

                                  return _buildChatTile(
                                    chatId: chatId,
                                    name: userName,
                                    imageUrl: userImage,
                                    lastMessage: lastMessage,
                                    time: formattedTime,
                                    hasUnread: hasUnread,
                                    unreadCount: unreadCount,
                                    providerId:
                                        isSeeker ? otherUserId : currentUserId,
                                    providerName: isSeeker ? userName : 'You',
                                    providerImage: isSeeker ? userImage : '',
                                    seekerId:
                                        isSeeker ? currentUserId : otherUserId,
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
            'No conversations yet',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start chatting with service providers',
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
    required String providerId,
    required String providerName,
    required String providerImage,
    required String seekerId,
  }) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              providerId: providerId,
              providerName: providerName,
              providerImage: providerImage,
              seekerId: seekerId,
            ),
          ),
        ).then((_) {
          // Refresh the messages list when returning from chat
          setState(() {});
        });
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200],
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? Icon(
                Icons.person,
                size: 28,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              )
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
      subtitle: Text(
        lastMessage.isEmpty ? 'No messages yet' : lastMessage,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? (hasUnread ? Colors.grey[300] : Colors.grey[500])
              : (hasUnread ? Colors.black87 : Colors.grey[600]),
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
              color: hasUnread ? const Color(0xFF2A9D8F) : Colors.grey[500],
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
