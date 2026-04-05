import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';
import '../models/user_profile_provider.dart';
import '../widgets/ugc/report_block_sheet.dart';
import 'post_screen.dart';

// ── モバイル: Google Maps ──
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

// ── Web: flutter_map (OpenStreetMap) ──
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class MapScreen extends StatefulWidget {
  final MapScreenController? controller;
  const MapScreen({super.key, this.controller});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class MapScreenController {
  _MapScreenState? _state;
  void jumpTo(double lat, double lng) {
    _state?.jumpToLocation(lat, lng);
  }
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  SpotPin? _selectedPin;

  // Google Maps (モバイル)
  gmaps.GoogleMapController? _gMapController;

  // flutter_map (Web)
  final MapController _fMapController = MapController();

  bool _showSatellite = true;
  PinType? _pinTypeFilter;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void dispose() {
    _gMapController?.dispose();
    super.dispose();
  }

  List<SpotPin> get _filteredPins {
    return SampleData.pins.where((p) {
      return _pinTypeFilter == null || p.pinType == _pinTypeFilter;
    }).toList();
  }

  void _onPinTap(SpotPin pin) {
    setState(() {
      _selectedPin = _selectedPin?.id == pin.id ? null : pin;
    });
    if (_selectedPin != null) {
      if (kIsWeb) {
        _fMapController.move(ll.LatLng(pin.lat, pin.lng), 14.0);
      } else {
        _gMapController?.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(pin.lat, pin.lng), 14.0),
        );
      }
    }
  }

  Future<void> _openGoogleMapsNavigation(SpotPin pin) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${pin.lat},${pin.lng}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void jumpToLocation(double lat, double lng) {
    if (kIsWeb) {
      _fMapController.move(ll.LatLng(lat, lng), 14.0);
    } else {
      _gMapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), 14.0),
      );
    }
  }

  void _onPinTypeFilterChanged(PinType? type) {
    setState(() {
      _pinTypeFilter = type;
      _selectedPin = null;
    });
  }

  // ── Google Maps マーカー（モバイル用）──
  Set<gmaps.Marker> _buildGoogleMarkers() {
    return _filteredPins.map((pin) {
      final isSelected = _selectedPin?.id == pin.id;
      final hue = pin.pinType == PinType.sightseeing
          ? gmaps.BitmapDescriptor.hueRed
          : gmaps.BitmapDescriptor.hueBlue;
      return gmaps.Marker(
        markerId: gmaps.MarkerId(pin.id),
        position: gmaps.LatLng(pin.lat, pin.lng),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? gmaps.BitmapDescriptor.hueOrange : hue,
        ),
        onTap: () => _onPinTap(pin),
        zIndexInt: isSelected ? 2 : 1,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── マップ本体 ──
          kIsWeb ? _buildFlutterMap() : _buildGoogleMap(),

          // ── フィルターチップ ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildPinTypeFilterChips(),
              ],
            ),
          ),

          // ── ピン詳細カード ──
          if (_selectedPin != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildPinDetailCard(_selectedPin!),
            ),

          // ── 投稿ボタン（ピン未選択時） ──
          if (_selectedPin == null)
            Positioned(
              bottom: 24,
              right: 20,
              child: _buildPostButton(),
            ),

          // ── 現在地ボタン ──
          Positioned(
            bottom: _selectedPin == null ? 100 : 200,
            right: 20,
            child: _buildMyLocationButton(),
          ),

          // ── 衛星/地図切り替えボタン ──
          Positioned(
            bottom: _selectedPin == null ? 160 : 260,
            right: 20,
            child: _buildSatelliteToggle(),
          ),
        ],
      ),
    );
  }

  // ── Google Maps ウィジェット（iOS / Android）──
  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: const gmaps.CameraPosition(
        target: gmaps.LatLng(36.5, 137.0),
        zoom: 6.0,
      ),
      mapType: _showSatellite ? gmaps.MapType.satellite : gmaps.MapType.normal,
      markers: _buildGoogleMarkers(),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      onMapCreated: (c) => _gMapController = c,
      onTap: (_) {
        if (_selectedPin != null) setState(() => _selectedPin = null);
      },
    );
  }

  // ── flutter_map ウィジェット（Web プレビュー）──
  Widget _buildFlutterMap() {
    return FlutterMap(
      mapController: _fMapController,
      options: MapOptions(
        initialCenter: const ll.LatLng(36.5, 137.0),
        initialZoom: 6.0,
        onTap: (_, __) {
          if (_selectedPin != null) setState(() => _selectedPin = null);
        },
      ),
      children: [
        // タイルレイヤー（衛星 or 標準）
        TileLayer(
          urlTemplate: _showSatellite
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.shotmap.pins',
          maxZoom: 19,
        ),
        // ピンマーカー（元デザイン: 円形コンテナ＋絵文字）
        MarkerLayer(
          markers: _filteredPins.map((pin) {
            final isSelected = _selectedPin?.id == pin.id;
            return Marker(
              point: ll.LatLng(pin.lat, pin.lng),
              width: isSelected ? 48 : 38,
              height: isSelected ? 48 : 38,
              child: GestureDetector(
                onTap: () => _onPinTap(pin),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : (pin.pinType == PinType.sightseeing
                            ? const Color(0xFFE53935)
                            : const Color(0xFF1565C0)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE53935)
                          : Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      pin.pinType == PinType.sightseeing ? '🏔' : '🍴',
                      style: TextStyle(fontSize: isSelected ? 20 : 16),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSatelliteToggle() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showSatellite = !_showSatellite),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(
              _showSatellite ? Icons.map_outlined : Icons.satellite_alt,
              size: 20, color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
          child: Text(_showSatellite ? '地図' : '航空', style: const TextStyle(color: Colors.white, fontSize: 9)),
        ),
      ],
    );
  }

  Widget _buildPinTypeFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildPinTypeChip(null, '📍 両方', AppColors.primary),
          const SizedBox(width: 8),
          _buildPinTypeChip(PinType.sightseeing, '⛰️ 風景', const Color(0xFFE53935)),
          const SizedBox(width: 8),
          _buildPinTypeChip(PinType.gourmet, '🍴 グルメ', const Color(0xFF1565C0)),
        ],
      ),
    );
  }

  Widget _buildPinTypeChip(PinType? type, String label, Color color) {
    final isSelected = _pinTypeFilter == type;
    return GestureDetector(
      onTap: () => _onPinTypeFilterChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? color : color.withValues(alpha: 0.4), width: isSelected ? 0 : 1.5),
          boxShadow: [BoxShadow(
            color: isSelected ? color.withValues(alpha: 0.3) : AppColors.primaryDark.withValues(alpha: 0.08),
            blurRadius: isSelected ? 8 : 4, offset: const Offset(0, 2),
          )],
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : color)),
      ),
    );
  }

  Widget _buildPinDetailCard(SpotPin pin) {
    return Consumer<UserProfileProvider>(
      builder: (_, provider, __) {
        final isSaved = provider.isSavedPin(pin.id);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          pin.imageUrl,
                          width: 80, height: 80, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80, height: 80,
                            color: AppColors.primaryVeryLight,
                            child: const Icon(Icons.image, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pin.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: pin.pinType.lightColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: pin.pinType.color.withValues(alpha: 0.4)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: pin.pinType.color, shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text(pin.pinType.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pin.pinType.color)),
                              ]),
                            ),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                              const SizedBox(width: 2),
                              Text(pin.prefecture, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ]),
                            const SizedBox(height: 6),
                            Row(children: [
                              Expanded(
                                child: Wrap(spacing: 6, children: pin.tags.take(2).map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.tagBlue, borderRadius: BorderRadius.circular(8)),
                                  child: Text(tag, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                )).toList()),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  provider.toggleSavePin(pin);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(isSaved ? '保存を解除しました' : '保存しました ✓', style: const TextStyle(fontSize: 13)),
                                    backgroundColor: isSaved ? AppColors.textSecondary : AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  ));
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isSaved ? const Color(0xFFFFF3CD) : AppColors.primaryVeryLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSaved ? const Color(0xFFFFD700) : AppColors.primaryLight),
                                  ),
                                  child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, size: 18, color: isSaved ? const Color(0xFFFFAA00) : AppColors.primary),
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFEEF3F6)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text('シェア:', style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    _shareButton(icon: Icons.camera_alt, label: 'Instagram', color: const Color(0xFFDD2A7B), onTap: () => _shareToSns(pin, 'instagram')),
                    const SizedBox(width: 6),
                    _shareButton(icon: Icons.close, label: 'X', color: const Color(0xFF1A1A1A), onTap: () => _shareToSns(pin, 'x')),
                    const SizedBox(width: 6),
                    _shareButton(icon: Icons.link, label: 'コピー', color: AppColors.primary, onTap: () => _copyShareLink(pin)),
                  ]),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEEF3F6)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openGoogleMapsNavigation(pin),
                    child: Container(
                      width: double.infinity, height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.directions, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('経路・ナビ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -12, left: -8,
              child: GestureDetector(
                onTap: () => showReportBlockSheet(context, authorName: pin.authorName, postId: pin.id),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.more_horiz, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ),
            Positioned(
              top: -12, right: -8,
              child: GestureDetector(
                onTap: () => setState(() => _selectedPin = null),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shareButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Future<void> _shareToSns(SpotPin pin, String platform) async {
    const shotmapUrl = 'https://shotmap.app';
    if (platform == 'x') {
      final shareText = Uri.encodeComponent('📍 ${pin.title}\n${pin.prefecture}\n\nShotmapで発見しました！\n$shotmapUrl\n#shotmap #写真スポット');
      final uri = Uri.parse('https://twitter.com/intent/tweet?text=$shareText');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    _copyShareLink(pin);
  }

  void _copyShareLink(SpotPin pin) {
    const shotmapUrl = 'https://shotmap.app';
    final text = '📍 ${pin.title}（${pin.prefecture}）\n\nShotmapで発見しました！\n$shotmapUrl\n#shotmap #写真スポット';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Text('クリップボードにコピーしました', style: TextStyle(fontSize: 13)),
      ]),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildPostButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostScreen())),
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryLight, AppColors.primary]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return GestureDetector(
      onTap: () {
        if (kIsWeb) {
          _fMapController.move(const ll.LatLng(35.6762, 139.6503), 12.0);
        } else {
          _gMapController?.animateCamera(
            gmaps.CameraUpdate.newLatLngZoom(const gmaps.LatLng(35.6762, 139.6503), 12.0),
          );
        }
      },
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.my_location, color: AppColors.primary, size: 22),
      ),
    );
  }
}
