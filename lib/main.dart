import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

// 🔑 CONFIGURACIÓN SUPABASE (WEB)
const String supabaseUrl = 'https://tdwqqewjbaagweuujxcw.supabase.co';
const String supabaseAnonKey = 'sb_publishable_7UjMcXrFGPVBioVvsityDw_KRFJDUM6';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TechSolutions Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: session == null ? const LoginScreen() : const DashboardScreen(),
    );
  }
}