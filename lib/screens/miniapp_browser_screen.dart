import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/mini_app.dart';
import '../services/miniapp_runtime_loader.dart';
import '../services/miniapp_mobile_loader.dart';
import 'miniapp_container_screen.dart';

class MiniAppBrowserScreen extends StatefulWidget {
  const MiniAppBrowserScreen({super.key});

  @override
  State<MiniAppBrowserScreen> createState() => _MiniAppBrowserScreenState();
}

class _MiniAppBrowserScreenState extends State<MiniAppBrowserScreen> {
  List<MiniApp> _availableMiniApps = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMiniApps();
  }

  Future<void> _loadMiniApps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use appropriate loader based on platform
      if (kIsWeb) {
        // Use runtime engine loader for web
        await MiniAppRuntimeLoader.initialize();
        final miniApps = await MiniAppRuntimeLoader.loadAvailableMiniApps();
        setState(() {
          _availableMiniApps = miniApps;
          _isLoading = false;
        });
      } else {
        // Use mobile loader for Android/iOS
        await MiniAppMobileLoader.initialize();
        final miniApps = await MiniAppMobileLoader.loadAvailableMiniApps();
        setState(() {
          _availableMiniApps = miniApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _launchMiniApp(MiniApp miniApp) async {
    // Use appropriate loader based on platform
    if (kIsWeb) {
      // Web platform - use runtime engine
      final isValid = await MiniAppRuntimeLoader.validatePermissions(miniApp.permissions);
      if (!isValid) {
        _showErrorDialog('Invalid Permissions', 
            'This Mini-App requests unsupported permissions.');
        return;
      }

      final isCompatible = await MiniAppRuntimeLoader.isCompatible(miniApp);
      if (!isCompatible) {
        _showErrorDialog('Incompatible', 
            'This Mini-App is not compatible with your platform.');
        return;
      }

      final launchData = await MiniAppRuntimeLoader.launchMiniApp(miniApp.id);
      if (launchData == null) {
        _showErrorDialog('Launch Failed', 'Failed to launch Mini-App through Runtime Engine.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MiniAppContainerScreen(
            app: miniApp,
            directUrl: miniApp.entryUrl,
          ),
        ),
      );
    } else {
      // Mobile platform - use mobile loader
      final isValid = await MiniAppMobileLoader.validatePermissions(miniApp.permissions);
      if (!isValid) {
        _showErrorDialog('Invalid Permissions', 
            'This Mini-App requests unsupported permissions.');
        return;
      }

      final isCompatible = await MiniAppMobileLoader.isCompatible(miniApp);
      if (!isCompatible) {
        _showErrorDialog('Incompatible', 
            'This Mini-App is not compatible with your platform.');
        return;
      }

      final launchData = await MiniAppMobileLoader.launchMiniApp(miniApp.id);
      if (launchData == null) {
        _showErrorDialog('Launch Failed', 'Failed to launch Mini-App on Mobile.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MiniAppContainerScreen(
            app: miniApp,
            directUrl: miniApp.entryUrl,
          ),
        ),
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-App Browser'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              kIsWeb ? 'Loading Mini-Apps (Web)...' : 'Loading Mini-Apps (Mobile)...',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading Mini-Apps',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMiniApps,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableMiniApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Mini-Apps Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Place your Mini-Apps in the miniapps/ directory',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMiniApps,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableMiniApps.length,
      itemBuilder: (context, index) {
        final miniApp = _availableMiniApps[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.apps,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              miniApp.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Version: ${miniApp.version} | Platform: ${kIsWeb ? 'Web' : 'Mobile'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: const Icon(Icons.launch),
            onTap: () => _launchMiniApp(miniApp),
          ),
        );
      },
    );
  }
}
