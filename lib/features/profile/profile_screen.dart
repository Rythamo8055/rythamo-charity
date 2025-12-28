import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bento_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/doodle.dart';
import '../../core/services/missions_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/image_service.dart';
import '../../core/providers/theme_provider.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final MissionsService _missionsService = MissionsService();
  final ImageService _imageService = ImageService();
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleEdit(Map<String, dynamic>? currentData) {
    if (_isEditing) {
      // Save
      _missionsService.updateUserProfile({'name': _nameController.text});
    } else {
      // Start Editing
      _nameController.text = currentData?['name'] ?? 'Rythamo User';
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepCharcoal,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _missionsService.getUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.mintGreen));
            }

            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final name = data?['name'] ?? 'Rythamo User';
            final missionsJoined = data?['missions_joined'] ?? 0;
            final impactScore = data?['impact_score'] ?? 0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 120 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("PROFILE", style: AppTypography.sectionHeader(context)),
                      IconButton(
                        icon: Icon(_isEditing ? LucideIcons.check : LucideIcons.edit3, color: AppColors.mintGreen),
                        onPressed: () => _toggleEdit(data),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Avatar & Name
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            // Avatar with profile picture
                            GestureDetector(
                              onTap: () => _showImageSourceDialog(context),
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.getOverlay(context, opacity: 0.2),
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: data?['profilePicture'] != null
                                      ? Image.network(
                                          data!['profilePicture'],
                                          key: ValueKey(data['profilePicture']), // Force rebuild when URL changes
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              color: AppColors.getSurface(context),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                  color: AppColors.mintGreen,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: AppColors.getSurface(context),
                                              child: Icon(
                                                LucideIcons.user,
                                                size: 48,
                                                color: AppColors.getTextTertiary(context),
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: AppColors.getSurface(context),
                                          child: Icon(
                                            LucideIcons.user,
                                            size: 48,
                                            color: AppColors.getTextTertiary(context),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            // Edit button
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showImageSourceDialog(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.mintGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.getBackground(context),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.camera,
                                    size: 16,
                                    color: AppColors.darkCharcoalText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _isEditing
                            ? TextField(
                                controller: _nameController,
                                textAlign: TextAlign.center,
                                style: AppTypography.bigData(context).copyWith(fontSize: 24),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Enter Name",
                                  hintStyle: TextStyle(color: Colors.white24),
                                ),
                              )
                            : Text(
                                name,
                                style: AppTypography.bigData(context).copyWith(fontSize: 24),
                              ),
                        const SizedBox(height: 8),
                        Text(
                          "Level 5 Philanthropist",
                          style: AppTypography.body(context).copyWith(color: AppColors.salmonOrange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Stats Grid
                  Text("YOUR IMPACT", style: AppTypography.sectionHeader(context)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: BentoCard(
                          backgroundColor: AppColors.lighterGraphite,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.rocket, color: AppColors.periwinkleBlue),
                              const SizedBox(height: 16),
                              Text(
                                "$missionsJoined",
                                style: AppTypography.bigData(context).copyWith(fontSize: 48),
                              ),
                              Text("Missions Joined", style: AppTypography.body(context).copyWith(fontSize: 12, color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BentoCard(
                          backgroundColor: AppColors.lighterGraphite,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.heart, color: AppColors.salmonOrange),
                              const SizedBox(height: 16),
                              Text(
                                "$impactScore",
                                style: AppTypography.bigData(context).copyWith(fontSize: 48),
                              ),
                              Text("Lives Impacted", style: AppTypography.body(context).copyWith(fontSize: 12, color: Colors.white54)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Settings List
                  Text("SETTINGS", style: AppTypography.sectionHeader(context)),
                  const SizedBox(height: 16),
                  _buildThemeToggle(context),
                  _buildSettingItem("Notifications", LucideIcons.bell),
                  _buildSettingItem("Privacy & Security", LucideIcons.lock),
                  _buildSettingItem("Help & Support", LucideIcons.helpCircle),
                  _buildSettingItem(
                    "Log Out",
                    LucideIcons.logOut,
                    isDestructive: true,
                    onTap: () async {
                      final authService = AuthService();
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, {bool isDestructive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.lighterGraphite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppColors.salmonOrange : Colors.white70, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTypography.button(context).copyWith(
                color: isDestructive ? AppColors.salmonOrange : Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Change Profile Picture",
              style: AppTypography.sectionHeader(context).copyWith(
                color: AppColors.getTextPrimary(context),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.camera, color: AppColors.mintGreen),
              ),
              title: Text("Take Photo", style: AppTypography.body(context)),
              onTap: () {
                Navigator.pop(context);
                _handleImageSelection(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.periwinkleBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.image, color: AppColors.periwinkleBlue),
              ),
              title: Text("Choose from Gallery", style: AppTypography.body(context)),
              onTap: () {
                Navigator.pop(context);
                _handleImageSelection(ImageSource.gallery);
              },
            ),
            if (!_isUploadingImage) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.salmonOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.trash2, color: AppColors.salmonOrange),
                ),
                title: Text("Remove Photo", style: AppTypography.body(context).copyWith(color: AppColors.salmonOrange)),
                onTap: () async {
                  Navigator.pop(context);
                  await _imageService.deleteProfilePicture();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? image = source == ImageSource.camera
          ? await _imageService.pickImageFromCamera()
          : await _imageService.pickImageFromGallery();

      if (image != null) {
        setState(() => _isUploadingImage = true);
        
        // Show loading snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading profile picture...')),
          );
        }

        await _imageService.uploadProfilePicture(image);
        
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: AppColors.mintGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: AppColors.salmonOrange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? LucideIcons.moon : LucideIcons.sun,
            color: isDark ? AppColors.periwinkleBlue : AppColors.salmonOrange,
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            "Dark Mode",
            style: AppTypography.button(context),
          ),
          const Spacer(),
          Switch(
            value: isDark,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: AppColors.mintGreen,
            activeTrackColor: AppColors.mintGreen.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
