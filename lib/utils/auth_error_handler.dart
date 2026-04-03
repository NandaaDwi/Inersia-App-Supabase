import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorHandler {
  static String mapError(Object e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return "Email atau kata sandi salah.";
      }
      if (msg.contains('email not confirmed')) {
        return "Email belum diverifikasi. Silakan cek kotak masuk Anda.";
      }
      if (msg.contains('already registered')) {
        return "Email ini sudah terdaftar. Silakan masuk.";
      }
      if (msg.contains('too many requests')) {
        return "Terlalu banyak percobaan. Silakan tunggu beberapa saat.";
      }
      if (msg.contains('user_banned')) {
        return "Akun Anda telah ditangguhkan. Hubungi admin untuk bantuan.";
      }
      return e.message;
    }
    return "Terjadi kesalahan koneksi. Silakan coba lagi.";
  }
}
