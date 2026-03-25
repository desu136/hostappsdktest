import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WebViewBridgeService {
  void handleMessage(String message) {
    try {
      // Try to parse as JSON first
      Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(
          // This would normally use jsonDecode, but for simplicity we'll log the raw message
          <String, dynamic>{},
        );
      } catch (e) {
        // If not JSON, treat as simple string message
        data = {'message': message};
      }

      final String type = data['type'] ?? 'unknown';
      final dynamic messageData = data['data'] ?? {};

      _logMessage('Received message from mini-app: $message');
      _logMessage('Message type: $type');
      _logMessage('Message data: $messageData');

      // Handle different message types
      switch (type) {
        case 'getDeviceInfo':
          _handleGetDeviceInfo();
          break;
        case 'showToast':
          _handleShowToast(messageData['message'] ?? 'Toast message');
          break;
        case 'vibrate':
          _handleVibrate();
          break;
        case 'getUserInfo':
          _handleGetUserInfo();
          break;
        case 'share':
          _handleShare(messageData);
          break;
        case 'requestCamera':
          _handleRequestCamera();
          break;
        case 'requestLocation':
          _handleRequestLocation();
          break;
        case 'openShareDialog':
          _handleOpenShareDialog(messageData);
          break;
        default:
          _logMessage('Unknown message type: $type');
      }
    } catch (e) {
      _logMessage('Error handling message: $e');
    }
  }

  void _handleGetDeviceInfo() {
    // Simulate device info response
    final deviceInfo = {
      'platform': 'Flutter App',
      'version': '1.0.0',
      'deviceId': 'echat_demo_001',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _logMessage('Device info requested: $deviceInfo');
    
    // In a real implementation, you would send this back to the WebView
    // For now, we just log it
  }

  void _handleShowToast(String message) {
    _logMessage('Toast requested: $message');
    
    // In a real implementation, you would show a toast
    // For now, we just log it
    HapticFeedback.lightImpact();
  }

  void _handleVibrate() {
    _logMessage('Vibration requested');
    
    // In a real implementation, you would vibrate the device
    HapticFeedback.mediumImpact();
  }

  void _handleGetUserInfo() {
    // Simulate user info response
    final userInfo = {
      'id': 'user_001',
      'name': 'Demo User',
      'email': 'demo@echat.com',
      'avatar': '👤',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _logMessage('User info requested: $userInfo');
    
    // In a real implementation, you would send this back to the WebView
  }

  void _handleShare(Map<String, dynamic> data) {
    _logMessage('Share requested: $data');
    
    // In a real implementation, you would open the native share dialog
    HapticFeedback.lightImpact();
  }

  void _handleRequestCamera() {
    _logMessage('Camera permission requested');
    
    // In a real implementation, you would request camera permission
    // and open the camera if granted
    HapticFeedback.lightImpact();
  }

  void _handleRequestLocation() {
    _logMessage('Location permission requested');
    
    // In a real implementation, you would request location permission
    // and get the current location if granted
    HapticFeedback.lightImpact();
  }

  void _handleOpenShareDialog(Map<String, dynamic> data) {
    final String title = data['title'] ?? 'Share';
    final String text = data['text'] ?? '';
    final String url = data['url'] ?? '';
    
    _logMessage('Share dialog requested: title=$title, text=$text, url=$url');
    
    // In a real implementation, you would open the native share dialog
    HapticFeedback.lightImpact();
  }

  void _logMessage(String message) {
    // In a real implementation, you might want to:
    // 1. Log to a file
    // 2. Send to analytics
    // 3. Display in debug console
    // 4. Show in a debug overlay
    
    debugPrint('🔗 WebViewBridge: $message');
    
    // For demonstration purposes, we're using debugPrint
    // In production, you might want to use a proper logging solution
  }

  // Method to get JavaScript code for injection
  String getJavaScriptBridgeCode() {
    return '''
      // Mini App Native Bridge
      (function() {
        console.log('Initializing MiniAppNativeBridge...');
        
        // Bridge object
        window.MiniAppNativeBridge = {
          // Send message to native side
          postMessage: function(data) {
            if (typeof data === 'object') {
              data = JSON.stringify(data);
            }
            // This will be handled by the Flutter JavaScript channel
            console.log('Sending to native:', data);
          },
          
          // Convenience methods
          showToast: function(message) {
            this.postMessage({
              type: 'showToast',
              data: { message: message }
            });
          },
          
          vibrate: function() {
            this.postMessage({
              type: 'vibrate',
              data: {}
            });
          },
          
          getDeviceInfo: function() {
            this.postMessage({
              type: 'getDeviceInfo',
              data: {}
            });
          },
          
          getUserInfo: function() {
            this.postMessage({
              type: 'getUserInfo',
              data: {}
            });
          },
          
          share: function(content) {
            this.postMessage({
              type: 'share',
              data: content
            });
          },
          
          requestCamera: function() {
            this.postMessage({
              type: 'requestCamera',
              data: {}
            });
          },
          
          requestLocation: function() {
            this.postMessage({
              type: 'requestLocation',
              data: {}
            });
          },
          
          openShareDialog: function(title, text, url) {
            this.postMessage({
              type: 'openShareDialog',
              data: {
                title: title || '',
                text: text || '',
                url: url || ''
              }
            });
          }
        };
        
        console.log('MiniAppNativeBridge initialized successfully');
      })();
    ''';
  }
}
