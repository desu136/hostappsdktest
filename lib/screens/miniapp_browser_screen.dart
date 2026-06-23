import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/mini_app.dart';
import '../services/miniapp_runtime_loader.dart';
import '../services/miniapp_mobile_loader.dart';
import 'miniapp_container_screen.dart';
import 'package:miniapp_runtime_engine/miniapp_runtime_engine.dart';
import 'qr_scanner_screen.dart';

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
        
        miniApps.insert(0, MiniApp(
          id: 'hotel_menu',
          name: 'Hotel Menu System',
          version: '1.0.0',
          entryUrl: 'https://hotels-and-restaurants-menu-system.vercel.app',
          permissions: const [],
          manifestPath: '',
          localPath: '',
        ));
        miniApps.insert(0, MiniApp(
          id: 'qr_scanner',
          name: 'Scan QR to Load App',
          version: '1.0.0',
          entryUrl: '',
          permissions: const [],
          manifestPath: '',
          localPath: '',
        ));

        setState(() {
          _availableMiniApps = miniApps;
          _isLoading = false;
        });
      } else {
        // Use mobile loader for Android/iOS
        await MiniAppMobileLoader.initialize();
        final miniApps = await MiniAppMobileLoader.loadAvailableMiniApps();
        
        miniApps.insert(0, MiniApp(
          id: 'hotel_menu',
          name: 'Hotel Menu System',
          version: '1.0.0',
          entryUrl: 'https://hotels-and-restaurants-menu-system.vercel.app',
          permissions: const [],
          manifestPath: '',
          localPath: '',
        ));
        miniApps.insert(0, MiniApp(
          id: 'qr_scanner',
          name: 'Scan QR to Load App',
          version: '1.0.0',
          entryUrl: '',
          permissions: const [],
          manifestPath: '',
          localPath: '',
        ));

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
    if (miniApp.id == 'qr_scanner') {
      _launchScannerDirectly();
      return;
    }

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

      var launchData = await MiniAppRuntimeLoader.launchMiniApp(miniApp.id);
      if (launchData == null && miniApp.id == 'hotel_menu') {
        launchData = {'config': null, 'bridgeConfig': null};
      } else if (launchData == null) {
        _showErrorDialog('Launch Failed', 'Failed to launch Mini-App through Runtime Engine.');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MiniAppContainerScreen(
            app: miniApp,
            directUrl: miniApp.entryUrl,
            runtimeConfig: launchData?['config'],
            bridgeConfig: launchData?['bridgeConfig'],
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

      if (miniApp.id != 'hotel_menu') {
        final launchData = await MiniAppMobileLoader.launchMiniApp(miniApp.id);
        if (launchData == null) {
          _showErrorDialog('Launch Failed', 'Failed to launch Mini-App on Mobile.');
          return;
        }
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

  Future<void> _launchScannerDirectly() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result.isNotEmpty) {
      if (result.startsWith('http://') || result.startsWith('https://')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MiniAppContainerScreen(
              app: MiniApp(
                id: 'scanned_app',
                name: 'Scanned Web App',
                version: '1.0.0',
                entryUrl: result,
                permissions: const [],
                manifestPath: '',
                localPath: '',
              ),
              directUrl: result,
            ),
          ),
        );
      } else {
        _showErrorDialog('Invalid QR Code', 'The scanned QR code does not contain a valid web URL.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-App Browser'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomUrlDialog,
        icon: const Icon(Icons.language),
        label: const Text('Load URL'),
      ),
    );
  }

  void _showCustomUrlDialog() {
    final TextEditingController urlController = TextEditingController(text: 'https://');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Web App'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://hotels-and-restaurants-menu-system.vercel.app',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MiniAppContainerScreen(
                      app: MiniApp(
                        id: 'custom_url',
                        name: 'Custom Web App',
                        version: '1.0.0',
                        entryUrl: url,
                        permissions: const [],
                        manifestPath: '',
                        localPath: '',
                      ),
                      directUrl: url,
                    ),
                  ),
                );
              }
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              kIsWeb ? 'Loading Mini-Apps (Web)...' : 'Loading Mini-Apps (Mobile)...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMiniApps,
                child: const Text('Retry'),
              ),
            ],
          ),
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

    // Separate scanner out of grid for prominent dashboard display
    final gridApps = _availableMiniApps.where((app) => app.id != 'qr_scanner').toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Premium Scan Banner ──
          GestureDetector(
            onTap: _launchScannerDirectly,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scan to Load App',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan any restaurant QR code or mini-app developer token to launch instantly.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Open QR Scanner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Decorative Scan Frame
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 28),
          
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Mini-Apps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${gridApps.length} installed',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini Apps Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridApps.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final app = gridApps[index];
              return _buildAppGridItem(app);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppGridItem(MiniApp app) {
    return GestureDetector(
      onTap: () => _launchMiniApp(app),
      child: Column(
        children: [
          // App Icon Wrapper
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: _getAppGradient(app.id),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                app.icon,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // App Name
          Text(
            app.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 2),
          // App Version or Category
          Text(
            'v${app.version}',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Gradient _getAppGradient(String appId) {
    if (appId == 'restaurant_miniapp' || appId == 'hotel_menu') {
      return LinearGradient(
        colors: [Colors.orange.shade400, Colors.red.shade500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (appId == 'test_app') {
      return LinearGradient(
        colors: [Colors.purple.shade400, Colors.indigo.shade500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (appId == 'simple_app') {
      return LinearGradient(
        colors: [Colors.teal.shade400, Colors.green.shade500],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return LinearGradient(
      colors: [Colors.blue.shade400, Colors.blueAccent.shade700],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
