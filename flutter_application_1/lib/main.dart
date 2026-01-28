import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/main_layout.dart'; // DIUBAH: Sekarang mengarah ke MainLayout
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Kasir Galang Fotocopy',
      debugShowCheckedModeBanner: false,
      
      // Konfigurasi Tema Terang
      theme: themeProvider.lightTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      
      // Konfigurasi Tema Gelap
      darkTheme: themeProvider.darkTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade900,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: themeProvider.themeMode, 
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Loading screen saat mengecek status login
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Jika user sudah login, arahkan ke MainLayout (Menu Utama)
          if (snapshot.hasData) {
            return const MainLayout(); // REVISI: Memanggil MainLayout
          }
          
          // Jika belum login, tampilkan halaman Login
          return const LoginPage();
        },
      ),
    );
  }
}