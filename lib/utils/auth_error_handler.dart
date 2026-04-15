import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorHandler {
  static String map(Object error) {
    if (error is AuthException) {
      return _mapAuthException(error);
    }

    final msg = error.toString().toLowerCase();

    if (msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return 'Tidak ada koneksi internet. Periksa jaringan kamu dan coba lagi.';
    }

    return 'Terjadi kesalahan tidak terduga. Coba lagi beberapa saat.';
  }

  static String _mapAuthException(AuthException e) {
    final raw = e.message;
    final msg = raw.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('wrong password')) {
      return 'Email atau kata sandi salah. Periksa kembali dan coba lagi.';
    }

    if (msg.contains('email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return 'Email belum diverifikasi. Cek inbox kamu dan klik link verifikasi.';
    }

    if (msg.contains('too many requests') ||
        msg.contains('rate_limit') ||
        msg.contains('over_email_send_rate_limit')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit sebelum mencoba lagi.';
    }

    if (msg.contains('user_banned') || msg.contains('banned')) {
      return 'Akun kamu telah dinonaktifkan oleh admin. Hubungi support untuk bantuan.';
    }

    if (msg.contains('user not found') || msg.contains('no user')) {
      return 'Akun dengan email ini tidak ditemukan. Coba daftar terlebih dahulu.';
    }

    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('user_already_exists') ||
        msg.contains('duplicate')) {
      return 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
    }

    if (msg.contains('password should be') ||
        msg.contains('password_too_short') ||
        msg.contains('weak_password')) {
      return 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter dengan kombinasi huruf dan angka.';
    }

    if (msg.contains('invalid email') ||
        msg.contains('email_invalid') ||
        msg.contains('unable to validate email')) {
      return 'Format email tidak valid. Pastikan email kamu benar.';
    }

    if (msg.contains('jwt expired') || msg.contains('token_expired')) {
      return 'Sesi kamu telah berakhir. Silakan masuk kembali.';
    }

    if (msg.contains('invalid jwt') ||
        msg.contains('invalid token') ||
        msg.contains('malformed_jwt')) {
      return 'Token tidak valid. Silakan masuk kembali.';
    }

    if (msg.contains('refresh_token_not_found') ||
        msg.contains('refresh token')) {
      return 'Sesi tidak ditemukan. Silakan masuk kembali.';
    }

    if (msg.contains('otp_expired') ||
        msg.contains('otp expired') ||
        msg.contains('token has expired')) {
      return 'Kode verifikasi sudah kadaluarsa. Minta kode baru.';
    }

    if (msg.contains('otp_invalid') ||
        msg.contains('invalid otp') ||
        msg.contains('token is invalid')) {
      return 'Kode verifikasi tidak valid. Periksa kembali kode yang kamu masukkan.';
    }

    if (msg.contains('same_password') ||
        msg.contains('new password should be different')) {
      return 'Kata sandi baru tidak boleh sama dengan kata sandi lama.';
    }

    if (msg.contains('signup_disabled') ||
        msg.contains('signups not allowed')) {
      return 'Pendaftaran akun baru sedang dinonaktifkan. Coba lagi nanti.';
    }

    if (msg.contains('provider_email_needs_verification')) {
      return 'Verifikasi email diperlukan. Cek inbox kamu.';
    }

    if (raw.isNotEmpty && raw.length < 200) {
      return 'Kesalahan autentikasi: $raw';
    }

    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  static String mapRegister(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('duplicate')) {
        return 'Email ini sudah terdaftar. Silakan masuk atau gunakan email lain.';
      }
    }
    return map(error);
  }

  static String mapLogin(Object error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('user not found')) {
        return 'Email atau kata sandi salah. Periksa kembali dan coba lagi.';
      }
    }
    return map(error);
  }
}
