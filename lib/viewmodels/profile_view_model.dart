import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repo = ProfileRepository();
  
  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _setLoading(true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      _profile = await _repo.fetchProfile(user.id);
      
      if (_profile == null) {
        _profile = Profile(
          id: '',
          userId: user.id,
          displayName: user.email?.split('@')[0] ?? 'User',
        );
        await _repo.createProfile(_profile!);
        _profile = await _repo.fetchProfile(user.id);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateDisplayName(String newName) async {
    if (_profile == null || newName.trim().isEmpty) return;
    
    _setLoading(true);
    try {
      _profile!.displayName = newName.trim();
      await _repo.updateProfile(_profile!);

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image == null || _profile == null) return;

      _setLoading(true);

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${_profile!.userId}_avatar.$fileExt';
      final storage = Supabase.instance.client.storage.from('image');

      await storage.upload(
        fileName, 
        file, 
        fileOptions: const FileOptions(upsert: true),
      );

      final String publicUrl = storage.getPublicUrl(fileName);
      _profile!.avatarUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      
      await _repo.updateProfile(_profile!);

      notifyListeners();

    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null; 
    notifyListeners();
  }
}