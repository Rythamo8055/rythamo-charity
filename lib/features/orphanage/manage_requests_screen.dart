import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/request_service.dart';
import '../../core/models/item_request_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/auth_input_field.dart';
import '../../shared/widgets/request_card.dart';
import '../../shared/widgets/error_state_widget.dart';

class ManageRequestsScreen extends StatefulWidget {
  final String orphanageId;
  final String orphanageName;

  const ManageRequestsScreen({
    super.key,
    required this.orphanageId,
    required this.orphanageName,
  });

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  final RequestService _requestService = RequestService();

  void _showCreateRequestSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateRequestSheet(
        orphanageId: widget.orphanageId,
        orphanageName: widget.orphanageName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Manage Requests", style: AppTypography.sectionHeader(context)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.mintGreen),
            onPressed: _showCreateRequestSheet,
          ),
        ],
      ),
      body: StreamBuilder<List<ItemRequest>>(
        stream: _requestService.getOrphanageRequests(widget.orphanageId),
        builder: (context, snapshot) {
          // Don't show cached data while loading - prevents flash of old data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.mintGreen));
          }

          // Show error if any
          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: "Could not load requests",
              onRetry: () => (context as Element).markNeedsBuild(),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.clipboardList, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  Text(
                    "No active requests",
                    style: AppTypography.button(context).copyWith(color: AppColors.getTextSecondary(context)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: PillButton(
                      text: "CREATE REQUEST",
                      onPressed: _showCreateRequestSheet,
                      color: AppColors.mintGreen,
                      textColor: AppColors.darkCharcoalText,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return RequestCard(
                request: request,
                showOrphanageName: false,
                actionLabel: "Delete",
                onActionPressed: () async {
                  // Confirm delete
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.getCardBackground(context),
                      title: Text("Delete Request?", style: AppTypography.sectionHeader(context)),
                      content: Text("This action cannot be undone.", style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context))),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text("Cancel", style: AppTypography.button(context).copyWith(color: AppColors.getTextSecondary(context))),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete", style: TextStyle(color: AppColors.salmonOrange)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && mounted) {
                    try {
                      // Show loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Deleting request..."),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      
                      await _requestService.deleteRequest(request.id);
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Request deleted successfully"),
                            backgroundColor: AppColors.mintGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error deleting request: $e"),
                            backgroundColor: AppColors.salmonOrange,
                          ),
                        );
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRequestSheet,
        backgroundColor: AppColors.mintGreen,
        child: const Icon(LucideIcons.plus, color: AppColors.darkCharcoalText),
      ),
    );
  }
}

class _CreateRequestSheet extends StatefulWidget {
  final String orphanageId;
  final String orphanageName;

  const _CreateRequestSheet({
    required this.orphanageId,
    required this.orphanageName,
  });

  @override
  State<_CreateRequestSheet> createState() => _CreateRequestSheetState();
}

class _CreateRequestSheetState extends State<_CreateRequestSheet> {
  final RequestService _requestService = RequestService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String _selectedCategory = 'Food';
  String _selectedUnit = 'units';
  RequestPriority _selectedPriority = RequestPriority.medium;
  bool _isSubmitting = false;

  final List<String> _categories = ['Food', 'Clothes', 'Toys', 'Books', 'Medical', 'Other'];
  final List<String> _units = ['units', 'kg', 'boxes', 'pieces', 'sets'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _requestService.createRequest(
        orphanageId: widget.orphanageId,
        orphanageName: widget.orphanageName,
        itemName: _itemController.text,
        category: _selectedCategory,
        quantityNeeded: int.parse(_quantityController.text),
        unit: _selectedUnit,
        description: _descController.text,
        priority: _selectedPriority,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Request", style: AppTypography.sectionHeader(context)),
            const SizedBox(height: 24),
            
            AuthInputField(
              controller: _itemController,
              label: "Item Name",
              hint: "e.g. Rice, Winter Jackets",
            ),
            const SizedBox(height: 16),
            
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
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown("Unit", _selectedUnit, _units, (v) => setState(() => _selectedUnit = v!)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildDropdown("Category", _selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriorityDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            AuthInputField(
              controller: _descController,
              label: "Description (Optional)",
              hint: "Any specific details...",
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: PillButton(
                text: _isSubmitting ? "POSTING..." : "POST REQUEST",
                onPressed: _isSubmitting ? null : _submit,
                color: AppColors.mintGreen,
                textColor: AppColors.darkCharcoalText,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
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
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.getSurface(context),
              style: AppTypography.body(context).copyWith(color: AppColors.getTextPrimary(context)),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Priority", style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.getInputBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getOverlay(context, opacity: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<RequestPriority>(
              value: _selectedPriority,
              isExpanded: true,
              dropdownColor: AppColors.getSurface(context),
              style: AppTypography.body(context).copyWith(color: AppColors.getTextPrimary(context)),
              items: RequestPriority.values.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p.name.toUpperCase(), style: TextStyle(
                  color: p == RequestPriority.urgent ? AppColors.salmonOrange : AppColors.getTextPrimary(context)
                )),
              )).toList(),
              onChanged: (v) => setState(() => _selectedPriority = v!),
            ),
          ),
        ),
      ],
    );
  }
}
