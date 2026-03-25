import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  
  AuthUser? _currentUser;
  String? _authToken;

  AuthUser? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  // Initialize auth service and load stored user
  Future<void> initialize() async {
    await _loadStoredUser();
  }

  // Load user from local storage
  Future<void> _loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      final token = prefs.getString(_tokenKey);

      if (userJson != null && token != null) {
        _currentUser = AuthUser.fromJson(jsonDecode(userJson));
        _authToken = token;
      }
    } catch (e) {
      print('Error loading stored user: $e');
      await logout();
    }
  }

  // Sign up new user
  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
    String? bio,
  }) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate user ID and token
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final token = 'token_${DateTime.now().millisecondsSinceEpoch}_$userId';

      // Create user
      final user = AuthUser(
        id: userId,
        name: name,
        email: email,
        avatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random',
        bio: bio,
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
      );

      // Store user and token
      await _storeUser(user, token);

      return user;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in existing user
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes, create a user if not exists
      // In real app, this would validate against backend
      final userId = 'user_${email.split('@')[0]}_${DateTime.now().millisecondsSinceEpoch}';
      final token = 'token_${DateTime.now().millisecondsSinceEpoch}_$userId';

      final user = AuthUser(
        id: userId,
        name: email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z]'), ''),
        email: email,
        avatar: 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(email.split('@')[0])}&background=random',
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        isOnline: true,
      );

      await _storeUser(user, token);

      return user;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign out user
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
      
      _currentUser = null;
      _authToken = null;
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? avatar,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        bio: bio,
        avatar: avatar,
      );

      await _storeUser(updatedUser, _authToken!);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        isOnline: isOnline,
        lastSeen: DateTime.now(),
      );

      await _storeUser(updatedUser, _authToken!);
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  // Store user data locally
  Future<void> _storeUser(AuthUser user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, token);
      
      _currentUser = user;
      _authToken = token;
    } catch (e) {
      throw Exception('Failed to store user: $e');
    }
  }

  // Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password strength
  bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
