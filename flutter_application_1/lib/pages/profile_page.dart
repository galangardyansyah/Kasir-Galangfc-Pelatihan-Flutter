import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  // --- LOGIC 0: UPDATE FOTO PROFIL (KAMERA/GALERI) ---
  Future<void> _updateProfilePhoto(ImageSource source) async {
    try {
      // 1. Ambil Gambar dari Sumber (Kamera/Galeri)
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Kompres ukuran agar upload ringan
      );

      if (pickedFile == null) return;

      // Tampilkan loading snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sedang mengupload foto...")),
      );

      // 2. Upload ke Firebase Storage
      File file = File(pickedFile.path);
      String uid = user!.uid;
      
      // Simpan di folder user_photos dengan nama file sesuai UID user
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child('$uid.jpg');

      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      // 3. Update URL Foto di Firebase Auth
      await user?.updatePhotoURL(downloadUrl);
      await user?.reload();

      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diperbarui!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal upload: $e")),
        );
      }
    }
  }

  void _showEditPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Pilih Foto Profil", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text("Ambil dari Kamera"),
            onTap: () {
              Navigator.pop(context);
              _updateProfilePhoto(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.green),
            title: const Text("Ambil dari Galeri"),
            onTap: () {
              Navigator.pop(context);
              _updateProfilePhoto(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- LOGIC 1: EDIT NAMA ---
  void _showEditNameDialog() {
    final nameController = TextEditingController(text: user?.displayName ?? "");
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 0, left: 24, right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ubah Nama Tampilan", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nama Lengkap",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: isLoading ? null : () async {
                      if (nameController.text.trim().isEmpty) return;
                      setModalState(() => isLoading = true);
                      try {
                        await user?.updateDisplayName(nameController.text.trim());
                        await user?.reload();
                        setState(() {
                          user = FirebaseAuth.instance.currentUser;
                        });
                        if (mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Nama berhasil diubah")));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Gagal: $e")));
                      } finally {
                        setModalState(() => isLoading = false);
                      }
                    },
                    child: isLoading 
                      ? const SizedBox(height: 20, width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Simpan Perubahan"),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  // --- LOGIC 2: GANTI PASSWORD ---
  void _showChangePasswordDialog() {
    final passwordController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 0, left: 24, right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ganti Password", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Masukkan password baru minimal 6 karakter.", 
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password Baru",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: isLoading ? null : () async {
                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password minimal 6 karakter")));
                        return;
                      }
                      setModalState(() => isLoading = true);
                      try {
                        await user?.updatePassword(passwordController.text.trim());
                        if (mounted) Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Password berhasil diperbarui")));
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'requires-recent-login') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Keamanan: Silakan Login ulang.")));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Gagal: ${e.message}")));
                        }
                      } finally {
                        setModalState(() => isLoading = false);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error),
                    child: isLoading 
                      ? const SizedBox(height: 20, width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Ubah Password"),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String displayName = user?.displayName ?? "Pengguna";
    String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark 
                ? [Colors.blue.shade900, const Color(0xFF0D1B2A)]
                : [Colors.blue.shade900, Colors.blue.shade500],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: _showEditPhotoOptions,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade900, Colors.blue.shade400],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: theme.cardColor,
                        backgroundImage: user?.photoURL != null 
                            ? NetworkImage(user!.photoURL!) 
                            : null,
                        child: user?.photoURL == null
                            ? Text(initial, style: TextStyle(
                                fontSize: 45, fontWeight: FontWeight.bold, 
                                color: theme.colorScheme.primary))
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(displayName, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text(user?.email ?? "", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileTile(context, icon: Icons.person_outline, 
                    title: "Edit Data Diri", subtitle: "Ubah nama tampilan", onTap: _showEditNameDialog),
                  _buildProfileTile(context, icon: Icons.lock_outline, 
                    title: "Keamanan Akun", subtitle: "Ubah password login", onTap: _showChangePasswordDialog),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.errorContainer.withOpacity(0.2),
                    child: ListTile(
                      leading: Icon(Icons.logout, color: theme.colorScheme.error),
                      title: Text("Keluar Aplikasi", style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}