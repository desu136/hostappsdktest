import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'qr_scanner_screen.dart';
import '../models/mini_app.dart';
import '../models/miniapp_config.dart';

class MiniAppContainerScreen extends StatefulWidget {
  final MiniApp? app;
  final String? directUrl;
  final MiniAppConfig? runtimeConfig;
  final NativeBridgeConfig? bridgeConfig;
  final Function(bool)? onLoadingStateChanged;
  final Function(Object)? onError;

  const MiniAppContainerScreen({
    super.key,
    this.app,
    this.directUrl,
    this.runtimeConfig,
    this.bridgeConfig,
    this.onLoadingStateChanged,
    this.onError,
  });

  @override
  State<MiniAppContainerScreen> createState() => _MiniAppContainerScreenState();
}

class _MiniAppContainerScreenState extends State<MiniAppContainerScreen> {
  bool _isLoading = true;
  bool _isAuthSheetShowing = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Get URL from widget or app
    final url = widget.directUrl ?? widget.app?.entryUrl ?? 'about:blank';
    
    // Use runtime engine if available, otherwise fallback to mobile bridge
    if (widget.runtimeConfig != null && widget.bridgeConfig != null) {
      _createRuntimeEngineWebView(url, widget.runtimeConfig!, widget.bridgeConfig!);
    } else {
      _createMobileWebView(url);
    }
  }

  void _createMobileWebView(String url) {
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
      );

    if (url.startsWith('assets/')) {
      _controller.loadFlutterAsset(url.substring(7));
    } else if (url.startsWith('miniapps/')) {
      _controller.loadFlutterAsset(url);
    } else {
      _controller.loadRequest(Uri.parse(url));
    }

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

  void _createRuntimeEngineWebView(String url, MiniAppConfig config, NativeBridgeConfig bridgeConfig) {
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
            _injectRuntimeEngineBridge();
          },
          onWebResourceError: (WebResourceError error) {
            widget.onError?.call(error);
          },
        ),
      );

    if (url.startsWith('assets/')) {
      _controller.loadFlutterAsset(url.substring(7));
    } else if (url.startsWith('miniapps/')) {
      _controller.loadFlutterAsset(url);
    } else {
      _controller.loadRequest(Uri.parse(url));
    }

    // Add JavaScript bridge for runtime engine communication
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

  void _injectRuntimeEngineBridge() {
    final bridgeScript = '''
      // Mini-App Runtime Engine Bridge (Official v1.0.0)
      window.MiniAppRuntimeEngine = {
        version: '1.0.0',
        platform: '${Platform.operatingSystem}',
        
        // Bridge communication
        postMessage: function(data) {
          if (typeof data === 'object') {
            data = JSON.stringify(data);
          }
          MiniAppNativeBridge.postMessage(data);
        },
        
        // SDK API simulation
        auth: {
          login: function() {
            return new Promise(function(resolve, reject) {
              var callbackId = Date.now().toString();
              window['_resolve_auth_' + callbackId] = resolve;
              window['_reject_auth_' + callbackId] = reject;
              window.MiniAppRuntimeEngine.postMessage('type:auth_login,callbackId:' + callbackId);
            });
          },
          getProfile: function() {
            return new Promise(function(resolve, reject) {
              var callbackId = Date.now().toString();
              window['_resolve_auth_profile_' + callbackId] = resolve;
              window['_reject_auth_profile_' + callbackId] = reject;
              window.MiniAppRuntimeEngine.postMessage('type:auth_profile,callbackId:' + callbackId);
            });
          }
        },
        
        storage: {
          setItem: function(key, value) {
            localStorage.setItem('runtime_' + key, JSON.stringify(value));
            return Promise.resolve(true);
          },
          getItem: function(key) {
            const value = localStorage.getItem('runtime_' + key);
            return Promise.resolve(value ? JSON.parse(value) : null);
          },
          removeItem: function(key) {
            localStorage.removeItem('runtime_' + key);
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
              runtime: 'MiniAppRuntimeEngine/1.0.0'
            });
          },
          scanner: {
            scan: function() {
              return new Promise(function(resolve, reject) {
                var callbackId = Date.now().toString();
                window['_resolve_scan_' + callbackId] = resolve;
                window['_reject_scan_' + callbackId] = reject;
                window.MiniAppRuntimeEngine.postMessage('type:scanner_scan,callbackId:' + callbackId);
              });
            }
          }
        },
        
        // Lifecycle events
        onLaunch: function(callback) {
          console.log('🚀 Mini-App launched via Official Runtime Engine');
          if (callback) callback();
        },
        
        onShow: function(callback) {
          console.log('👁️ Mini-App shown via Official Runtime Engine');
          if (callback) callback();
        },
        
        onHide: function(callback) {
          console.log('🙈 Mini-App hidden via Official Runtime Engine');
          if (callback) callback();
        },
        
        onClose: function(callback) {
          console.log('👋 Mini-App closed via Official Runtime Engine');
          if (callback) callback();
        }
      };
      
      window.MiniApp = window.MiniAppRuntimeEngine;
      console.log('🚀 Official Mini-App Runtime Engine Bridge v1.0.0 loaded');
    ''';
    
    _controller.runJavaScript(bridgeScript);
  }

  void _injectMobileBridge() {
    const bridgeScript = '''
      window.MiniAppBridge = {
        version: '1.0.0',
        postMessage: function(data) {
          if (typeof data === 'object') { data = JSON.stringify(data); }
          MiniAppNativeBridge.postMessage(data);
        },
        auth: {
          login: function() {
            return new Promise(function(resolve, reject) {
              var callbackId = Date.now().toString();
              window['_resolve_auth_' + callbackId] = resolve;
              window['_reject_auth_' + callbackId] = reject;
              window.MiniAppBridge.postMessage('type:auth_login,callbackId:' + callbackId);
            });
          },
          getProfile: function() {
            return new Promise(function(resolve, reject) {
              var callbackId = Date.now().toString();
              window['_resolve_auth_profile_' + callbackId] = resolve;
              window['_reject_auth_profile_' + callbackId] = reject;
              window.MiniAppBridge.postMessage('type:auth_profile,callbackId:' + callbackId);
            });
          }
        },
        storage: {
          setItem: function(key, value) {
            localStorage.setItem('bridge_' + key, JSON.stringify(value));
            return Promise.resolve(true);
          },
          getItem: function(key) {
            const v = localStorage.getItem('bridge_' + key);
            return Promise.resolve(v ? JSON.parse(v) : null);
          }
        },
        device: {
          scanner: {
            scan: function() {
              return new Promise(function(resolve, reject) {
                var callbackId = Date.now().toString();
                window['_resolve_scan_' + callbackId] = resolve;
                window['_reject_scan_' + callbackId] = reject;
                window.MiniAppBridge.postMessage('type:scanner_scan,callbackId:' + callbackId);
              });
            }
          }
        },
        ui: {
          toast: function(msg) {
            MiniAppNativeBridge.postMessage(JSON.stringify({type:'showToast',message:msg}));
            return Promise.resolve();
          }
        }
      };
      window.MiniApp = window.MiniAppBridge;
      console.log('📱 Mobile Bridge v1.0.0 loaded');
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
      case 'auth_login':
        final callbackId = data['callbackId'] as String?;
        _handleAuthLogin(callbackId);
        break;
      case 'auth_profile':
        final callbackId = data['callbackId'] as String?;
        _handleAuthProfile(callbackId);
        break;
      case 'scanner_scan':
        final callbackId = data['callbackId'] as String?;
        _launchScanner(callbackId);
        break;
      case 'log':
        print('🔗 Mobile Bridge Log: ${data['message']}');
        break;
      default:
        print('🔗 Mobile Bridge: $type - ${data.toString()}');
    }
  }

  void _handleAuthLogin(String? callbackId) {
    if (_isAuthSheetShowing) {
      if (callbackId != null) {
        _controller.runJavaScript("window['_reject_auth_$callbackId'](new Error('Auth request already in progress'));");
      }
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;

    if (currentUser == null) {
      if (callbackId != null) {
        _controller.runJavaScript("window['_reject_auth_$callbackId'](new Error('User is not logged into Host App'));");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to eChat first to use SSO.')),
      );
      return;
    }

    _isAuthSheetShowing = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                '${widget.app?.name ?? "This Mini-App"} wants to access your account',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'This will share your Host App profile (${currentUser.name}) with the Mini-App. You will not need to enter a password.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (callbackId != null) {
                          _controller.runJavaScript("window['_reject_auth_$callbackId'](new Error('User denied login permission'));");
                        }
                      },
                      child: const Text('Deny'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (callbackId != null) {
                          final userJson = jsonEncode({
                            'id': currentUser.id,
                            'name': currentUser.name,
                            'email': currentUser.email,
                            'token': 'sso_token_${currentUser.id}'
                          });
                          _controller.runJavaScript("window['_resolve_auth_$callbackId']($userJson);");
                        }
                      },
                      child: const Text('Allow'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _isAuthSheetShowing = false;
    });
  }

  void _handleAuthProfile(String? callbackId) {
    if (callbackId != null) {
      final currentUser = Provider.of<AppProvider>(context, listen: false).currentUser;
      if (currentUser != null) {
        final userJson = jsonEncode({
          'id': currentUser.id,
          'name': currentUser.name,
          'email': currentUser.email
        });
        _controller.runJavaScript("window['_resolve_auth_profile_$callbackId']($userJson);");
      } else {
        _controller.runJavaScript("window['_reject_auth_profile_$callbackId'](new Error('Not logged in'));");
      }
    }
  }

  Future<void> _launchScanner(String? callbackId) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null) {
      if (callbackId != null) {
        _controller.runJavaScript("window['_resolve_scan_$callbackId']({ result: '$result' });");
      }
      
      // Load the scanned URL as a new Mini-App
      if (result.startsWith('http://') || result.startsWith('https://')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MiniAppContainerScreen(
              app: MiniApp(
                id: 'scanned_app',
                name: 'Scanned App',
                version: '1.0.0',
                entryUrl: result,
                manifestPath: '',
                localPath: '',
              ),
              directUrl: result,
            ),
          ),
        );
      }
    } else {
      if (callbackId != null) {
        _controller.runJavaScript("window['_reject_scan_$callbackId'](new Error('Scan cancelled'));");
      }
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
