import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/auth_user.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';

class AppProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  
  bool _isInitialized = false;
  bool _isLoading = true;

  // Getters
  AuthService get authService => _authService;
  ChatService get chatService => _chatService;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  AuthUser? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  List<ChatUser> get users => _chatService.users;
  List<ChatMessage> get messages => _chatService.messages;
  int get unreadCount => _chatService.getUnreadCount();

  // Initialize the app
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Initialize auth service
      await _authService.initialize();
      
      // Initialize chat service
      await _chatService.initialize();

      _isInitialized = true;
    } catch (e) {
      print('Error initializing app: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signIn(email: email, password: password);
      
      // Update online status
      if (_authService.currentUser != null) {
        await _authService.updateOnlineStatus(true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign up
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? bio,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Starting signup for: $email');
      await _authService.signUp(
        name: name,
        email: email,
        password: password,
        bio: bio,
      );
      
      print('Signup completed successfully');
      
      // Update online status
      if (_authService.currentUser != null) {
        await _authService.updateOnlineStatus(true);
        print('Online status updated');
      }
      
      print('User authenticated: ${_authService.isAuthenticated}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update online status before signing out
      if (_authService.currentUser != null) {
        await _authService.updateOnlineStatus(false);
      }

      await _authService.logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatar,
  }) async {
    try {
      await _authService.updateProfile(
        name: name,
        bio: bio,
        avatar: avatar,
      );
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String userId,
    required String text,
  }) async {
    try {
      await _chatService.sendMessage(userId: userId, text: text);
      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String userId) async {
    try {
      await _chatService.markMessagesAsRead(userId);
      notifyListeners();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Search users
  List<ChatUser> searchUsers(String query) {
    return _chatService.searchUsers(query);
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      notifyListeners();
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  // Update user online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      await _chatService.updateUserOnlineStatus(userId, isOnline);
      notifyListeners();
    } catch (e) {
      print('Error updating user online status: $e');
    }
  }

  // Get messages for a specific user
  List<ChatMessage> getMessagesForUser(String userId) {
    return _chatService.getMessagesForUser(userId);
  }

  // Refresh data
  Future<void> refresh() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _chatService.initialize();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
