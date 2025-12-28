import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/bento_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../../core/services/missions_service.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  String _selectedCategory = "All";
  bool _isMapView = false;
  final List<String> _categories = ["All", "Food", "Clothes", "Books", "Toys", "Others"];
  final MissionsService _missionsService = MissionsService();
  Position? _currentPosition;
  String _currentAddress = "Getting location...";

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = "Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = "Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = "Location permission denied permanently");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _currentAddress = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
      });
    } catch (e) {
      setState(() => _currentAddress = "Unable to get location");
    }
  }

  // Edit Mission Dialog
  void _showEditDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final titleController = TextEditingController(text: data['title']);
    final locationController = TextEditingController(text: data['location']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lighterGraphite,
        title: Text("EDIT MISSION", style: AppTypography.sectionHeader(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Title", labelStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: locationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Location", labelStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              _missionsService.updateMission(doc.id, {
                'title': titleController.text,
                'location': locationController.text,
              });
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: AppColors.mintGreen)),
          ),
        ],
      ),
    );
  }

  // Delete Confirmation
  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.lighterGraphite,
        title: Text("DELETE MISSION?", style: AppTypography.sectionHeader(context)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              _missionsService.deleteMission(docId);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: AppColors.salmonOrange)),
          ),
        ],
      ),
    );
  }

  // Deploy Dialog
  void _showDeployDialog(DocumentSnapshot doc) {
    final mission = doc.data() as Map<String, dynamic>;
    final String title = mission['title'] ?? 'Mission';
    final String category = mission['category'] ?? 'Others';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.lighterGraphite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("DEPLOY SUPPLIES", style: AppTypography.sectionHeader(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You are deploying supplies for '$title'.",
                style: AppTypography.body(context).copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              
              // Shipping From Location
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.deepCharcoal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mintGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, color: AppColors.mintGreen, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "Shipping From:",
                              style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.mintGreen),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.refreshCw, size: 16, color: Colors.white54),
                          onPressed: () async {
                            setState(() => _currentAddress = "Getting location...");
                            await _getCurrentLocation();
                            setState(() {});
                          },
                          tooltip: "Refresh Location",
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentAddress,
                      style: AppTypography.body(context).copyWith(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if (category == "Food")
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.salmonOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.salmonOrange),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: AppColors.salmonOrange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Please ensure food is non-perishable or properly packaged.",
                          style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.salmonOrange),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text("Confirm Deployment?", style: AppTypography.button(context).copyWith(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CANCEL", style: AppTypography.button(context).copyWith(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _missionsService.deploySupplies(doc.id, title, category);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Supplies Deployed from $_currentAddress for $category!"),
                    backgroundColor: AppColors.mintGreen,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 100,
                      left: 16,
                      right: 16,
                    ),
                  ),
                );
              },
              child: Text("CONFIRM", style: AppTypography.button(context).copyWith(color: AppColors.mintGreen)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Methods
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food': return LucideIcons.utensils;
      case 'Clothes': return LucideIcons.thermometerSnowflake;
      case 'Books': return LucideIcons.bookOpen;
      case 'Toys': return LucideIcons.gamepad2;
      case 'Others': return LucideIcons.bath;
      default: return LucideIcons.heart;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Food': return AppColors.periwinkleBlue;
      case 'Clothes': return AppColors.salmonOrange;
      case 'Books': return AppColors.mintGreen;
      case 'Toys': return AppColors.mutedMustard;
      case 'Others': return AppColors.salmonOrange;
      default: return AppColors.lighterGraphite;
    }
  }

  double _getHueForCategory(String category) {
    switch (category) {
      case 'Food': return BitmapDescriptor.hueBlue;
      case 'Clothes': return BitmapDescriptor.hueOrange;
      case 'Books': return BitmapDescriptor.hueGreen;
      case 'Toys': return BitmapDescriptor.hueYellow;
      case 'Others': return BitmapDescriptor.hueRed;
      default: return BitmapDescriptor.hueRed;
    }
  }

  Future<void> _seedData() async {
    final List<Map<String, dynamic>> initialMissions = [
      {
        "title": "WINTER WARMTH",
        "location": "Hope House Orphanage",
        "needs": ["Blankets", "Heaters", "Coats"],
        "urgency": "HIGH",
        "category": "Clothes",
        "latitude": 51.5074,
        "longitude": -0.1278,
      },
      {
        "title": "BACK TO SCHOOL",
        "location": "St. Mary's Shelter",
        "needs": ["Notebooks", "Pencils", "Backpacks"],
        "urgency": "MEDIUM",
        "category": "Books",
        "latitude": 51.5155,
        "longitude": -0.0922,
      },
      {
        "title": "NUTRITION DRIVE",
        "location": "City Care Center",
        "needs": ["Rice", "Beans", "Canned Goods"],
        "urgency": "CRITICAL",
        "category": "Food",
        "latitude": 51.5200,
        "longitude": -0.1100,
      },
      {
        "title": "PLAYTIME FOR ALL",
        "location": "Happy Kids Home",
        "needs": ["Board Games", "Footballs", "Dolls"],
        "urgency": "LOW",
        "category": "Toys",
        "latitude": 51.4900,
        "longitude": -0.1400,
      },
      {
        "title": "HYGIENE KITS",
        "location": "Downtown Shelter",
        "needs": ["Soap", "Toothpaste", "Shampoo"],
        "urgency": "HIGH",
        "category": "Others",
        "latitude": 51.5000,
        "longitude": -0.1000,
      },
    ];

    for (final mission in initialMissions) {
      await _missionsService.addMission(mission);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Database Seeded with Coordinates!"),
          backgroundColor: AppColors.mintGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepCharcoal,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ACTIVE MISSIONS", style: AppTypography.sectionHeader(context)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isMapView ? LucideIcons.list : LucideIcons.map, color: Colors.white),
                        onPressed: () => setState(() => _isMapView = !_isMapView),
                        tooltip: _isMapView ? "List View" : "Map View",
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.database, color: Colors.white24),
                        onPressed: _seedData,
                        tooltip: "Seed Data",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Category Filter (Keep visible in both modes)
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.white : AppColors.lighterGraphite,
                        borderRadius: BorderRadius.circular(100),
                        border: isSelected ? null : Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: AppTypography.button(context).copyWith(
                          fontSize: 12,
                          color: isSelected ? AppColors.deepCharcoal : Colors.white70,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _missionsService.getMissions(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error", style: TextStyle(color: Colors.white)));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  final filteredDocs = _selectedCategory == "All"
                      ? docs
                      : docs.where((doc) => (doc.data() as Map)['category'] == _selectedCategory).toList();

                    if (_isMapView) {
                      return GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(51.509364, -0.128928), // Default London
                          zoom: 13.0,
                        ),
                        markers: filteredDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final lat = data['latitude'] as double? ?? 51.509364;
                          final lng = data['longitude'] as double? ?? -0.128928;
                          final category = data['category'] ?? 'Others';
                          
                          return Marker(
                            markerId: MarkerId(doc.id),
                            position: LatLng(lat, lng),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              _getHueForCategory(category),
                            ),
                            infoWindow: InfoWindow(
                              title: data['title'] ?? 'Mission',
                              snippet: data['location'] ?? '',
                              onTap: () => _showDeployDialog(doc),
                            ),
                          );
                        }).toSet(),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      );
                    }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 120 + MediaQuery.of(context).padding.bottom),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final mission = doc.data() as Map<String, dynamic>;
                      
                      return BentoCard(
                        backgroundColor: AppColors.lighterGraphite,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with category badge and action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getColorForCategory(mission['category']),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(_getIconForCategory(mission['category']), size: 16, color: AppColors.darkCharcoalText),
                                      const SizedBox(width: 8),
                                      Text(
                                        (mission['urgency'] ?? 'MEDIUM').toString().toUpperCase(),
                                        style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.darkCharcoalText),
                                      ),
                                    ],
                                  ),
                                ),
                                // Action buttons
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(LucideIcons.edit3, color: Colors.white54, size: 18),
                                      onPressed: () => _showEditDialog(doc),
                                      tooltip: "Edit Mission",
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, color: AppColors.salmonOrange, size: 18),
                                      onPressed: () => _showDeleteDialog(doc.id),
                                      tooltip: "Delete Mission",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(mission['title'] ?? 'Untitled', style: AppTypography.bigData(context).copyWith(fontSize: 32)),
                            Text(mission['location'] ?? 'Unknown', style: AppTypography.body(context).copyWith(color: Colors.white70)),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: PillButton(
                                text: "DEPLOY SUPPLIES",
                                onPressed: () => _showDeployDialog(doc),
                                color: AppColors.white,
                                textColor: AppColors.deepCharcoal,
                                icon: LucideIcons.rocket,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
