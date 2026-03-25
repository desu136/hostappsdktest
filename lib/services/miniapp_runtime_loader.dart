import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/mini_app.dart';

// Define config classes locally since runtime engine is not available
class MiniAppConfig {
  final bool enableJavaScript;
  final bool enableDomStorage;
  final bool allowFileAccess;
  final bool allowInlineMediaPlayback;
  final String userAgent;
  final bool allowMixedContent;
  final bool enableZoom;
  final bool debugMode;

  const MiniAppConfig({
    this.enableJavaScript = true,
    this.enableDomStorage = true,
    this.allowFileAccess = false,
    this.allowInlineMediaPlayback = true,
    this.userAgent = 'MiniApp-Container/1.0',
    this.allowMixedContent = false,
    this.enableZoom = false,
    this.debugMode = false,
  });
}

class NativeBridgeConfig {
  final bool enableDeviceInfo;
  final bool enableUserInfo;
  final bool enableCamera;
  final bool enableLocation;
  final bool enableStorage;
  final bool enablePayments;
  final bool enableMessaging;

  const NativeBridgeConfig({
    this.enableDeviceInfo = true,
    this.enableUserInfo = true,
    this.enableCamera = false,
    this.enableLocation = false,
    this.enableStorage = true,
    this.enablePayments = false,
    this.enableMessaging = true,
  });
}

/// Mini-App Runtime Engine Loader
/// Integrates with the Mini-App Runtime Engine for loading and managing Mini-Apps
class MiniAppRuntimeLoader {
  static const String _miniAppsDir = 'miniapps';
  static Map<String, MiniApp> _loadedApps = {};
  static Map<String, MiniAppConfig> _appConfigs = {};
  static Map<String, NativeBridgeConfig> _bridgeConfigs = {};

  /// Initialize the runtime engine
  static Future<void> initialize() async {
    if (kIsWeb) {
      print('🌐 Mini-App Runtime Engine initialized for Web');
    } else {
      print('🖥️ Mini-App Runtime Engine initialized for Desktop/Mobile');
    }
    
    // Load all available Mini-Apps
    await loadAvailableMiniApps();
  }

  /// Load all available Mini-Apps from the miniapps directory
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
            _createRuntimeConfig(miniApp);
          }
        }
      }

      print('✅ Loaded ${miniApps.length} Mini-Apps through Runtime Engine');
      return miniApps;
    } catch (e) {
      print('❌ Error loading Mini-Apps through Runtime Engine: $e');
      return [];
    }
  }

  /// Load a specific Mini-App by name using runtime engine
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
        _createRuntimeConfig(miniApp);
      }

      return miniApp;
    } catch (e) {
      print('❌ Error loading Mini-App $appName through Runtime Engine: $e');
      return null;
    }
  }

  /// Load Mini-App from directory using runtime engine
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
        // For web, use runtime engine URL
        entryUrl = _getRuntimeEngineUrl(directory.path.split('/').last, entry);
      } else {
        // For desktop/mobile, use file:// protocol
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

  /// Create runtime engine configuration for Mini-App
  static void _createRuntimeConfig(MiniApp miniApp) {
    // Create MiniAppConfig based on permissions
    final config = MiniAppConfig(
      enableJavaScript: true,
      enableDomStorage: miniApp.permissions.contains('storage.read') || 
                        miniApp.permissions.contains('storage.write'),
      allowFileAccess: miniApp.permissions.contains('device.file'),
      enableZoom: false,
      debugMode: kDebugMode,
      userAgent: 'MiniApp-Runtime/1.0 (${miniApp.name})',
    );

    // Create NativeBridgeConfig based on permissions
    final bridgeConfig = NativeBridgeConfig(
      enableDeviceInfo: miniApp.permissions.contains('device.info'),
      enableUserInfo: miniApp.permissions.contains('auth.profile'),
      enableCamera: miniApp.permissions.contains('device.camera'),
      enableLocation: miniApp.permissions.contains('device.location'),
      enableStorage: miniApp.permissions.contains('storage.read') || 
                   miniApp.permissions.contains('storage.write'),
      enablePayments: miniApp.permissions.contains('payments.request'),
      enableMessaging: miniApp.permissions.contains('messaging.send'),
    );

    _appConfigs[miniApp.id] = config;
    _bridgeConfigs[miniApp.id] = bridgeConfig;

    print('🔧 Created runtime config for ${miniApp.name}');
  }

  /// Get runtime engine URL for Mini-App
  static String _getRuntimeEngineUrl(String appName, String entry) {
    // For web, use the runtime engine to serve files
    if (kIsWeb) {
      // For now, use direct web asset path
      // In production, this would be served by the runtime engine
      return 'miniapp-test.html';
    } else {
      // For desktop/mobile, the runtime engine handles file serving
      return 'file://${Directory('$_miniAppsDir/$appName/$entry').path}';
    }
  }

  /// Get Mini-App runtime configuration
  static MiniAppConfig? getAppConfig(String appId) {
    return _appConfigs[appId];
  }

  /// Get Mini-App bridge configuration
  static NativeBridgeConfig? getBridgeConfig(String appId) {
    return _bridgeConfigs[appId];
  }

  /// Validate Mini-App permissions for runtime engine
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

  /// Check if Mini-App is compatible with runtime engine
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

  /// Launch Mini-App using runtime engine
  static Future<Map<String, dynamic>?> launchMiniApp(String appId) async {
    try {
      final miniApp = _loadedApps[appId];
      if (miniApp == null) {
        print('❌ Mini-App not found: $appId');
        return null;
      }

      // Validate compatibility
      final compatible = await MiniAppRuntimeLoader.isCompatible(miniApp);
      if (!compatible) {
        print('❌ Mini-App not compatible with current platform');
        return null;
      }

      // Get runtime configurations
      final config = getAppConfig(appId) ?? const MiniAppConfig();
      final bridgeConfig = getBridgeConfig(appId) ?? const NativeBridgeConfig();

      print('🚀 Launching Mini-App ${miniApp.name} through Runtime Engine...');
      
      return {
        'miniApp': miniApp,
        'config': config,
        'bridgeConfig': bridgeConfig,
        'launched': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
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

  /// Get runtime engine status
  static Map<String, dynamic> getRuntimeStatus() {
    return {
      'initialized': true,
      'loadedApps': _loadedApps.length,
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
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
    _appConfigs.clear();
    _bridgeConfigs.clear();
    print('🧹 Runtime Engine cleaned up');
  }
}
