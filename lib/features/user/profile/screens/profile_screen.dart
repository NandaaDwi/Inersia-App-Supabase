import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: authState.when(
          data: (_) => ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              context.go('/login');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logout berhasil')));
            },
            child: const Text('Logout'),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text('Terjadi kesalahan: $error', textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
