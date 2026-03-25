import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/mini_app.dart';

/// Mobile-compatible Mini-App Loader
/// Optimized for Android and iOS without runtime engine dependency
class MiniAppMobileLoader {
  static const String _miniAppsDir = 'miniapps';
  static Map<String, MiniApp> _loadedApps = {};

  /// Initialize mobile Mini-App loader
  static Future<void> initialize() async {
    if (kIsWeb) {
      print('🌐 Mini-App Mobile Loader initialized for Web');
    } else if (Platform.isAndroid) {
      print('📱 Mini-App Mobile Loader initialized for Android');
    } else if (Platform.isIOS) {
      print('📱 Mini-App Mobile Loader initialized for iOS');
    } else {
      print('🖥️ Mini-App Mobile Loader initialized for Desktop');
    }
    
    // Load all available Mini-Apps
    await loadAvailableMiniApps();
  }

  /// Load all available Mini-Apps from miniapps directory
  static Future<List<MiniApp>> loadAvailableMiniApps() async {
    try {
      final directory = Directory(_miniAppsDir);
      
      if (!await directory.exists()) {
        print('⚠️ MiniApps directory not found: $_miniAppsDir');
        return [];
      }

      final miniApps = <MiniApp>[];
      
      await for (final entity in directory.list()) {
        if (entity is Directory) {
          final miniApp = await _loadMiniAppFromDirectory(entity);
          if (miniApp != null) {
            miniApps.add(miniApp);
            _loadedApps[miniApp.id] = miniApp;
          }
        }
      }

      print('✅ Loaded ${miniApps.length} Mini-Apps for Mobile');
      return miniApps;
    } catch (e) {
      print('❌ Error loading Mini-Apps for Mobile: $e');
      return [];
    }
  }

  /// Load a specific Mini-App by name
  static Future<MiniApp?> loadMiniApp(String appName) async {
    try {
      // Check if already loaded
      if (_loadedApps.containsKey(appName)) {
        return _loadedApps[appName];
      }

      final directory = Directory('$_miniAppsDir/$appName');
      
      if (!await directory.exists()) {
        print('❌ Mini-App directory not found: ${directory.path}');
        return null;
      }

      final miniApp = await _loadMiniAppFromDirectory(directory);
      if (miniApp != null) {
        _loadedApps[appName] = miniApp;
      }

      return miniApp;
    } catch (e) {
      print('❌ Error loading Mini-App $appName: $e');
      return null;
    }
  }

  /// Load Mini-App from directory
  static Future<MiniApp?> _loadMiniAppFromDirectory(Directory directory) async {
    try {
      // Read miniapp.json manifest
      final manifestFile = File('${directory.path}/miniapp.json');
      if (!await manifestFile.exists()) {
        print('⚠️ miniapp.json not found in ${directory.path}');
        return null;
      }

      final manifestContent = await manifestFile.readAsString();
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;

      // Extract manifest information
      final name = manifest['name'] as String? ?? 'Unknown App';
      final version = manifest['version'] as String? ?? '1.0.0';
      final entry = manifest['entry'] as String? ?? 'index.html';
      final permissions = (manifest['permissions'] as List<dynamic>?)?.cast<String>() ?? [];
      final author = manifest['author'] as String?;

      // Construct entry URL based on platform
      final entryFile = File('${directory.path}/$entry');
      if (!await entryFile.exists()) {
        print('❌ Entry file not found: ${entryFile.path}');
        return null;
      }

      String entryUrl;
      if (kIsWeb) {
        // For web, use direct web asset path
        entryUrl = 'miniapp-test.html';
      } else if (Platform.isAndroid) {
        // For Android, use file:// protocol with proper path
        entryUrl = 'file://${entryFile.path.replaceAll('\\', '/')}';
      } else if (Platform.isIOS) {
        // For iOS, use file:// protocol
        entryUrl = 'file://${entryFile.path}';
      } else {
        // For desktop, use file:// protocol
        if (Platform.isWindows) {
          entryUrl = 'file://${entryFile.path.replaceAll('\\', '/')}';
        } else {
          entryUrl = 'file://${entryFile.path}';
        }
      }

      return MiniApp(
        id: directory.path.split('/').last,
        name: name,
        version: version,
        entryUrl: entryUrl,
        permissions: permissions,
        author: author,
        manifestPath: manifestFile.path,
        localPath: directory.path,
      );

    } catch (e) {
      print('❌ Error parsing Mini-App manifest in ${directory.path}: $e');
      return null;
    }
  }

  /// Validate Mini-App permissions for mobile
  static Future<bool> validatePermissions(List<String> permissions) async {
    final supportedPermissions = [
      'auth.profile',
      'device.camera',
      'device.scanner',
      'device.location',
      'device.clipboard',
      'device.file',
      'device.info',
      'storage.read',
      'storage.write',
      'ui.modal',
      'ui.toast',
      'payments.request',
      'messaging.send',
      'storage',
      'messaging',
      'camera',
      'location',
      'payments',
      'device_info',
      'notifications',
    ];

    for (final permission in permissions) {
      if (!supportedPermissions.contains(permission)) {
        print('❌ Unsupported permission: $permission');
        return false;
      }
    }

    return true;
  }

  /// Check if Mini-App is compatible with mobile platform
  static Future<bool> isCompatible(MiniApp miniApp) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platforms - full support
      return true;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms - full support
      return true;
    } else if (kIsWeb) {
      // Web platform - limited support
      return true;
    }

    return false;
  }

  /// Launch Mini-App for mobile
  static Future<Map<String, dynamic>?> launchMiniApp(String appId) async {
    try {
      final miniApp = _loadedApps[appId];
      if (miniApp == null) {
        print('❌ Mini-App not found: $appId');
        return null;
      }

      // Validate compatibility
      final isCompatible = await MiniAppMobileLoader.isCompatible(miniApp);
      if (!isCompatible) {
        print('❌ Mini-App not compatible with current platform');
        return null;
      }

      print('🚀 Launching Mini-App ${miniApp.name} on Mobile...');
      
      return {
        'miniApp': miniApp,
        'platform': Platform.operatingSystem,
        'launched': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'mobileOptimized': true,
      };
    } catch (e) {
      print('❌ Error launching Mini-App $appId: $e');
      return null;
    }
  }

  /// Get all loaded Mini-Apps
  static Map<String, MiniApp> getLoadedApps() {
    return Map.from(_loadedApps);
  }

  /// Get mobile loader status
  static Map<String, dynamic> getMobileStatus() {
    return {
      'initialized': true,
      'loadedApps': _loadedApps.length,
      'platform': Platform.operatingSystem,
      'isMobile': Platform.isAndroid || Platform.isIOS,
      'supportedPermissions': [
        'auth.profile',
        'device.camera',
        'device.scanner',
        'device.location',
        'device.clipboard',
        'device.file',
        'device.info',
        'storage.read',
        'storage.write',
        'ui.modal',
        'ui.toast',
        'payments.request',
        'messaging.send',
      ],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Cleanup resources
  static Future<void> cleanup() async {
    _loadedApps.clear();
    print('🧹 Mobile Loader cleaned up');
  }
}
