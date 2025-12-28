import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/orphanage_service.dart';
import '../../core/services/google_places_service.dart';
import '../../core/models/orphanage_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/orphanage_card.dart';
import 'orphanage_detail_screen.dart';

class OrphanageDiscoveryScreen extends StatefulWidget {
  const OrphanageDiscoveryScreen({super.key});

  @override
  State<OrphanageDiscoveryScreen> createState() => _OrphanageDiscoveryScreenState();
}

class _OrphanageDiscoveryScreenState extends State<OrphanageDiscoveryScreen> {
  final OrphanageService _orphanageService = OrphanageService();
  // TODO: Inject API Key properly, e.g., via environment variables or a config file
  final GooglePlacesService _placesService = GooglePlacesService(apiKey: 'YOUR_API_KEY'); 
  
  final Completer<GoogleMapController> _controller = Completer();
  
  bool _isMapView = true;
  double _radiusKm = 10.0;
  Position? _currentPosition;
  String _currentAddress = "Getting location...";
  bool _isLoadingLocation = false;
  Set<Marker> _markers = {};
  List<Orphanage> _orphanages = [];
  bool _isLoadingOrphanages = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = "Location services disabled";
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = "Location permission denied";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = "Location permission permanently denied";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _currentAddress = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        _isLoadingLocation = false;
      });

      _fetchOrphanages();

      // Move map to current location
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 13.0,
        ),
      ));
    } catch (e) {
      setState(() {
        _currentAddress = "Failed to get location: $e";
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _fetchOrphanages() async {
    if (_currentPosition == null) return;

    setState(() => _isLoadingOrphanages = true);

    try {
      final location = GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude);
      
      // Fetch only registered orphanages from Firestore (no Google Places billing required)
      final registeredOrphanages = await _orphanageService.getNearbyOrphanagesFuture(location, _radiusKm);

      setState(() {
        _orphanages = registeredOrphanages;
        _updateMarkers();
        _isLoadingOrphanages = false;
      });
    } catch (e) {
      print("Error fetching orphanages: $e");
      setState(() => _isLoadingOrphanages = false);
    }
  }

  void _updateMarkers() {
    _markers = _orphanages.map((orphanage) {
      final isRegistered = orphanage.userId != 'google_place';
      return Marker(
        markerId: MarkerId(orphanage.id),
        position: LatLng(orphanage.location.latitude, orphanage.location.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isRegistered ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
        ),
        infoWindow: InfoWindow(
          title: orphanage.name,
          snippet: isRegistered ? "Registered Partner" : "Found on Google Maps",
          onTap: () {
             Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrphanageDetailScreen(orphanageId: orphanage.id),
                ),
              );
          },
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("DISCOVER ORPHANAGES", style: AppTypography.sectionHeader(context)),
                          Text(
                            "Find orphanages near you",
                            style: AppTypography.body(context).copyWith(color: AppColors.getTextSecondary(context), fontSize: 12),
                          ),
                        ],
                      ),
                      // View toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getCardBackground(context),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          children: [
                            _buildViewToggle(LucideIcons.map, _isMapView, () {
                              setState(() => _isMapView = true);
                            }),
                            _buildViewToggle(LucideIcons.list, !_isMapView, () {
                              setState(() => _isMapView = false);
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current location
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.getCardBackground(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mapPin, color: AppColors.mintGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextPrimary(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: _isLoadingLocation
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.getTextSecondary(context)),
                                )
                              : Icon(LucideIcons.refreshCw, size: 16, color: AppColors.getTextSecondary(context)),
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Radius slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Search Radius",
                            style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.getTextSecondary(context)),
                          ),
                          Text(
                            "${_radiusKm.toStringAsFixed(0)} km",
                            style: AppTypography.button(context).copyWith(fontSize: 12, color: AppColors.mintGreen),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.mintGreen,
                          inactiveTrackColor: AppColors.getDivider(context),
                          thumbColor: AppColors.mintGreen,
                          overlayColor: AppColors.mintGreen.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          value: _radiusKm,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          onChanged: (value) {
                            setState(() => _radiusKm = value);
                          },
                          onChangeEnd: (value) {
                             _fetchOrphanages();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map or List View
            Expanded(
              child: _currentPosition == null
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.mintGreen),
                    )
                  : _isMapView
                      ? _buildMapView()
                      : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.mintGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.darkCharcoalText : AppColors.getTextSecondary(context),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 13.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        if (!_controller.isCompleted) {
           _controller.complete(controller);
        }
      },
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  Widget _buildListView() {
    if (_isLoadingOrphanages) {
      return Center(child: CircularProgressIndicator(color: AppColors.mintGreen));
    }

    if (_orphanages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 64, color: AppColors.getTextTertiary(context)),
            const SizedBox(height: 16),
            Text(
              "No orphanages found nearby",
              style: AppTypography.button(context).copyWith(color: AppColors.getTextSecondary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              "Try increasing the search radius",
              style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.getTextTertiary(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _orphanages.length,
      itemBuilder: (context, index) {
        final orphanage = _orphanages[index];
        return OrphanageCard(
          orphanage: orphanage,
          userLocation: GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OrphanageDetailScreen(orphanageId: orphanage.id),
              ),
            );
          },
        );
      },
    );
  }
}
