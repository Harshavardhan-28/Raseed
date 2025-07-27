import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'screens/receipt_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Disable debug overlays in production
  WidgetsApp.debugAllowBannerOverride = false;
  
  runApp(const RaseedApp());
}

class RaseedApp extends StatefulWidget {
  const RaseedApp({super.key});

  @override
  State<RaseedApp> createState() => _RaseedAppState();
}

class _RaseedAppState extends State<RaseedApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Listen to incoming links when the app is already open
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Deep link received: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('🚨 Deep link error: $err');
      },
    );

    // Handle deep link when app is launched from a link
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        debugPrint('🚀 Initial deep link: $uri');
        // Delay handling to ensure widget tree is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(uri);
        });
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('🎯 Handling deep link: ${uri.toString()}');
    
    // Check if it's a receipt deep link: raseed://receipt/receiptId
    if (uri.scheme == 'raseed' && uri.host == 'receipt') {
      final receiptId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      
      if (receiptId != null) {
        debugPrint('📄 Opening receipt: $receiptId');
        
        // Navigate to receipt detail screen
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ReceiptDetailScreen(receiptId: receiptId),
          ),
        );
      } else {
        debugPrint('❌ Invalid receipt ID in deep link');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RASEED - Finance App',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display', // iOS style font
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
