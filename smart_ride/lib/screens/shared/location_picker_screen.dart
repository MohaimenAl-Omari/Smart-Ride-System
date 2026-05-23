import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/constant.dart';

/// The data returned when the user confirms their location choice.
class LocationResult {
  final double lat;
  final double lng;
  final String address;

  const LocationResult({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String title;

  /// Pre-selected position to show when the screen opens (optional).
  final LatLng? initial;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initial,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  // ── Tabs ──────────────────────────────────────────────────────────
  late final TabController _tabs;
  static const int _tabText = 0;
  static const int _tabMap  = 1;

  // ── Shared state ─────────────────────────────────────────────────
  // Default: Amman, Jordan (used for map initial position)
  static const LatLng _amman = LatLng(31.9539, 35.9106);

  LatLng _markerPosition = _amman;
  String _resolvedAddress = '';
  bool _resolving = false;
  bool _confirmed = false; // true once the user has confirmed a result

  // ── "Type Address" tab ───────────────────────────────────────────
  final TextEditingController _manualCtl = TextEditingController();
  String? _manualError;
  bool _searching = false;

  // ── "Pick on Map" tab ────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ── Preset simulation spots (Jordan cities) ──────────────────────
  static const List<_SimSpot> _simSpots = [
    _SimSpot('Amman – Downtown',      31.9539, 35.9106),
    _SimSpot('Amman – Abdali',        31.9727, 35.9179),
    _SimSpot('Zarqa',                 32.0728, 36.0878),
    _SimSpot('Irbid',                 32.5556, 35.8500),
    _SimSpot('Aqaba',                 29.5321, 35.0063),
    _SimSpot('Salt',                  32.0394, 35.7278),
    _SimSpot('Madaba',                31.7165, 35.7934),
    _SimSpot('Jerash',                32.2742, 35.8998),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    if (widget.initial != null) {
      _markerPosition = widget.initial!;
      _reverseGeocode(_markerPosition);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _manualCtl.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _resolving = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).toList();
        setState(() => _resolvedAddress = parts.join(', '));
      }
    } catch (_) {
      setState(() => _resolvedAddress =
          '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}');
    } finally {
      setState(() => _resolving = false);
    }
  }

  Future<bool> _forwardGeocode(String query) async {
    setState(() => _searching = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final l = locations.first;
        final pos = LatLng(l.latitude, l.longitude);
        setState(() {
          _markerPosition   = pos;
          _resolvedAddress  = query;
          _manualError      = null;
        });
        return true;
      } else {
        setState(() => _manualError = 'Address not found — try a different term.');
        return false;
      }
    } catch (_) {
      setState(() => _manualError = 'Could not search for that address.');
      return false;
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _goToMyLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        AppToast.show(
          context,
          'Location permission is permanently denied. Enable it in Settings.',
          error: true,
        );
      }
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final here = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(here, 16));
      setState(() => _markerPosition = here);
      await _reverseGeocode(here);
    } catch (_) {
      if (mounted) AppToast.show(context, 'Could not get your location.', error: true);
    }
  }

  void _jumpToSimSpot(_SimSpot spot) {
    final pos = LatLng(spot.lat, spot.lng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 14));
    setState(() => _markerPosition = pos);
    _reverseGeocode(pos);
  }

  void _confirm() {
    final addr = _resolvedAddress.isNotEmpty
        ? _resolvedAddress
        : _manualCtl.text.trim();
    if (addr.isEmpty) return;
    Navigator.pop(
      context,
      LocationResult(
        lat:     _markerPosition.latitude,
        lng:     _markerPosition.longitude,
        address: addr,
      ),
    );
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTextTab(),
                  _buildMapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.card(),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const Text('Type an address or pick on the map',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ─────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: AppColors.primaryGradient,
            boxShadow: AppShadows.primary(),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 15),
                  SizedBox(width: 6),
                  Text('Type Address'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 15),
                  SizedBox(width: 6),
                  Text('Pick on Map'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── "Type Address" tab ──────────────────────────────────────────

  Widget _buildTextTab() {
    final hasResult = _resolvedAddress.isNotEmpty && _tabs.index == _tabText
        || (_manualCtl.text.trim().isNotEmpty && _resolvedAddress.isNotEmpty);
    // Consider result ready when we've searched and have coords
    final ready = _resolvedAddress.isNotEmpty || _manualCtl.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // Address input field
        Container(
          decoration: AppDecor.card(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your address',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: AppDecor.field(),
                child: TextField(
                  controller: _manualCtl,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'e.g. University of Jordan, Amman',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.place_outlined,
                        color: AppColors.primaryDark, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 14),
                    suffixIcon: _manualCtl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _manualCtl.clear();
                              setState(() {
                                _resolvedAddress = '';
                                _manualError = null;
                              });
                            },
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textMuted),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _searchManual(),
                  textInputAction: TextInputAction.search,
                ),
              ),
              if (_manualError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.rose, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_manualError!,
                          style: const TextStyle(
                              color: AppColors.rose,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Search Address',
                icon: Icons.search_rounded,
                height: 46,
                loading: _searching,
                onTap: _searching ? null : _searchManual,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Preset simulation spots
        const SectionHeader(
          title: 'Quick Locations',
          subtitle: 'Tap a city/landmark to use it directly.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _simSpots.map((spot) {
            final selected = _resolvedAddress.contains(spot.name.split('–').last.trim());
            return GestureDetector(
              onTap: () {
                final pos = LatLng(spot.lat, spot.lng);
                setState(() {
                  _markerPosition  = pos;
                  _resolvedAddress = spot.name;
                  _manualCtl.text  = spot.name;
                  _manualError     = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  boxShadow: selected ? AppShadows.primary() : AppShadows.card(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_rounded,
                        size: 13,
                        color: selected ? Colors.white : AppColors.primaryDark),
                    const SizedBox(width: 5),
                    Text(spot.name,
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Result preview + confirm
        if (_resolvedAddress.isNotEmpty || _manualCtl.text.trim().isNotEmpty) ...[
          _buildResultPreview(),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Confirm Location',
            icon: Icons.check_rounded,
            height: 50,
            onTap: _resolving ? null : _confirm,
            loading: _resolving,
          ),
        ],
      ],
    );
  }

  Future<void> _searchManual() async {
    final q = _manualCtl.text.trim();
    if (q.isEmpty) {
      setState(() => _manualError = 'Please enter an address first.');
      return;
    }
    final ok = await _forwardGeocode(q);
    if (ok) {
      // Show the result
      setState(() {});
    }
  }

  Widget _buildResultPreview() {
    final bool geocoded = _resolvedAddress.isNotEmpty;
    final String displayAddress =
        geocoded ? _resolvedAddress : _manualCtl.text.trim();
    final Color accentColor =
        geocoded ? AppColors.emerald : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              geocoded
                  ? Icons.check_circle_rounded
                  : Icons.edit_location_alt_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  geocoded ? 'Location ready' : 'Address entered',
                  style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(displayAddress,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                if (geocoded)
                  Text(
                    '${_markerPosition.latitude.toStringAsFixed(5)}, '
                    '${_markerPosition.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  )
                else
                  Text(
                    'Tap "Search Address" to verify, or confirm directly.',
                    style: TextStyle(
                        color: AppColors.primary.withOpacity(0.75),
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── "Pick on Map" tab ───────────────────────────────────────────

  Widget _buildMapTab() {
    return Stack(
      children: [
        // Full map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.initial ?? _amman,
            zoom: 13,
          ),
          onMapCreated: (ctrl) => _mapController = ctrl,
          markers: {
            Marker(
              markerId: const MarkerId('selected'),
              position: _markerPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              draggable: true,
              onDragEnd: (pos) async {
                setState(() => _markerPosition = pos);
                await _reverseGeocode(pos);
              },
            ),
          },
          onTap: (pos) async {
            setState(() => _markerPosition = pos);
            await _reverseGeocode(pos);
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),

        // Simulation quick-jump chips (top of map)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _simSpots.map((spot) {
                return GestureDetector(
                  onTap: () => _jumpToSimSpot(spot),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.card(),
                    ),
                    child: Text(spot.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom panel
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.floating(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Address preview
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.place_rounded,
                          color: AppColors.primaryDark, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selected Location',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            _resolving
                                ? 'Resolving address…'
                                : _resolvedAddress.isNotEmpty
                                    ? _resolvedAddress
                                    : 'Tap on the map to pick a location',
                            style: TextStyle(
                                color: _resolvedAddress.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (_resolving)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _goToMyLocation,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.4)),
                            color: AppColors.primarySoft,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.my_location_rounded,
                                  color: AppColors.primaryDark, size: 16),
                              SizedBox(width: 6),
                              Text('My Location',
                                  style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: (_resolving || _resolvedAddress.isEmpty)
                            ? null
                            : _confirm,
                        child: AnimatedOpacity(
                          opacity: _resolvedAddress.isNotEmpty ? 1.0 : 0.45,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: AppColors.primaryGradient,
                              boxShadow: AppShadows.primary(),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded,
                                      color: Colors.white, size: 18),
                                  SizedBox(width: 6),
                                  Text('Confirm Location',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A preset simulation location used for quick-jump chips.
class _SimSpot {
  final String name;
  final double lat;
  final double lng;
  const _SimSpot(this.name, this.lat, this.lng);
}
