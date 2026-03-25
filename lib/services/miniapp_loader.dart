import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'miniapp_server.dart';
import '../models/mini_app.dart';

class MiniAppLoader {
  static const String _miniAppsDir = 'miniapps';
  
  /// Load all available Mini-Apps from the miniapps directory
  static Future<List<MiniApp>> loadAvailableMiniApps() async {
    try {
      final directory = Directory(_miniAppsDir);
      
      if (!await directory.exists()) {
        print('MiniApps directory not found: $_miniAppsDir');
        return [];
      }

      final miniApps = <MiniApp>[];
      
      await for (final entity in directory.list()) {
        if (entity is Directory) {
          final miniApp = await _loadMiniAppFromDirectory(entity);
          if (miniApp != null) {
            miniApps.add(miniApp);
          }
        }
      }

      return miniApps;
    } catch (e) {
      print('Error loading Mini-Apps: $e');
      return [];
    }
  }

  /// Load a specific Mini-App by name
  static Future<MiniApp?> loadMiniApp(String appName) async {
    try {
      final directory = Directory('$_miniAppsDir/$appName');
      
      if (!await directory.exists()) {
        print('Mini-App directory not found: ${directory.path}');
        return null;
      }

      return await _loadMiniAppFromDirectory(directory);
    } catch (e) {
      print('Error loading Mini-App $appName: $e');
      return null;
    }
  }

  /// Load Mini-App from directory containing miniapp.json and entry file
  static Future<MiniApp?> _loadMiniAppFromDirectory(Directory directory) async {
    try {
      // Read miniapp.json manifest
      final manifestFile = File('${directory.path}/miniapp.json');
      if (!await manifestFile.exists()) {
        print('miniapp.json not found in ${directory.path}');
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

      // Construct file URL for the entry point
      final entryFile = File('${directory.path}/$entry');
      if (!await entryFile.exists()) {
        print('Entry file not found: ${entryFile.path}');
        return null;
      }

      // For web platform, use web assets
      String entryUrl;
      if (kIsWeb) {
        // For web, serve from web assets
        entryUrl = 'miniapp-test.html';
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
      print('Error parsing Mini-App manifest in ${directory.path}: $e');
      return null;
    }
  }

  /// Get Mini-App manifest as JSON
  static Future<Map<String, dynamic>?> getMiniAppManifest(String appName) async {
    try {
      final manifestFile = File('$_miniAppsDir/$appName/miniapp.json');
      if (!await manifestFile.exists()) {
        return null;
      }

      final content = await manifestFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      print('Error reading Mini-App manifest for $appName: $e');
      return null;
    }
  }

  /// Validate Mini-App permissions against host platform
  static Future<bool> validatePermissions(List<String> permissions) async {
    final supportedPermissions = [
      'auth.profile',
      'device.camera',
      'device.scanner',
      'device.location',
      'device.clipboard',
      'device.file',
      'storage.read',
      'storage.write',
      'ui.modal',
      'ui.toast',
      'payments.request',
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
        print('Unsupported permission: $permission');
        return false;
      }
    }

    return true;
  }

  /// Check if Mini-App is compatible with current platform
  static Future<bool> isCompatible(MiniApp miniApp) async {
    // Check platform compatibility
    if (Platform.isIOS || Platform.isAndroid) {
      // Mobile platforms
      return true;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop platforms (development)
      return true;
    }

    return false;
  }
}
