import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/profile/services/edit_profile_service.dart';
import 'package:inersia_supabase/models/user_model.dart';

final editProfileServiceProvider = Provider.autoDispose(
  (_) => EditProfileService(),
);

final currentUserForEditProvider = FutureProvider.autoDispose<UserModel>((ref) {
  return ref.read(editProfileServiceProvider).getCurrentUser();
});

enum EditProfileStatus { idle, loading, success, error }

class EditProfileState {
  final EditProfileStatus status;
  final String? errorMessage;
  final String? successMessage;
  final File? localPhoto;
  final String? nameError;
  final String? usernameError;

  const EditProfileState({
    this.status = EditProfileStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.localPhoto,
    this.nameError,
    this.usernameError,
  });

  bool get isLoading => status == EditProfileStatus.loading;
  bool get isSuccess => status == EditProfileStatus.success;

  EditProfileState copyWith({
    EditProfileStatus? status,
    String? errorMessage,
    String? successMessage,
    File? localPhoto,
    String? nameError,
    String? usernameError,
    bool clearLocalPhoto = false,
    bool clearErrors = false,
    bool clearMessages = false,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages
          ? null
          : (successMessage ?? this.successMessage),
      localPhoto: clearLocalPhoto ? null : (localPhoto ?? this.localPhoto),
      nameError: clearErrors ? null : (nameError ?? this.nameError),
      usernameError: clearErrors ? null : (usernameError ?? this.usernameError),
    );
  }
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final EditProfileService _service;

  EditProfileNotifier(this._service) : super(const EditProfileState());

  void setLocalPhoto(File file) {
    state = state.copyWith(localPhoto: file);
  }

  void removeLocalPhoto() {
    state = state.copyWith(clearLocalPhoto: true);
  }

  Future<bool> save({
    required String name,
    required String username,
    required String bio,
    String? currentUsername,
  }) async {
    state = state.copyWith(clearErrors: true, clearMessages: true);

    bool hasError = false;

    if (name.trim().isEmpty) {
      state = state.copyWith(nameError: 'Nama tidak boleh kosong.');
      hasError = true;
    } else if (name.trim().length < 2) {
      state = state.copyWith(nameError: 'Nama minimal 2 karakter.');
      hasError = true;
    }

    if (username.trim().isEmpty) {
      state = state.copyWith(usernameError: 'Username tidak boleh kosong.');
      hasError = true;
    } else if (username.trim().length < 3) {
      state = state.copyWith(usernameError: 'Username minimal 3 karakter.');
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
      state = state.copyWith(
        usernameError: 'Username hanya boleh huruf, angka, dan underscore.',
      );
      hasError = true;
    }

    if (hasError) return false;

    state = state.copyWith(status: EditProfileStatus.loading);

    try {
      final usernameChanged =
          username.trim().toLowerCase() !=
          (currentUsername ?? '').toLowerCase();

      if (usernameChanged) {
        final available = await _service.isUsernameAvailable(username.trim());
        if (!available) {
          if (mounted) {
            state = state.copyWith(
              status: EditProfileStatus.idle,
              usernameError: 'Username sudah digunakan.',
            );
          }
          return false;
        }
      }

      await _service.updateProfile(
        name: name,
        username: username,
        bio: bio,
        photoFile: state.localPhoto,
      );

      if (mounted) {
        state = state.copyWith(
          status: EditProfileStatus.success,
          successMessage: 'Profil berhasil diperbarui!',
          clearLocalPhoto: true,
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          status: EditProfileStatus.error,
          errorMessage: 'Gagal menyimpan profil. Coba lagi.',
        );
      }
      return false;
    }
  }

  void resetStatus() {
    state = state.copyWith(status: EditProfileStatus.idle, clearMessages: true);
  }
}

final editProfileProvider =
    StateNotifierProvider.autoDispose<EditProfileNotifier, EditProfileState>(
      (ref) => EditProfileNotifier(ref.read(editProfileServiceProvider)),
    );
