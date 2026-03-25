import 'package:flutter/material.dart';
import '../models/mini_app.dart';
import '../widgets/mini_app_card.dart';
import 'miniapp_container_screen.dart';

class MiniAppsScreen extends StatefulWidget {
  const MiniAppsScreen({super.key});

  @override
  State<MiniAppsScreen> createState() => _MiniAppsScreenState();
}

class _MiniAppsScreenState extends State<MiniAppsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = MiniApp.getCategories();
  final TextEditingController _searchController = TextEditingController();
  List<MiniApp> _filteredApps = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _filteredApps = MiniApp.getSampleApps();
    _searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = MiniApp.getAppsByCategory(_selectedCategory)
          .where((app) =>
              app.name.toLowerCase().contains(query) ||
              app.description.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mini Apps',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _categories.map((category) {
            return Tab(text: category);
          }).toList(),
          onTap: (index) {
            _onCategoryChanged(_categories[index]);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _filteredApps = MiniApp.getAppsByCategory(_selectedCategory);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search mini apps...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Mini apps grid
          Expanded(
            child: _filteredApps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apps_outage,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No mini apps found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      return MiniAppCard(
                        app: app,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MiniAppContainerScreen(app: app),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "add",
            onPressed: _showAddMiniAppDialog,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "test",
            onPressed: _showTestUrlDialog,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: const Icon(Icons.science),
          ),
        ],
      ),
    );
  }

  void _showAddMiniAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mini App'),
        content: const Text('Mini app management feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTestUrlDialog() {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Mini App URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Mini App Name (optional)',
                hintText: 'Test Mini App',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Mini App URL',
                hintText: 'http://localhost:3000 or http://192.168.1.10:8081/app',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Text(
              'Use this to test mini-apps developed with @ebisa-tesfaye/miniapp-sdk',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = urlController.text.trim();
              final name = nameController.text.trim().isNotEmpty 
                  ? nameController.text.trim() 
                  : 'Test Mini App';
              
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _launchTestMiniApp(name, url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid URL')),
                );
              }
            },
            child: const Text('Launch'),
          ),
        ],
      ),
    );
  }

  void _launchTestMiniApp(String name, String url) {
    final testApp = MiniApp.legacy(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: 'Test mini-app from URL',
      icon: '🧪',
      url: url,
      category: 'Testing',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MiniAppContainerScreen(
          app: testApp,
          directUrl: url,
        ),
      ),
    );
  }
}
