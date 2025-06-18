import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/message_models.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or get existing chat
  Future<Chat> createOrGetChat(String seekerId, String providerId) async {
    final chatId = ChatHelper.createChatId(seekerId, providerId);
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      final newChat = Chat(
        id: chatId,
        seekerId: seekerId,
        providerId: providerId,
        lastMessage: '',
        createdAt: DateTime.now(),
        participants: [seekerId, providerId],
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .set(newChat.toFirestore());
      return newChat;
    }

    return Chat.fromFirestore(chatDoc);
  }

  // Send text message
  Future<void> sendTextMessage(String chatId, String text) async {
    if (currentUserId == null || text.trim().isEmpty) return;

    final message = ChatMessage(
      id: '', // Will be set by Firestore
      senderId: currentUserId!,
      text: text.trim(),
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Update chat's last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Send audio message
  Future<void> sendAudioMessage(String chatId, File audioFile) async {
    if (currentUserId == null) return;

    // Upload audio file
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child('chat_audios')
        .child('${currentUserId}_$timestamp.m4a');

    final uploadTask = ref.putFile(
      audioFile,
      SettableMetadata(contentType: 'audio/m4a'),
    );

    final snapshot = await uploadTask;
    final audioUrl = await snapshot.ref.getDownloadURL();

    final message = ChatMessage(
      id: '',
      senderId: currentUserId!,
      audioUrl: audioUrl,
      type: MessageType.audio,
      timestamp: DateTime.now(),
    );

    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Update chat's last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': 'Voice message',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Send image message
  Future<void> sendImageMessage(String chatId, File imageFile) async {
    if (currentUserId == null) return;

    // Upload image file
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage
        .ref()
        .child('chat_images')
        .child('${currentUserId}_$timestamp.jpg');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    final imageUrl = await snapshot.ref.getDownloadURL();

    final message = ChatMessage(
      id: '',
      senderId: currentUserId!,
      imageUrl: imageUrl,
      type: MessageType.image,
      timestamp: DateTime.now(),
    );

    // Add message to subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Update chat's last message
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': 'Photo',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Get chats for current user
  Stream<List<Chat>> getUserChats() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList());
  }

  // Get messages for a chat
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Get unread message count for a chat
  Stream<int> getUnreadCount(String chatId) {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (currentUserId == null) return;

    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Clear chat messages
  Future<void> clearChat(String chatId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Update chat document
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Get user data
  Future<ChatUser?> getUserData(String userId, UserRole role) async {
    try {
      final collection =
          role == UserRole.seeker ? 'service_seekers' : 'service_providers';

      final doc = await _firestore.collection(collection).doc(userId).get();

      if (doc.exists) {
        return ChatUser.fromMap(doc.data()!, userId, role);
      }

      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Enhanced method to get chat with user data
  Future<Chat?> getChatWithUserData(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return null;

      final chat = Chat.fromFirestore(chatDoc);

      // Get user data
      final seeker = await getUserData(chat.seekerId, UserRole.seeker);
      final provider = await getUserData(chat.providerId, UserRole.provider);

      return chat.copyWith(seeker: seeker, provider: provider);
    } catch (e) {
      print('Error getting chat with user data: $e');
      return null;
    }
  }
}
