import 'dart:io';

import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileService {
  final _client = supabaseConfig.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  Future<UserModel> getCurrentUser() async {
    final res = await _client
        .from('users')
        .select()
        .eq('id', _currentUserId)
        .single();

    return UserModel.fromJson(res);
  }

  Future<bool> isUsernameAvailable(String username) async {
    final res = await _client
        .from('users')
        .select('id')
        .eq('username', username)
        .neq('id', _currentUserId)
        .maybeSingle();

    return res == null;
  }

  Future<String> uploadPhoto(File imageFile) async {
    final uid = _currentUserId;
    final ext = imageFile.path.split('.').last.toLowerCase();
    final path = '$uid.$ext';

    await _client.storage
        .from('avatars')
        .upload(path, imageFile, fileOptions: FileOptions(upsert: true));

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  Future<UserModel> updateProfile({
    required String name,
    required String username,
    required String bio,
    File? photoFile,
  }) async {
    final uid = _currentUserId;
    String? newPhotoUrl;

    if (photoFile != null) {
      newPhotoUrl = await uploadPhoto(photoFile);
    }

    final updates = <String, dynamic>{
      'name': name.trim(),
      'username': username.trim(),
      'bio': bio.trim(),
      'updated_at': DateTime.now().toIso8601String(),
      if (newPhotoUrl != null) 'photo_url': newPhotoUrl,
    };

    final res = await _client
        .from('users')
        .update(updates)
        .eq('id', uid)
        .select()
        .single();

    return UserModel.fromJson(res);
  }
}
