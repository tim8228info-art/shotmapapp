import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

/// flutter_map version of MapPickerScreen (web-compatible)
class MapPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;
  const MapPickerScreen({super.key, this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _picked;
  bool _showSatellite = true;

  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  static const List<_QuickSpot> _quickSpots = [
    _QuickSpot('東京', LatLng(35.6895, 139.6917)),
    _QuickSpot('大阪', LatLng(34.6937, 135.5023)),
    _QuickSpot('京都', LatLng(35.0116, 135.7681)),
    _QuickSpot('北海道', LatLng(43.0642, 141.3469)),
    _QuickSpot('沖縄', LatLng(26.2124, 127.6809)),
    _QuickSpot('富士山', LatLng(35.3606, 138.7274)),
    _QuickSpot('広島', LatLng(34.3963, 132.4596)),
    _QuickSpot('福岡', LatLng(33.5904, 130.4017)),
  ];

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchPlace(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(q)}'
        '&format=json&limit=1&accept-language=ja&countrycodes=jp',
      );
      final res = await http.get(url, headers: {'User-Agent': 'ShotMapApp/1.0'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'] as String);
          final lng = double.tryParse(data[0]['lon'] as String);
          if (lat != null && lng != null) {
            _mapController.move(LatLng(lat, lng), 15.0);
            _searchCtrl.clear();
            FocusScope.of(context).unfocus();
          }
        } else {
          _showSnack('場所が見つかりませんでした');
        }
      }
    } catch (_) {
      if (mounted) _showSnack('検索に失敗しました');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(fontSize: 13)),
      backgroundColor: AppColors.primaryDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onMapTap(LatLng latLng) {
    setState(() => _picked = latLng);
  }

  void _confirm() => Navigator.of(context).pop(_picked);
  void _cancel() => Navigator.of(context).pop(null);

  void _jumpTo(LatLng pos, {double zoom = 12.0}) {
    _mapController.move(pos, zoom);
  }

  String _formatLatLng(LatLng ll) {
    return 'N${ll.latitude.toStringAsFixed(5)}, E${ll.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = _showSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter ?? const LatLng(36.5, 137.0),
              initialZoom: 5.5,
              onTap: (_, latLng) => _onMapTap(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.shotmap.pins',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 50, height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(child: Text('📍', style: TextStyle(fontSize: 20))),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Map type toggle
          Positioned(
            right: 16, bottom: 220,
            child: GestureDetector(
              onTap: () => setState(() => _showSatellite = !_showSatellite),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Icon(_showSatellite ? Icons.map_outlined : Icons.satellite_alt, size: 22, color: AppColors.primary),
              ),
            ),
          ),

          // Header
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildStatusBar(),
                const SizedBox(height: 8),
                _buildQuickSpots(),
              ],
            ),
          ),

          // Center hint
          if (_picked == null)
            Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.touch_app, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('マップをタップしてピンを立てる', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ),

          // Bottom panel
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _cancel,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)]),
              child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)]),
              child: Row(children: [
                const SizedBox(width: 14),
                const Icon(Icons.search, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(fontSize: 13),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _searchPlace,
                    decoration: InputDecoration(hintText: '地名を入力してEnter...', hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint), border: InputBorder.none, fillColor: Colors.transparent, filled: false, contentPadding: EdgeInsets.zero),
                  ),
                ),
                if (_isSearching)
                  const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                else
                  GestureDetector(onTap: () => _searchPlace(_searchCtrl.text), child: const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.search, size: 20, color: AppColors.primary))),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(_picked == null ? 'マップをタップしてピンを選択' : 'ピン選択済み　再タップで移動', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuickSpots() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSpots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final spot = _quickSpots[i];
          return GestureDetector(
            onTap: () => _jumpTo(spot.latLng),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 4)]),
              child: Text(spot.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            if (_picked == null)
              _buildNoPinMessage()
            else
              _buildPickedInfo(_picked!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _picked == null ? null : _confirm,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.border, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_picked == null ? Icons.location_off : Icons.check_circle, size: 20, color: _picked == null ? AppColors.textHint : Colors.white),
                  const SizedBox(width: 8),
                  Text(_picked == null ? 'マップをタップして場所を選んでください' : 'この場所を投稿先に設定する', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _picked == null ? AppColors.textHint : Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildNoPinMessage() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primaryVeryLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryLight)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.3), shape: BoxShape.circle), child: const Icon(Icons.location_searching, size: 22, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('まだ場所が選択されていません', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text('マップ上の好きな場所をタップしてピンを立てましょう', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildPickedInfo(LatLng ll) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE3F4FC), Color(0xFFD0EBFA)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryLight)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]), child: const Icon(Icons.location_on, size: 24, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ピン位置を選択しました ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          const SizedBox(height: 3),
          Text(_formatLatLng(ll), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ])),
        GestureDetector(
          onTap: () => setState(() => _picked = null),
          child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary)),
        ),
      ]),
    );
  }
}

class _QuickSpot {
  final String name;
  final LatLng latLng;
  const _QuickSpot(this.name, this.latLng);
}
