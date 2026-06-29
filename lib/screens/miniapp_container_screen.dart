import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'qr_scanner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
            final trimmed = message.message.trim();
            if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
              data = jsonDecode(trimmed) as Map<String, dynamic>;
            } else {
              data = Map<String, dynamic>.from(
                trimmed.split(',').map((e) => e.trim()).toList().asMap().map((key, value) {
                  final parts = value.split(':');
                  return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : value);
                })
              );
            }
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
            final trimmed = message.message.trim();
            if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
              data = jsonDecode(trimmed) as Map<String, dynamic>;
            } else {
              data = Map<String, dynamic>.from(
                trimmed.split(',').map((e) => e.trim()).toList().asMap().map((key, value) {
                  final parts = value.split(':');
                  return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : value);
                })
              );
            }
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
      // Official MiniAppBridge mock for webview_flutter support
      window.flutter_inappwebview = {
        callHandler: function(handlerName, args) {
          return new Promise(function(resolve, reject) {
            var callbackId = Date.now().toString() + '_' + Math.random().toString(36).substr(2, 9);
            window['_resolve_' + callbackId] = function(res) {
              resolve(res);
            };
            
            // Post message to the channel
            MiniAppNativeBridge.postMessage(JSON.stringify({
              handler: handlerName,
              id: args.id || callbackId,
              method: args.method,
              params: args.params || {},
              callbackId: callbackId
            }));
          });
        }
      };
      
      window.MiniAppBridge = {
        version: '1.0.0',
        postMessage: function(data) {
          if (typeof data === 'object') { data = JSON.stringify(data); }
          MiniAppNativeBridge.postMessage(data);
        },
        auth: {
          login: function() {
            return window.flutter_inappwebview.callHandler("MiniAppBridge", { method: "auth.login" })
              .then(function(res) { return res.result; });
          },
          getProfile: function() {
            return window.flutter_inappwebview.callHandler("MiniAppBridge", { method: "auth.getProfile" })
              .then(function(res) { return res.result; });
          }
        },
        storage: {
          setItem: function(key, value) {
            return window.flutter_inappwebview.callHandler("MiniAppBridge", { method: "storage.setItem", params: { key: key, value: value } })
              .then(function(res) { return res.result; });
          },
          getItem: function(key) {
            return window.flutter_inappwebview.callHandler("MiniAppBridge", { method: "storage.getItem", params: { key: key } })
              .then(function(res) { return res.result; });
          }
        },
        device: {
          scanner: {
            scan: function() {
              return window.flutter_inappwebview.callHandler("MiniAppBridge", { method: "device.scanner.scan" })
                .then(function(res) { return res.result; });
            }
          },
          location: {
            getLocation: function() {
              return window.flutter_inappwebview.callHandler("MiniAppBridge", { method: "device.location.getCurrentPosition" })
                .then(function(res) { return res.result; });
            }
          }
        },
        ui: {
          toast: function(msg) {
            return window.flutter_inappwebview.callHandler("MiniAppBridge", { method: "ui.toast", params: { message: msg } });
          }
        }
      };
      window.MiniApp = window.MiniAppBridge;
      console.log('📱 Mobile Bridge v1.0.0 loaded');
    ''';
    _controller.runJavaScript(bridgeScript);
  }

  void _handleBridgeMessage(Map<String, dynamic> data) {
    // If it's a JSON callHandler request from the SDK
    final String? handler = data['handler'] as String?;
    if (handler == 'MiniAppBridge') {
      final callbackId = data['callbackId'] as String?;
      final method = data['method'] as String?;
      final params = data['params'] as Map<String, dynamic>? ?? {};
      _handleSDKRequest(method, params, callbackId);
      return;
    }

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

  void _handleSDKRequest(String? method, Map<String, dynamic> params, String? callbackId) {
    if (callbackId == null) return;
    
    switch (method) {
      case 'core.init':
        _resolveSDK(callbackId, {
          'instanceId': 'instance_${widget.app?.id ?? 'default'}',
          'capabilities': [
            'auth.profile',
            'auth.token',
            'storage.kv',
            'device.location',
            'device.scanner',
            'ui.toast',
            'ui.modal'
          ]
        });
        break;
        
      case 'auth.getProfile':
        _handleSDKGetProfile(callbackId);
        break;
        
      case 'auth.getToken':
        _resolveSDK(callbackId, {
          'accessToken': 'sso_token_${Provider.of<AppProvider>(context, listen: false).currentUser?.id ?? 'guest'}'
        });
        break;
        
      case 'storage.setItem':
        final key = params['key'] as String?;
        final value = params['value'];
        if (key != null) {
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString('miniapp_${widget.app?.id ?? 'default'}_$key', value.toString());
            _resolveSDK(callbackId, true);
          });
        } else {
          _rejectSDK(callbackId, 'Missing key');
        }
        break;
        
      case 'storage.getItem':
        final key = params['key'] as String?;
        if (key != null) {
          SharedPreferences.getInstance().then((prefs) {
            final val = prefs.getString('miniapp_${widget.app?.id ?? 'default'}_$key');
            _resolveSDK(callbackId, val);
          });
        } else {
          _rejectSDK(callbackId, 'Missing key');
        }
        break;
        
      case 'storage.removeItem':
        final key = params['key'] as String?;
        if (key != null) {
          SharedPreferences.getInstance().then((prefs) {
            prefs.remove('miniapp_${widget.app?.id ?? 'default'}_$key');
            _resolveSDK(callbackId, true);
          });
        } else {
          _rejectSDK(callbackId, 'Missing key');
        }
        break;
        
      case 'storage.clear':
        SharedPreferences.getInstance().then((prefs) {
          final prefix = 'miniapp_${widget.app?.id ?? 'default'}_';
          final keysToRemove = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
          for (var k in keysToRemove) {
            prefs.remove(k);
          }
          _resolveSDK(callbackId, true);
        });
        break;
        
      case 'device.location.getCurrentPosition':
        _handleSDKGetLocation(callbackId);
        break;
        
      case 'device.scanner.scan':
        _handleSDKScan(callbackId);
        break;
        
      case 'ui.toast':
        final message = params['message'] as String?;
        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          _resolveSDK(callbackId, true);
        } else {
          _rejectSDK(callbackId, 'Missing message');
        }
        break;
        
      case 'ui.modal':
        final title = params['title'] as String? ?? 'Alert';
        final message = params['message'] as String? ?? '';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resolveSDK(callbackId, {'confirmed': true});
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
        break;
        
      default:
        _rejectSDK(callbackId, 'Method not implemented: $method');
    }
  }

  void _resolveSDK(String callbackId, dynamic result) {
    final jsonResult = jsonEncode({'ok': true, 'result': result});
    _controller.runJavaScript("window['_resolve_$callbackId']($jsonResult);");
  }

  void _rejectSDK(String callbackId, String errorMessage) {
    final jsonResult = jsonEncode({'ok': false, 'error': errorMessage});
    _controller.runJavaScript("window['_resolve_$callbackId']($jsonResult);");
  }

  void _handleSDKGetLocation(String callbackId) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
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
              const Icon(Icons.location_on, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                '${widget.app?.name ?? "This Mini-App"} wants to access your location',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will share your real-time GPS location with the Mini-App to find nearby branches and deliver orders.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _rejectSDK(callbackId, 'User denied location permission');
                      },
                      child: const Text('Deny'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await appProvider.fetchLocation(requestPermission: true);
                        final pos = appProvider.currentPosition;
                        if (pos != null) {
                          _resolveSDK(callbackId, {
                            'coords': {
                              'latitude': pos.latitude,
                              'longitude': pos.longitude,
                              'accuracy': pos.accuracy,
                              'altitude': pos.altitude,
                            },
                            'timestamp': pos.timestamp.millisecondsSinceEpoch
                          });
                        } else {
                          _rejectSDK(callbackId, 'Could not retrieve GPS coordinates.');
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
    );
  }

  void _handleSDKGetProfile(String callbackId) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final currentUser = appProvider.currentUser;

    if (currentUser == null) {
      _rejectSDK(callbackId, 'User is not logged into Host App');
      return;
    }

    final appId = widget.app?.id ?? 'default';
    SharedPreferences.getInstance().then((prefs) {
      final isGranted = prefs.getBool('miniapp_${appId}_profile_granted') ?? false;
      if (isGranted) {
        _resolveSDK(callbackId, {
          'id': currentUser.id,
          'displayName': currentUser.name,
          'email': currentUser.email,
          'avatarUrl': currentUser.avatar,
        });
        return;
      }

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
                const Icon(Icons.account_circle, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  '${widget.app?.name ?? "This Mini-App"} wants to access your profile',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'This will share your name (${currentUser.name}) and email (${currentUser.email}) with the Mini-App.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectSDK(callbackId, 'User denied profile access');
                        },
                        child: const Text('Deny'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          prefs.setBool('miniapp_${appId}_profile_granted', true);
                          _resolveSDK(callbackId, {
                            'id': currentUser.id,
                            'displayName': currentUser.name,
                            'email': currentUser.email,
                            'avatarUrl': currentUser.avatar,
                          });
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
      );
    });
  }

  Future<void> _handleSDKScan(String callbackId) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null) {
      _resolveSDK(callbackId, {'result': result});
    } else {
      _rejectSDK(callbackId, 'Scan cancelled');
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

    final appId = widget.app?.id ?? 'default';
    SharedPreferences.getInstance().then((prefs) {
      final isGranted = prefs.getBool('miniapp_${appId}_login_granted') ?? false;
      if (isGranted) {
        if (callbackId != null) {
          final userJson = jsonEncode({
            'id': currentUser.id,
            'name': currentUser.name,
            'email': currentUser.email,
            'token': 'sso_token_${currentUser.id}'
          });
          _controller.runJavaScript("window['_resolve_auth_$callbackId']($userJson);");
        }
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
                          prefs.setBool('miniapp_${appId}_login_granted', true);
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
