import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';
import '../models/auth_user.dart';

class ChatService {
  static const String _chatsKey = 'chats';
  static const String _messagesKey = 'messages';
  static const String _usersKey = 'users';
  
  List<ChatUser> _users = [];
  List<ChatMessage> _messages = [];
  
  List<ChatUser> get users => _users;
  List<ChatMessage> get messages => _messages;

  // Initialize chat service
  Future<void> initialize() async {
    await _loadData();
    await _generateSampleUsers();
  }

  // Load stored data
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load users
      final usersJson = prefs.getStringList(_usersKey) ?? [];
      _users = usersJson.map((json) => ChatUser.fromJson(jsonDecode(json))).toList();
      
      // Load messages
      final messagesJson = prefs.getStringList(_messagesKey) ?? [];
      _messages = messagesJson.map((json) => ChatMessage.fromJson(jsonDecode(json))).toList();
      
      // Sort messages by timestamp
      _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error loading chat data: $e');
      _users = [];
      _messages = [];
    }
  }

  // Save data to local storage
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save users
      final usersJson = _users.map((user) => jsonEncode(user.toJson())).toList();
      await prefs.setStringList(_usersKey, usersJson);
      
      // Save messages
      final messagesJson = _messages.map((message) => jsonEncode(message.toJson())).toList();
      await prefs.setStringList(_messagesKey, messagesJson);
    } catch (e) {
      print('Error saving chat data: $e');
    }
  }

  // Generate sample users for demo
  Future<void> _generateSampleUsers() async {
    if (_users.isEmpty) {
      final sampleUsers = [
        ChatUser(
          id: 'user1',
          name: 'Alice Johnson',
          avatar: 'https://ui-avatars.com/api/?name=Alice+Johnson&background=FF6B6B',
          lastMessage: 'Hey! How are you?',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
          isOnline: true,
          unreadCount: 2,
        ),
        ChatUser(
          id: 'user2',
          name: 'Bob Smith',
          avatar: 'https://ui-avatars.com/api/?name=Bob+Smith&background=4ECDC4',
          lastMessage: 'See you tomorrow!',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
          isOnline: false,
          unreadCount: 0,
        ),
        ChatUser(
          id: 'user3',
          name: 'Carol Davis',
          avatar: 'https://ui-avatars.com/api/?name=Carol+Davis&background=45B7D1',
          lastMessage: 'Thanks for the help!',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
          isOnline: true,
          unreadCount: 1,
        ),
        ChatUser(
          id: 'user4',
          name: 'David Wilson',
          avatar: 'https://ui-avatars.com/api/?name=David+Wilson&background=96CEB4',
          lastMessage: 'Great idea!',
          lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
          isOnline: false,
          unreadCount: 0,
        ),
        ChatUser(
          id: 'user5',
          name: 'Emma Brown',
          avatar: 'https://ui-avatars.com/api/?name=Emma+Brown&background=FFEAA7',
          lastMessage: 'Let me check and get back to you',
          lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
          isOnline: true,
          unreadCount: 3,
        ),
      ];
      
      _users = sampleUsers;
      await _saveData();
      
      // Generate sample messages for each user
      await _generateSampleMessages();
    }
  }

  // Generate sample messages
  Future<void> _generateSampleMessages() async {
    if (_messages.isEmpty) {
      final sampleMessages = <ChatMessage>[];
      final random = Random();
      
      for (final user in _users) {
        // Add 3-5 messages per user
        final messageCount = 3 + random.nextInt(3);
        
        for (int i = 0; i < messageCount; i++) {
          final isSentByMe = random.nextBool();
          final timestamp = DateTime.now().subtract(
            Duration(hours: random.nextInt(24) + i),
          );
          
          sampleMessages.add(ChatMessage(
            id: 'msg_${user.id}_$i',
            text: _getRandomMessage(isSentByMe),
            timestamp: timestamp,
            isSentByMe: isSentByMe,
            senderId: isSentByMe ? 'current_user' : user.id,
          ));
        }
      }
      
      _messages = sampleMessages;
      await _saveData();
    }
  }

  // Get random message
  String _getRandomMessage(bool isSentByMe) {
    final sentMessages = [
      'Hey! How are you doing?',
      'What are you up to today?',
      'Did you see the latest update?',
      'Let\'s catch up soon!',
      'Thanks for your help!',
      'That sounds great!',
      'I\'ll be there in 10 minutes',
      'Can you send me the files?',
      'Sure, no problem!',
      'Talk to you later!',
    ];
    
    final receivedMessages = [
      'Hi! I\'m good, thanks for asking!',
      'Just working on some projects',
      'Yes, it looks amazing!',
      'Definitely! How about this weekend?',
      'You\'re welcome!',
      'I agree completely',
      'Perfect, see you soon!',
      'I\'ll send them right away',
      'Thanks for understanding',
      'Looking forward to it!',
    ];
    
    final messages = isSentByMe ? sentMessages : receivedMessages;
    return messages[Random().nextInt(messages.length)];
  }

  // Get messages for a specific user
  List<ChatMessage> getMessagesForUser(String userId) {
    return _messages
        .where((message) => 
            message.senderId == userId || 
            (message.senderId == 'current_user' && message.text.contains(userId)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // Send a message
  Future<void> sendMessage({
    required String userId,
    required String text,
  }) async {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      timestamp: DateTime.now(),
      isSentByMe: true,
      senderId: 'current_user',
    );

    _messages.add(message);
    
    // Update user's last message
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      _users[userIndex] = _users[userIndex].copyWith(
        lastMessage: text,
        lastMessageTime: DateTime.now(),
        unreadCount: 0, // Reset unread count for sent messages
      );
    }

    await _saveData();

    // Simulate receiving a response after a delay
    _simulateResponse(userId);
  }

  // Simulate receiving a response
  void _simulateResponse(String userId) {
    Future.delayed(const Duration(seconds: 2), () async {
      final responses = [
        'That\'s interesting! Tell me more.',
        'I see what you mean.',
        'Absolutely! I agree with you.',
        'Let me think about that...',
        'Great point! Thanks for sharing.',
        'How does that work exactly?',
        'That makes sense.',
        'I\'ll look into it and get back to you.',
      ];

      final response = ChatMessage(
        id: 'msg_response_${DateTime.now().millisecondsSinceEpoch}',
        text: responses[Random().nextInt(responses.length)],
        timestamp: DateTime.now(),
        isSentByMe: false,
        senderId: userId,
      );

      _messages.add(response);

      // Update user's last message and unread count
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          lastMessage: response.text,
          lastMessageTime: DateTime.now(),
          unreadCount: (_users[userIndex].unreadCount ?? 0) + 1,
        );
      }

      await _saveData();
    });
  }

  // Search users
  List<ChatUser> searchUsers(String query) {
    if (query.isEmpty) return _users;
    
    return _users.where((user) =>
        user.name.toLowerCase().contains(query.toLowerCase()) ||
        user.lastMessage.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String userId) async {
    // Update unread count for the user
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      _users[userIndex] = _users[userIndex].copyWith(unreadCount: 0);
      await _saveData();
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    _messages.removeWhere((message) => message.id == messageId);
    await _saveData();
  }

  // Get unread count
  int getUnreadCount() {
    return _users.fold(0, (sum, user) => sum + (user.unreadCount ?? 0));
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      _users[userIndex] = _users[userIndex].copyWith(isOnline: isOnline);
      await _saveData();
    }
  }
}
