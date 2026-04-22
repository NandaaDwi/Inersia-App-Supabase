import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Kebijakan Privasi",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A237E).withOpacity(0.2),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 30),
                  _buildPolicySection(
                    title: "1. Informasi yang Kami Kumpulkan",
                    content:
                        "Inersia mengumpulkan informasi yang Anda berikan saat mendaftar, seperti nama, alamat email, dan preferensi topik artikel. Kami juga mengumpulkan data penggunaan secara otomatis untuk meningkatkan pengalaman membaca Anda.",
                  ),
                  _buildPolicySection(
                    title: "2. Penggunaan Informasi",
                    content:
                        "Data Anda digunakan untuk personalisasi feed artikel, mengirimkan notifikasi konten terbaru, dan mengelola akun penulis Anda secara aman di platform kami.",
                  ),
                  _buildPolicySection(
                    title: "3. Keamanan Data",
                    content:
                        "Kami menggunakan teknologi enkripsi terkini dan layanan Supabase untuk memastikan data pribadi Anda aman dari akses yang tidak sah.",
                  ),
                  _buildPolicySection(
                    title: "4. Hak Pengguna",
                    content:
                        "Anda memiliki hak penuh untuk memperbarui profil dan menghapus konten yang Anda tulis.",
                  ),
                  _buildPolicySection(
                    title: "5. Perubahan Kebijakan",
                    content:
                        "Kami dapat memperbarui kebijakan ini secara berkala. Perubahan signifikan akan diberitahukan melalui notifikasi aplikasi atau email yang terdaftar.",
                  ),
                  const SizedBox(height: 40),
                  _buildContactBox(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Privasi Anda Penting",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Terakhir diperbarui: 20 April 2026",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPolicySection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F7AF6),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            "Punya pertanyaan lebih lanjut?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            "support@inersia.com",
            style: TextStyle(
              color: const Color(0xFF3F7AF6),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
