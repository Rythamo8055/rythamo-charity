import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/auth_input_field.dart';
import '../../shared/widgets/pill_button.dart';

class OrphanageProfileSetupScreen extends StatefulWidget {
  const OrphanageProfileSetupScreen({super.key});

  @override
  State<OrphanageProfileSetupScreen> createState() => _OrphanageProfileSetupScreenState();
}

class _OrphanageProfileSetupScreenState extends State<OrphanageProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Create Orphanage Profile
      await FirebaseFirestore.instance.collection('orphanages').add({
        'userId': user.uid,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'description': _descriptionController.text,
        'capacity': int.tryParse(_capacityController.text) ?? 0,
        'currentOccupancy': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'location': const GeoPoint(0, 0), // Placeholder
      });

      // Update User Profile to indicate setup is done (optional, or just rely on orphanage existence)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isProfileSetup': true,
        'displayName': _nameController.text,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile setup complete!"),
            backgroundColor: AppColors.mintGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.salmonOrange),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Setup Profile", style: AppTypography.sectionHeader(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tell us about your orphanage",
                style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
              ),
              const SizedBox(height: 24),

              AuthInputField(
                controller: _nameController,
                label: "Orphanage Name",
                hint: "e.g. Sunshine Home",
                prefixIcon: LucideIcons.building,
                validator: (v) => v?.isEmpty == true ? "Required" : null,
              ),
              const SizedBox(height: 16),

              AuthInputField(
                controller: _phoneController,
                label: "Phone Number",
                hint: "+1 234 567 8900",
                prefixIcon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty == true ? "Required" : null,
              ),
              const SizedBox(height: 16),

              AuthInputField(
                controller: _addressController,
                label: "Address",
                hint: "Full address",
                prefixIcon: LucideIcons.mapPin,
                validator: (v) => v?.isEmpty == true ? "Required" : null,
              ),
              const SizedBox(height: 16),

              AuthInputField(
                controller: _capacityController,
                label: "Capacity",
                hint: "Number of children",
                prefixIcon: LucideIcons.users,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              AuthInputField(
                controller: _descriptionController,
                label: "Description",
                hint: "Brief description of your mission...",
                prefixIcon: LucideIcons.fileText,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: PillButton(
                  text: _isLoading ? "SAVING..." : "COMPLETE SETUP",
                  onPressed: _isLoading ? null : _saveProfile,
                  color: AppColors.mintGreen,
                  textColor: AppColors.darkCharcoalText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
