import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'config.dart';
import 'bridge_config.dart';

class MiniAppContainer extends StatefulWidget {
  final String url;
  final MiniAppConfig config;
  final NativeBridgeConfig bridgeConfig;
  final Function(bool)? onLoadingStateChanged;
  final Function(Object)? onError;
  final Function(Map<String, dynamic>)? onBridgeMessage;

  const MiniAppContainer({
    super.key,
    required this.url,
    this.config = const MiniAppConfig(),
    this.bridgeConfig = const NativeBridgeConfig(),
    this.onLoadingStateChanged,
    this.onError,
    this.onBridgeMessage,
  });

  @override
  State<MiniAppContainer> createState() => _MiniAppContainerState();
}

class _MiniAppContainerState extends State<MiniAppContainer> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Handle progress
          },
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
            _injectBridge();
          },
          onWebResourceError: (WebResourceError error) {
            widget.onError?.call(error);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Add JavaScript bridge
    _controller.addJavaScriptChannel(
      'MiniAppNativeBridge',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          // Parse the message
          Map<String, dynamic> data = {};
          try {
            data = Map<String, dynamic>.from(
              // Simple parsing for demo
              message.message.split(',').map((e) => e.trim()).toList().asMap().map((key, value) {
                final parts = value.split(':');
                return MapEntry(parts[0].trim(), parts.length > 1 ? parts[1].trim() : value);
              })
            );
          } catch (e) {
            data = {'message': message.message};
          }
          
          widget.onBridgeMessage?.call(data);
        } catch (e) {
          widget.onError?.call(e);
        }
      },
    );
  }

  void _injectBridge() {
    final bridgeScript = '''
      // MiniApp Native Bridge
      window.MiniAppNativeBridge = {
        postMessage: function(data) {
          if (typeof data === 'object') {
            data = JSON.stringify(data);
          }
          MiniAppNativeBridge.postMessage(data);
        },
        
        showToast: function(message) {
          this.postMessage('type:showToast,message:' + message);
        },
        
        vibrate: function() {
          this.postMessage('type:vibrate');
        },
        
        getDeviceInfo: function() {
          this.postMessage('type:getDeviceInfo');
        },
        
        getUserInfo: function() {
          this.postMessage('type:getUserInfo');
        },
        
        share: function(content) {
          this.postMessage('type:share,data:' + JSON.stringify(content));
        },
        
        requestCamera: function() {
          this.postMessage('type:requestCamera');
        },
        
        requestLocation: function() {
          this.postMessage('type:requestLocation');
        },
        
        log: function(message) {
          this.postMessage('type:log,message:' + message);
        },
        
        testNative: function(data) {
          this.postMessage('type:testNative,data:' + JSON.stringify(data));
        },
        
        getHostInfo: function() {
          this.postMessage('type:getHostInfo');
        }
      };
      
      console.log('MiniApp Native Bridge injected successfully');
    ''';
    
    _controller.runJavaScript(bridgeScript);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
