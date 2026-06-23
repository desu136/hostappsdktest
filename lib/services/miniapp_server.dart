import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:path/path.dart' as path;

class MiniAppServer {
  static HttpServer? _server;
  static int _port = 8081;

  /// Start the local Mini-App server
  static Future<void> startServer() async {
    if (_server != null) {
      print('Mini-App server already running on port $_port');
      return;
    }

    try {
      _server = await HttpServer.bind('localhost', _port);
      print('🚀 Mini-App server started on http://localhost:$_port');
      // Listen in background — do NOT await this or it blocks forever
      _server!.listen(_handleRequest);
    } catch (e) {
      print('❌ Failed to start Mini-App server: $e');
      // Try alternative port
      _port = 8082;
      try {
        _server = await HttpServer.bind('localhost', _port);
        print('🚀 Mini-App server started on http://localhost:$_port');
        _server!.listen(_handleRequest);
      } catch (e2) {
        print('❌ Failed to start Mini-App server on alternative port: $e2');
      }
    }
  }

  /// Handle incoming HTTP requests
  static void _handleRequest(HttpRequest request) {
    final String requestPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final String filePath = path.join('miniapps', requestPath.substring(1));
    
    // Add CORS headers
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      request.response.close();
      return;
    }

    try {
      final File file = File(filePath);
      
      if (file.existsSync()) {
        // Determine content type
        final String contentType = _getContentType(filePath);
        request.response.headers.set('Content-Type', contentType);
        
        // Serve the file
        final Uint8List content = file.readAsBytesSync();
        request.response.add(content);
        request.response.statusCode = HttpStatus.ok;
        print('✅ Served: $filePath');
      } else {
        // Try to serve index.html for SPA routing
        final File indexFile = File(path.join('miniapps', 'test_app', 'index.html'));
        final File restIndexFile = File(path.join('miniapps', 'restaurant_miniapp', 'index.html'));
        if (indexFile.existsSync() && requestPath.startsWith('/test_app/')) {
          request.response.headers.set('Content-Type', 'text/html');
          final Uint8List content = indexFile.readAsBytesSync();
          request.response.add(content);
          request.response.statusCode = HttpStatus.ok;
          print('✅ Served index.html for: $requestPath');
        } else if (restIndexFile.existsSync() && requestPath.startsWith('/restaurant_miniapp/')) {
          request.response.headers.set('Content-Type', 'text/html');
          final Uint8List content = restIndexFile.readAsBytesSync();
          request.response.add(content);
          request.response.statusCode = HttpStatus.ok;
          print('✅ Served index.html for: $requestPath');
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('File not found: $filePath');
          print('❌ Not found: $filePath');
        }
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Error serving file: $e');
      print('❌ Error serving $filePath: $e');
    }

    request.response.close();
  }

  /// Get content type based on file extension
  static String _getContentType(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    
    switch (extension) {
      case '.html':
        return 'text/html';
      case '.js':
        return 'application/javascript';
      case '.css':
        return 'text/css';
      case '.json':
        return 'application/json';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.ico':
        return 'image/x-icon';
      default:
        return 'text/plain';
    }
  }

  /// Get the server URL for a Mini-App
  static String getMiniAppUrl(String appName) {
    return 'http://localhost:$_port/$appName/';
  }

  /// Stop the server
  static Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      print('🛑 Mini-App server stopped');
    }
  }

  /// Check if server is running
  static bool get isRunning => _server != null;
}
