String getReadableErrorMessage(Object error) {
  final errString = error.toString().toLowerCase();

  if (errString.contains('socketexception') ||
      errString.contains('connection refused') ||
      errString.contains('network is unreachable')) {
    return 'Koneksi terputus. Pastikan perangkat Anda terhubung ke internet.';
  }

  if (errString.contains('timeout')) {
    return 'Permintaan waktu habis. Silakan coba beberapa saat lagi.';
  }

  return 'Terjadi kesalahan sistem. Mohon coba lagi nanti.';
}
