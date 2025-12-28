import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/donation_service.dart';
import '../../core/models/donation_offer_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/auth_input_field.dart';

class CreateOfferScreen extends StatefulWidget {
  final String? orphanageId;
  final String? orphanageName;
  final String? initialCategory;
  final DonationOffer? existingOffer;

  const CreateOfferScreen({
    super.key,
    this.orphanageId,
    this.orphanageName,
    this.initialCategory,
    this.existingOffer,
  });

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final DonationService _donationService = DonationService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Form State
  final List<DonationItem> _items = [];
  final List<File> _photos = [];
  List<String> _existingPhotoUrls = []; // For editing
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Custom Orphanage Controllers
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customAddressController = TextEditingController();

  DateTime _preferredPickupTime = DateTime.now().add(const Duration(days: 1));
  String _deliveryOption = 'self-delivery';
  bool _isSubmitting = false;

  // Temporary controllers for adding a new item
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedCategory = 'Food';
  String _selectedUnit = 'units';

  final List<String> _categories = ['Food', 'Clothes', 'Toys', 'Books', 'Medical', 'Other'];
  final List<String> _units = ['units', 'kg', 'boxes', 'pieces', 'sets'];

  bool get _isCustom => widget.orphanageId == null && (widget.existingOffer == null || widget.existingOffer!.orphanageId == 'custom');
  bool get _isEditing => widget.existingOffer != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
      // Auto-open add item sheet if a category was selected from home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddItemSheet();
      });
    }

    if (_isEditing) {
      final offer = widget.existingOffer!;
      _items.addAll(offer.items);
      _addressController.text = offer.pickupAddress;
      _notesController.text = offer.notes;
      _deliveryOption = offer.deliveryOption;
      _preferredPickupTime = offer.preferredPickupTime;
      _existingPhotoUrls = List.from(offer.photoUrls);
      
      if (offer.orphanageId == 'custom') {
         _customNameController.text = offer.orphanageName;
         _customAddressController.text = offer.orphanageAddress ?? '';
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    _customNameController.dispose();
    _customAddressController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _photos.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _addItem() {
    if (_itemNameController.text.isNotEmpty && _quantityController.text.isNotEmpty) {
      setState(() {
        _items.add(DonationItem(
          name: _itemNameController.text,
          category: _selectedCategory,
          quantity: int.parse(_quantityController.text),
          unit: _selectedUnit,
        ));
        _itemNameController.clear();
        _quantityController.clear();
      });
      Navigator.pop(context); // Close bottom sheet
    }
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Item", style: AppTypography.sectionHeader(context)),
              const SizedBox(height: 16),
              AuthInputField(
                controller: _itemNameController,
                label: "Item Name",
                hint: "e.g., Rice, T-Shirts",
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AuthInputField(
                      controller: _quantityController,
                      label: "Quantity",
                      hint: "0",
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Unit", style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.getInputBackground(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.getOverlay(context, opacity: 0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              dropdownColor: AppColors.getSurface(context),
                              style: AppTypography.body(context).copyWith(color: AppColors.getTextPrimary(context)),
                              items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                              onChanged: (val) => setState(() => _selectedUnit = val!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Category", style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.getInputBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.getOverlay(context, opacity: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppColors.getSurface(context),
                        style: AppTypography.body(context).copyWith(color: AppColors.getTextPrimary(context)),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: PillButton(
                  text: "ADD ITEM",
                  onPressed: _addItem,
                  color: AppColors.mintGreen,
                  textColor: AppColors.deepCharcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitOffer() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter origin location')),
      );
      return;
    }

    if (_isCustom && (_customNameController.text.isEmpty || _customAddressController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter orphanage details')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in. Please log in again.');
      }

      print('DEBUG: Creating donation - User: ${user.uid}, Editing: $_isEditing');

      if (_isEditing) {
        print('DEBUG: Updating offer ${widget.existingOffer!.id}');
        await _donationService.updateDonationOffer(
          offerId: widget.existingOffer!.id,
          items: _items,
          pickupAddress: _addressController.text,
          preferredPickupTime: _preferredPickupTime,
          deliveryOption: _deliveryOption,
          notes: _notesController.text,
          newPhotos: _photos,
          existingPhotoUrls: _existingPhotoUrls,
        );
        print('DEBUG: Offer updated successfully');
      } else {
        print('DEBUG: Creating new donation offer');
        await _donationService.createDonationOffer(
          donorId: user.uid,
          donorName: user.displayName ?? 'Anonymous',
          orphanageId: widget.orphanageId ?? 'custom',
          orphanageName: widget.orphanageName ?? _customNameController.text,
          orphanageAddress: _isCustom ? _customAddressController.text : null,
          items: _items,
          pickupAddress: _addressController.text,
          preferredPickupTime: _preferredPickupTime,
          deliveryOption: _deliveryOption,
          notes: _notesController.text,
          photos: _photos,
          pickupLocation: const GeoPoint(0, 0),
        );
        print('DEBUG: Donation created successfully');
      }

      if (mounted) {
        Navigator.pop(context); // Go back to details
        
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppColors.getSurface(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/mascot/excited.json',
                    height: 150,
                    width: 150,
                    repeat: false,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEditing ? 'Donation Updated!' : 'Donation Posted!',
                    style: AppTypography.sectionHeader(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Thank you for your generosity.",
                    style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: PillButton(
                      text: "AWESOME",
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.mintGreen,
                      textColor: AppColors.deepCharcoal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print('ERROR: Failed to ${_isEditing ? "update" : "create"} donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.salmonOrange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: Text(_isEditing ? "Edit Donation Offer" : "Make Donation Offer", style: AppTypography.sectionHeader(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orphanage Info
              if (_isCustom) ...[
                Text("ORPHANAGE DETAILS", style: AppTypography.sectionHeader(context)),
                const SizedBox(height: 12),
                AuthInputField(
                  controller: _customNameController,
                  label: "Orphanage Name",
                  hint: "e.g. Sunshine Home",
                  prefixIcon: LucideIcons.building,
                ),
                const SizedBox(height: 12),
                AuthInputField(
                  controller: _customAddressController,
                  label: "Orphanage Address",
                  hint: "Full address of the orphanage",
                  prefixIcon: LucideIcons.mapPin,
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.building, color: AppColors.mintGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Donating to", style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
                            Text(_isEditing ? widget.existingOffer!.orphanageName : widget.orphanageName!, style: AppTypography.button(context).copyWith(fontSize: 16, color: AppColors.getTextPrimary(context))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Items List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ITEMS", style: AppTypography.sectionHeader(context)),
                  TextButton.icon(
                    onPressed: _showAddItemSheet,
                    icon: const Icon(LucideIcons.plus, size: 16, color: AppColors.mintGreen),
                    label: Text("Add Item", style: AppTypography.button(context).copyWith(color: AppColors.mintGreen, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.getOverlay(context, opacity: 0.1), style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Lottie.asset(
                        'assets/mascot/thinking.json',
                        height: 100,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text("No items added yet", style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context))),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getCardBackground(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.getBackground(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(LucideIcons.package, size: 16, color: AppColors.getTextSecondary(context)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name, 
                                  style: AppTypography.button(context).copyWith(color: AppColors.getTextPrimary(context)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${item.quantity} ${item.unit} • ${item.category}", 
                                  style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.salmonOrange),
                            onPressed: () => setState(() => _items.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Photos
              Text("PHOTOS (Optional)", style: AppTypography.sectionHeader(context)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingPhotoUrls.length + _photos.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.getOverlay(context, opacity: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(LucideIcons.camera, color: AppColors.getTextSecondary(context)),
                          ),
                        ),
                      );
                    }
                    
                    // Display existing photos first
                    if (index <= _existingPhotoUrls.length) {
                       final url = _existingPhotoUrls[index - 1];
                       return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _existingPhotoUrls.removeAt(index - 1)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                  ),
                                child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Display new photos
                    final photoIndex = index - _existingPhotoUrls.length - 1;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _photos[photoIndex],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(photoIndex)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                ),
                              child: const Icon(LucideIcons.x, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Origin Location
              Text("ORIGIN LOCATION", style: AppTypography.sectionHeader(context)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackground(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mintGreen.withValues(alpha: 0.3)),
                ),
                child: AuthInputField(
                  controller: _addressController,
                  label: "Pickup Address",
                  hint: "Where should we pick up from?",
                  prefixIcon: LucideIcons.mapPin,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              
              // Delivery Option
              Text("Delivery Option", style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildRadioOption('Self Delivery', 'self-delivery'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRadioOption('Request Pickup', 'pickup-requested'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              AuthInputField(
                controller: _notesController,
                label: "Notes",
                hint: "Any special instructions...",
                prefixIcon: LucideIcons.fileText,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: PillButton(
                  text: _isSubmitting ? "SUBMITTING..." : (_isEditing ? "UPDATE OFFER" : "SUBMIT OFFER"),
                  onPressed: _isSubmitting ? null : _submitOffer,
                  color: AppColors.mintGreen,
                  textColor: AppColors.deepCharcoal,
                  icon: _isSubmitting ? null : LucideIcons.send,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    final isSelected = _deliveryOption == value;
    return GestureDetector(
      onTap: () => setState(() => _deliveryOption = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintGreen.withValues(alpha: 0.2) : AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.mintGreen : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle : LucideIcons.circle,
              size: 16,
              color: isSelected ? AppColors.mintGreen : AppColors.getTextSecondary(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.button(context).copyWith(
                  fontSize: 12,
                  color: isSelected ? AppColors.mintGreen : AppColors.getTextSecondary(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
