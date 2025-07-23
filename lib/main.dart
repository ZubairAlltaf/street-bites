import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streetbites/models/cart_model.dart';
import 'package:streetbites/provider/buyer/buyer_auth_provider.dart';
import 'package:streetbites/provider/buyer/chat_provider.dart';
import 'package:streetbites/provider/buyer/food_lover_provider.dart';
import 'package:streetbites/provider/vendore/product_provider.dart';
import 'package:streetbites/provider/vendore/seller_auth_provider.dart';
import 'package:streetbites/provider/vendore/vendore_chat_provider.dart';
import 'package:streetbites/screens/foodlover/buyer_home_screen.dart';
import 'package:streetbites/screens/login_screen.dart';
import 'package:streetbites/screens/role_selection_screen.dart';
import 'package:streetbites/screens/vendore/seller_signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://prdasllwzrvtvpafeajq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByZGFzbGx3enJ2dHZwYWZlYWpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIwMzY4MTAsImV4cCI6MjA2NzYxMjgxMH0.YyRMCWKz1fkk_Bd4xum3BiEsLKLuD7hzfLOunIg_KBU',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BuyerAuthProvider()),
        ChangeNotifierProvider(create: (_) => FoodLoverProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VendorChatProvider()),
        ChangeNotifierProvider(create: (_) => SellerAuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool initialized = false;

  @override
  void initState() {
    super.initState();


    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        final user = session.user;
        final provider = Provider.of<BuyerAuthProvider>(context, listen: false);

        await provider.insertUserIfNotExists(
          user: user,
          name: user.userMetadata?['full_name'] ?? '',
          username: user.email?.split('@').first ?? '',
          phone: '',
        );

        setState(() {
          initialized = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StreetBites',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.green),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const RoleSelectionScreen(),
        '/food_lover_home': (context) => const FoodLoverHomeScreen(),
      },
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor ?? Colors.green,
      ),
    );
  }
}
