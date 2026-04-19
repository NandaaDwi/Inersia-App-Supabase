import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inersia_supabase/features/auth/widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A237E).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A237E).withOpacity(0.2),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Masuk untuk melanjutkan perjalanan kreatifmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 220,
                  child: Image.asset(
                    'assets/images/logo_inersia2.png',
                    fit: BoxFit.contain,
                  ),
                ),

                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _LoginFormPanel(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoginForm(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun? ',
                  style: TextStyle(color: Colors.white70),
                ),
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: const Text(
                    'Daftar sekarang',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F7AF6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
