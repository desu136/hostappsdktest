class MiniApp {
  final String id;
  final String name;
  final String version;
  final String entryUrl;
  final List<String> permissions;
  final String? author;
  final String manifestPath;
  final String localPath;
  final String? customIcon;

  const MiniApp({
    required this.id,
    required this.name,
    required this.version,
    required this.entryUrl,
    this.permissions = const [],
    this.author,
    required this.manifestPath,
    required this.localPath,
    this.customIcon,
  });

  // Legacy constructor for backward compatibility
  MiniApp.legacy({
    required this.id,
    required this.name,
    required String description,
    required String icon,
    required String url,
    String category = 'General',
  }) : version = '1.0.0',
       entryUrl = url,
       permissions = [],
       author = null,
       manifestPath = '',
       localPath = '',
       customIcon = icon;

  // For backward compatibility
  String get description => 'Mini-App: $name';
  String get icon {
    if (customIcon != null && customIcon!.isNotEmpty) return customIcon!;
    if (id == 'restaurant_miniapp' || id == 'hotel_menu') return '🍔';
    if (id == 'qr_scanner') return '🔍';
    if (id == 'simple_app') return '📱';
    if (id == 'test_app') return '🧪';
    return '📱';
  }
  String get url => entryUrl;
  String get category => 'General';

  // Sample mini-apps for demonstration
  static List<MiniApp> getSampleApps() {
    return [
      MiniApp.legacy(
        id: '1',
        name: 'Weather',
        description: 'Check weather forecast',
        icon: '🌤️',
        url: 'http://192.168.1.10:8081/weather',
        category: 'Utilities',
      ),
      MiniApp.legacy(
        id: '2',
        name: 'Calculator',
        description: 'Perform calculations',
        icon: '🧮',
        url: 'http://192.168.1.10:8081/calculator',
        category: 'Utilities',
      ),
      MiniApp.legacy(
        id: '3',
        name: 'News',
        description: 'Latest news updates',
        icon: '📰',
        url: 'http://192.168.1.10:8081/news',
        category: 'Information',
      ),
      MiniApp.legacy(
        id: '4',
        name: 'Games',
        description: 'Play fun games',
        icon: '🎮',
        url: 'http://192.168.1.10:8081/games',
        category: 'Entertainment',
      ),
      MiniApp.legacy(
        id: '5',
        name: 'Music',
        description: 'Listen to music',
        icon: '🎵',
        url: 'http://192.168.1.10:8081/music',
        category: 'Entertainment',
      ),
      MiniApp.legacy(
        id: '6',
        name: 'Calendar',
        description: 'Manage your schedule',
        icon: '📅',
        url: 'http://192.168.1.10:8081/calendar',
        category: 'Productivity',
      ),
      MiniApp.legacy(
        id: '7',
        name: 'Notes',
        description: 'Take quick notes',
        icon: '📝',
        url: 'http://192.168.1.10:8081/notes',
        category: 'Productivity',
      ),
      MiniApp.legacy(
        id: '8',
        name: 'Maps',
        description: 'Navigate and explore',
        icon: '🗺️',
        url: 'http://192.168.1.10:8081/maps',
        category: 'Utilities',
      ),
      MiniApp.legacy(
        id: '9',
        name: 'Camera',
        description: 'Capture moments',
        icon: '�',
        url: 'http://192.168.1.10:8081/camera',
        category: 'Utilities',
      ),
    ];
  }

  // Get apps by category
  static List<MiniApp> getAppsByCategory(String category) {
    final allApps = getSampleApps();
    if (category == 'All') {
      return allApps;
    }
    return allApps.where((app) => app.category == category).toList();
  }

  // Get all categories
  static List<String> getCategories() {
    final allApps = getSampleApps();
    final categories = allApps.map((app) => app.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }
}
