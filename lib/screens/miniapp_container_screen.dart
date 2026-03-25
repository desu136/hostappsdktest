import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io';
import '../models/mini_app.dart';

class MiniAppContainerScreen extends StatefulWidget {
  final MiniApp? app;
  final String? directUrl;
  final Function(bool)? onLoadingStateChanged;
  final Function(Object)? onError;

  const MiniAppContainerScreen({
    super.key,
    this.app,
    this.directUrl,
    this.onLoadingStateChanged,
    this.onError,
  });

  @override
  State<MiniAppContainerScreen> createState() => _MiniAppContainerScreenState();
}

class _MiniAppContainerScreenState extends State<MiniAppContainerScreen> {
  bool _isLoading = true;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Get URL from widget or app
    final url = widget.directUrl ?? widget.app?.entryUrl ?? 'about:blank';
    
    // Create WebView with mobile configuration
    _createWebView(url);
  }

  void _createWebView(String url) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            widget.onLoadingStateChanged?.call(true);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            widget.onLoadingStateChanged?.call(false);
            _injectMobileBridge();
          },
          onWebResourceError: (WebResourceError error) {
            widget.onError?.call(error);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    // Add JavaScript bridge for mobile communication
    _controller.addJavaScriptChannel(
      'MiniAppNativeBridge',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          Map<String, dynamic> data = {};
          try {
            data = Map<String, dynamic>.from(
              message.message.split(',').map((e) => e.trim()).toList().asMap().map((key, value) {
                final parts = value.split(':');
                return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : value);
              })
            );
          } catch (e) {
            data = {'message': message.message};
          }
          
          _handleBridgeMessage(data);
        } catch (e) {
          widget.onError?.call(e);
        }
      },
    );
  }

  void _injectMobileBridge() {
    final bridgeScript = '''
      // Mini-App Mobile Bridge (Android/iOS)
        window.MiniAppMobileBridge = {
          version: '1.0.0',
          platform: '${Platform.operatingSystem}',
          
          // Bridge communication
          postMessage: function(data) {
            if (typeof data === 'object') {
              data = JSON.stringify(data);
            }
            MiniAppNativeBridge.postMessage(data);
          },
          
          // Basic SDK APIs for mobile
          auth: {
            login: function() {
              return Promise.resolve({
                id: 'mobile_user_\${Date.now()}',
                name: 'Mobile User',
                token: 'mobile_token_\${Date.now()}'
              });
            },
            getProfile: function() {
              return Promise.resolve({
                id: 'mobile_user_\${Date.now()}',
                name: 'Mobile User',
                email: 'mobile@example.com'
              });
            }
          },
          
          storage: {
            setItem: function(key, value) {
              localStorage.setItem('mobile_' + key, JSON.stringify(value));
              return Promise.resolve(true);
            },
            getItem: function(key) {
              const value = localStorage.getItem('mobile_' + key);
              return Promise.resolve(value ? JSON.parse(value) : null);
            },
            removeItem: function(key) {
              localStorage.removeItem('mobile_' + key);
              return Promise.resolve(true);
            }
          },
          
          ui: {
            showModal: function(options) {
              alert(options.title + '\\\\n' + options.content);
              return Promise.resolve({action: 'confirmed'});
            },
            toast: function(message) {
              this.postMessage('type:showToast,message:' + message);
              return Promise.resolve();
            }
          },
          
          device: {
            getInfo: function() {
              return Promise.resolve({
                platform: '${Platform.operatingSystem}',
                userAgent: navigator.userAgent,
                runtime: 'MiniAppMobileBridge/1.0.0'
              });
            }
          },
          
          // Lifecycle events
          onLaunch: function(callback) {
            console.log('🚀 Mini-App launched on Mobile');
            if (callback) callback();
          },
          
          onShow: function(callback) {
            console.log('👁️ Mini-App shown on Mobile');
            if (callback) callback();
          },
          
          onHide: function(callback) {
            console.log('🙈 Mini-App hidden on Mobile');
            if (callback) callback();
          },
          
          onClose: function(callback) {
            console.log('👋 Mini-App closed on Mobile');
            if (callback) callback();
          }
        };
        
        console.log('🚀 Mini-App Mobile Bridge loaded (${Platform.operatingSystem})');
        
        // Auto-initialize bridge
        if (window.MiniAppMobileBridge.onLaunch) {
          window.MiniAppMobileBridge.onLaunch();
        }
    ''';
    
    _controller.runJavaScript(bridgeScript);
  }

  void _handleBridgeMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'showToast':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] as String? ?? '')),
        );
        break;
      case 'log':
        print('🔗 Mobile Bridge Log: ${data['message']}');
        break;
      default:
        print('🔗 Mobile Bridge: $type - ${data.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.app?.name ?? 'Mini-App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showMobileInfo,
            tooltip: 'Mobile Bridge Info',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Mini-App...'),
                    Text('Mobile Bridge', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMobileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mobile Bridge Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bridge Version: 1.0.0'),
            Text('Platform: ${Platform.operatingSystem}'),
            Text('Mini-App: ${widget.app?.name ?? "Unknown"}'),
            Text('URL: ${widget.directUrl ?? widget.app?.entryUrl ?? "Unknown"}'),
            const SizedBox(height: 8),
            const Text('Bridge Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('✅ Authentication'),
            const Text('✅ Storage'),
            const Text('✅ UI Components'),
            const Text('✅ Device APIs'),
            const Text('✅ Mobile Optimized'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
