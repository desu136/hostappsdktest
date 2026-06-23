import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/auth_wrapper.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/miniapp_container_screen.dart';
import 'screens/miniapp_browser_screen.dart';
import 'services/miniapp_server.dart';
import 'package:miniapp_runtime_engine/miniapp_runtime_engine.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start Mini-App server only for non-web platforms
  if (!kIsWeb) {
    await MiniAppServer.startServer();
  }
  
  runApp(const EchatApp());
}

class EchatApp extends StatelessWidget {
  const EchatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'Echat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.1,
            ),
            headlineMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.1,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.1,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              letterSpacing: 0.25,
            ),
          ),
          // Card theme for modern UI
          cardTheme: CardThemeData(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          // App bar theme
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/chat-detail': (context) => const ChatDetailScreen(user: null),
          '/webview': (context) => const WebViewScreen(
            title: 'Mini App',
            url: 'http://192.168.1.10:8081',
          ),
          '/miniapp-container': (context) => const MiniAppContainerScreen(
            app: null,
          ),
          '/miniapp-browser': (context) => const MiniAppBrowserScreen(),
        },
      ),
    );
  }
}
