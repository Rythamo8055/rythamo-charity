import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

/// Service for handling image uploads and management
class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  
  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }
  
  /// Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(XFile imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      
      // Create file reference
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('profile_pictures').child(fileName);
      
      // Upload file
      final File file = File(imageFile.path);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': user.uid},
        ),
      );
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Delete old profile picture if exists
      await _deleteOldProfilePicture(user.uid);
      
      // Update user profile in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profilePicture': downloadUrl,
        'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }
  
  /// Delete old profile picture from storage
  Future<void> _deleteOldProfilePicture(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      
      if (data != null && data.containsKey('profilePicture')) {
        final String? oldUrl = data['profilePicture'] as String?;
        if (oldUrl != null && oldUrl.isNotEmpty) {
          try {
            final Reference oldRef = _storage.refFromURL(oldUrl);
            await oldRef.delete();
          } catch (e) {
            debugPrint('Error deleting old profile picture: $e');
            // Continue even if deletion fails
          }
        }
      }
    } catch (e) {
      debugPrint('Error accessing old profile picture: $e');
    }
  }
  
  /// Get user's profile picture URL
  Future<String?> getProfilePictureUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data();
      return data?['profilePicture'] as String?;
    } catch (e) {
      debugPrint('Error getting profile picture URL: $e');
      return null;
    }
  }
  
  /// Delete user's profile picture
  Future<bool> deleteProfilePicture() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }
      
      await _deleteOldProfilePicture(user.uid);
      
      await _firestore.collection('users').doc(user.uid).update({
        'profilePicture': FieldValue.delete(),
        'profilePictureUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error deleting profile picture: $e');
      return false;
    }
  }
  
  /// Show image source selection (gallery or camera)
  Future<XFile?> showImageSourceSelection({
    required Function(ImageSource) onSourceSelected,
  }) async {
    // This will be called from UI to show a dialog
    // The UI will handle showing the dialog and calling pickImageFromGallery or pickImageFromCamera
    return null;
  }
}
