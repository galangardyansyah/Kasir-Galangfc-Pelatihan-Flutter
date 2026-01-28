import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pengaturan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(theme, "UMUM"),

          // TEMA APLIKASI
          _buildTile(
            theme,
            icon: Icons.palette_outlined,
            title: "Tema Aplikasi",
            subtitle: "Mode: ${themeProvider.themeMode.name.toUpperCase()}",
            onTap: () => _showThemeDialog(context, themeProvider),
          ),

          // BAHASA
          _buildTile(
            theme,
            icon: Icons.language_outlined,
            title: "Bahasa",
            subtitle: "Indonesia",
            onTap: () {
              // Tambahkan logika ganti bahasa di sini nanti
            },
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(theme, "APLIKASI"),

          // TENTANG APLIKASI
          _buildTile(
            theme,
            icon: Icons.info_outline,
            title: "Tentang Aplikasi",
            subtitle: "Informasi versi & pengembang",
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "Inventory Pro",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(Icons.store, size: 40),
              );
            },
          ),

          // KEBIJAKAN PRIVASI
          _buildTile(
            theme,
            icon: Icons.privacy_tip_outlined,
            title: "Kebijakan Privasi",
            subtitle: "Lihat kebijakan penggunaan",
            onTap: () {
              // Logika url_launcher bisa ditaruh di sini
            },
          ),

          const SizedBox(height: 40),

          Center(
            child: Text(
              "Versi 1.0.0",
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Helper agar tampilan konsisten ---

  void _showThemeDialog(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Tema"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text("Terang"),
              value: ThemeMode.light,
              groupValue: provider.themeMode,
              onChanged: (mode) {
                provider.setTheme(mode!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text("Gelap"),
              value: ThemeMode.dark,
              groupValue: provider.themeMode,
              onChanged: (mode) {
                provider.setTheme(mode!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }
}