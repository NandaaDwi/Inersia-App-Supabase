import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inersia_supabase/features/user/profile/providers/edit_profile_provider.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserForEditProvider);
    final editState = ref.watch(editProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          userAsync.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _EditForm(
          initialName: user.name,
          initialUsername: user.username,
          initialBio: user.bio ?? '',
          initialPhotoUrl: user.photoUrl,
          currentUsername: user.username,
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFF374151),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat data profil',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentUserForEditProvider.future),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _EditForm extends HookConsumerWidget {
  final String initialName;
  final String initialUsername;
  final String initialBio;
  final String? initialPhotoUrl;
  final String currentUsername;

  const _EditForm({
    required this.initialName,
    required this.initialUsername,
    required this.initialBio,
    this.initialPhotoUrl,
    required this.currentUsername,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController(text: initialName);
    final usernameCtrl = useTextEditingController(text: initialUsername);
    final bioCtrl = useTextEditingController(text: initialBio);
    final editState = ref.watch(editProfileProvider);

    useEffect(() {
      if (editState.isSuccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(editState.successMessage ?? 'Berhasil!'),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context);
            ref.read(editProfileProvider.notifier).resetStatus();
          }
        });
      }
      return null;
    }, [editState.isSuccess]);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _PhotoPicker(
              currentPhotoUrl: initialPhotoUrl,
              localPhoto: editState.localPhoto,
              onPick: (file) =>
                  ref.read(editProfileProvider.notifier).setLocalPhoto(file),
              onRemove: () =>
                  ref.read(editProfileProvider.notifier).removeLocalPhoto(),
            ),
          ),
          const SizedBox(height: 32),

          _SectionLabel('Nama Lengkap'),
          const SizedBox(height: 8),
          _TextField(
            controller: nameCtrl,
            hintText: 'Nama kamu',
            maxLength: 50,
            errorText: editState.nameError,
            onChanged: (_) {
              if (editState.nameError != null) {
                ref.read(editProfileProvider.notifier).resetStatus();
              }
            },
          ),
          const SizedBox(height: 20),

          _SectionLabel('Username'),
          const SizedBox(height: 4),
          const Text(
            'Hanya huruf, angka, dan underscore (_)',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 12),
          ),
          const SizedBox(height: 8),
          _TextField(
            controller: usernameCtrl,
            hintText: 'username_kamu',
            maxLength: 30,
            prefix: const Text(
              '@',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
            errorText: editState.usernameError,
            onChanged: (_) {
              if (editState.usernameError != null) {
                ref.read(editProfileProvider.notifier).resetStatus();
              }
            },
          ),
          const SizedBox(height: 20),

          _SectionLabel('Bio'),
          const SizedBox(height: 8),
          _TextField(
            controller: bioCtrl,
            hintText: 'Ceritakan sedikit tentang dirimu...',
            maxLength: 160,
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          if (editState.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDC2626).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      editState.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: editState.isLoading
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();
                      await ref
                          .read(editProfileProvider.notifier)
                          .save(
                            name: nameCtrl.text,
                            username: usernameCtrl.text,
                            bio: bioCtrl.text,
                            currentUsername: currentUsername,
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF1E3A5F),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: editState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


class _PhotoPicker extends StatelessWidget {
  final String? currentPhotoUrl;
  final File? localPhoto;
  final ValueChanged<File> onPick;
  final VoidCallback onRemove;

  const _PhotoPicker({
    this.currentPhotoUrl,
    this.localPhoto,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = localPhoto != null;
    final hasRemote = currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty;

    return Stack(
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: const Color(0xFF1F2937),
          backgroundImage: hasLocal
              ? FileImage(localPhoto!) as ImageProvider
              : hasRemote
              ? NetworkImage(currentPhotoUrl!)
              : null,
          child: (!hasLocal && !hasRemote)
              ? const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF6B7280),
                  size: 44,
                )
              : null,
        ),

        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: () => _showPickerOptions(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0D0D0D), width: 2.5),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ganti Foto Profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              title: const Text(
                'Pilih dari Galeri',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (picked != null) onPick(File(picked.path));
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              title: const Text(
                'Ambil Foto',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null) onPick(File(picked.path));
              },
            ),
            if (localPhoto != null || (currentPhotoUrl != null))
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Hapus Foto',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemove();
                },
              ),
          ],
        ),
      ),
    );
  }
}


class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int maxLines;
  final Widget? prefix;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const _TextField({
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.maxLines = 1,
    this.prefix,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFDC2626).withOpacity(0.6)
                  : const Color(0xFF1F2937),
              width: errorText != null ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                  child: prefix,
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  maxLength: maxLength,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(
                      prefix != null ? 6 : 14,
                      14,
                      14,
                      14,
                    ),
                    counterStyle: const TextStyle(color: Color(0xFF4B5563)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
