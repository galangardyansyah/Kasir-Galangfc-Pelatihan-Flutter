import 'package:flutter/material.dart';
import 'home_page.dart';
import 'kasir_page.dart';
import 'riwayat_transaksi_page.dart';
import 'laporan_page.dart'; // 1. TAMBAHKAN IMPORT INI
import 'profile_page.dart';
import 'settings_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // 2. TAMBAHKAN LaporanPage() ke dalam list halaman
  final List<Widget> _pages = const [
    HomePage(),
    KasirPage(),
    RiwayatTransaksiPage(),
    LaporanPage(), // Halaman Laporan Baru
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0D47A1), const Color(0xFF001529)]
                : [Colors.blue.shade900, Colors.blue.shade500],
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
            ),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.blue, size: 24);
              }
              return const IconThemeData(color: Colors.white70, size: 22);
            }),
            indicatorColor: Colors.white,
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            // 3. TAMBAHKAN Destinasi Baru untuk Laporan
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Produk',
              ),
              NavigationDestination(
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: 'Kasir',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Riwayat',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined), // Ikon Laporan
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Laporan',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Setelan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}