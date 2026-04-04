import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

/// マップピッカー画面
/// ・マップタップで自由にピンを立てる
/// ・検索バーで地名検索 → ジャンプ
/// ・Nominatim 逆ジオコーディングで既存の場所・お店を候補表示し選択可能
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

  // ── 周辺POI候補 ──
  List<_PlaceResult> _nearbyPlaces = [];
  bool _loadingNearby = false;
  _PlaceResult? _selectedPlace; // POIから選んだ場合

  // ── 検索候補リスト ──
  List<_PlaceResult> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ─── 場所テキスト検索（Enter確定） ───
  Future<void> _searchPlace(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() {
      _isSearching = true;
      _showSearchResults = false;
    });
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

  // ─── インクリメンタル検索（入力中にリアルタイム候補表示） ───
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSearchSuggestions(q);
    });
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=8&accept-language=ja&countrycodes=jp'
        '&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'ShotMapApp/1.0'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        final results = data.map((item) {
          final lat = double.tryParse(item['lat'] as String) ?? 0;
          final lng = double.tryParse(item['lon'] as String) ?? 0;
          final name = item['display_name'] as String? ?? '';
          final type = item['type'] as String? ?? '';
          final category = item['class'] as String? ?? '';
          return _PlaceResult(
            name: _shortenDisplayName(name),
            fullName: name,
            lat: lat,
            lng: lng,
            type: type,
            category: category,
          );
        }).toList();
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
        });
      }
    } catch (_) {
      // 検索候補取得失敗は無視
    }
  }

  /// 長すぎる表示名を短縮
  String _shortenDisplayName(String name) {
    final parts = name.split(',');
    if (parts.length <= 2) return name;
    // 最初の2パートだけ表示
    return '${parts[0].trim()}, ${parts[1].trim()}';
  }

  // ─── マップタップ時に周辺POI取得 ───
  void _onMapTap(LatLng latLng) {
    setState(() {
      _picked = latLng;
      _selectedPlace = null;
      _showSearchResults = false;
    });
    FocusScope.of(context).unfocus();
    _fetchNearbyPlaces(latLng);
  }

  /// Nominatim 逆ジオコーディング + 周辺検索で、タップ地点付近のPOI候補を取得
  Future<void> _fetchNearbyPlaces(LatLng center) async {
    setState(() {
      _loadingNearby = true;
      _nearbyPlaces = [];
    });

    try {
      // 1. 逆ジオコーディング（タップ地点の住所）
      final reverseUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${center.latitude}&lon=${center.longitude}'
        '&format=json&accept-language=ja&zoom=18&addressdetails=1',
      );
      final reverseRes = await http.get(reverseUrl, headers: {'User-Agent': 'ShotMapApp/1.0'});

      // 2. 周辺のPOI検索 (amenity, tourism, shop, leisure)
      // Nominatim search で viewbox を使い範囲内のPOIを取得
      final delta = 0.005; // 約500m四方

      // amenity/tourism/shop カテゴリ別に小さいクエリ
      final poiUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&limit=10&accept-language=ja'
        '&viewbox=${center.longitude - delta},${center.latitude + delta},'
        '${center.longitude + delta},${center.latitude - delta}'
        '&bounded=1'
        '&addressdetails=1',
      );

      final futures = await Future.wait([
        reverseRes.statusCode == 200 ? Future.value(reverseRes) : http.get(reverseUrl, headers: {'User-Agent': 'ShotMapApp/1.0'}),
        http.get(poiUrl, headers: {'User-Agent': 'ShotMapApp/1.0'}),
      ]);

      if (!mounted) return;

      final List<_PlaceResult> places = [];

      // 逆ジオコーディング結果
      if (futures[0].statusCode == 200) {
        final revData = jsonDecode(futures[0].body);
        if (revData is Map && revData['display_name'] != null) {
          final name = revData['display_name'] as String;
          final lat = double.tryParse(revData['lat']?.toString() ?? '') ?? center.latitude;
          final lng = double.tryParse(revData['lon']?.toString() ?? '') ?? center.longitude;
          final type = revData['type'] as String? ?? '';
          final category = revData['class'] as String? ?? '';
          places.add(_PlaceResult(
            name: _shortenDisplayName(name),
            fullName: name,
            lat: lat,
            lng: lng,
            type: type,
            category: category,
            isReverseGeocode: true,
          ));
        }
      }

      // 周辺POI検索結果
      if (futures[1].statusCode == 200) {
        final poiData = jsonDecode(futures[1].body) as List;
        for (final item in poiData) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0;
          final lng = double.tryParse(item['lon']?.toString() ?? '') ?? 0;
          final name = item['display_name'] as String? ?? '';
          final type = item['type'] as String? ?? '';
          final category = item['class'] as String? ?? '';
          // 重複排除（逆ジオコーディングと同じ場所は除く）
          if (places.isNotEmpty &&
              (places[0].lat - lat).abs() < 0.0001 &&
              (places[0].lng - lng).abs() < 0.0001) {
            continue;
          }
          places.add(_PlaceResult(
            name: _shortenDisplayName(name),
            fullName: name,
            lat: lat,
            lng: lng,
            type: type,
            category: category,
          ));
        }
      }

      setState(() {
        _nearbyPlaces = places.take(6).toList();
        _loadingNearby = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _nearbyPlaces = [];
          _loadingNearby = false;
        });
      }
    }
  }

  void _selectPlace(_PlaceResult place) {
    setState(() {
      _picked = LatLng(place.lat, place.lng);
      _selectedPlace = place;
    });
    _mapController.move(LatLng(place.lat, place.lng), 17.0);
  }

  void _selectSearchResult(_PlaceResult place) {
    setState(() {
      _picked = LatLng(place.lat, place.lng);
      _selectedPlace = place;
      _showSearchResults = false;
      _searchResults = [];
    });
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    _mapController.move(LatLng(place.lat, place.lng), 17.0);
    _fetchNearbyPlaces(LatLng(place.lat, place.lng));
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

  void _confirm() => Navigator.of(context).pop(_picked);
  void _cancel() => Navigator.of(context).pop(null);

  void _jumpTo(LatLng pos, {double zoom = 12.0}) {
    _mapController.move(pos, zoom);
  }

  String _formatLatLng(LatLng ll) {
    return 'N${ll.latitude.toStringAsFixed(5)}, E${ll.longitude.toStringAsFixed(5)}';
  }

  IconData _placeIcon(String category, String type) {
    if (category == 'amenity') {
      if (type == 'restaurant' || type == 'fast_food' || type == 'cafe') return Icons.restaurant;
      if (type == 'bar' || type == 'pub') return Icons.local_bar;
      if (type == 'hospital' || type == 'clinic') return Icons.local_hospital;
      if (type == 'school' || type == 'university') return Icons.school;
      if (type == 'parking') return Icons.local_parking;
      if (type == 'fuel') return Icons.local_gas_station;
      return Icons.place;
    }
    if (category == 'tourism') {
      if (type == 'hotel' || type == 'guest_house') return Icons.hotel;
      if (type == 'museum') return Icons.museum;
      if (type == 'attraction' || type == 'viewpoint') return Icons.landscape;
      return Icons.tour;
    }
    if (category == 'shop') return Icons.store;
    if (category == 'leisure') return Icons.park;
    if (category == 'highway') return Icons.directions;
    if (category == 'building') return Icons.apartment;
    if (category == 'railway') return Icons.train;
    return Icons.location_on;
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
              // 周辺POIマーカー（小さいグレー丸）
              if (_nearbyPlaces.isNotEmpty && _picked != null)
                MarkerLayer(
                  markers: _nearbyPlaces
                      .where((p) => !p.isReverseGeocode)
                      .map((place) {
                    final isSelected = _selectedPlace == place;
                    return Marker(
                      point: LatLng(place.lat, place.lng),
                      width: isSelected ? 44 : 36,
                      height: isSelected ? 44 : 36,
                      child: GestureDetector(
                        onTap: () => _selectPlace(place),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : AppColors.primary,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _placeIcon(place.category, place.type),
                              size: isSelected ? 20 : 16,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // メインピン（選択中）
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

          // 検索候補ドロップダウン
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 62, right: 12,
              child: _buildSearchResultsList(),
            ),

          // Center hint
          if (_picked == null && !_showSearchResults)
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
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: '場所・お店の名前を検索...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _searchResults = [];
                        _showSearchResults = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.clear, size: 18, color: AppColors.textHint),
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

  /// 検索結果候補リスト
  Widget _buildSearchResultsList() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _searchResults.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border, indent: 56),
          itemBuilder: (_, i) {
            final place = _searchResults[i];
            return ListTile(
              dense: true,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _placeIcon(place.category, place.type),
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                place.name,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                place.fullName,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryVeryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '選択',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              onTap: () => _selectSearchResult(place),
            );
          },
        ),
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

            // 周辺POI候補
            if (_picked != null && (_nearbyPlaces.isNotEmpty || _loadingNearby)) ...[
              const SizedBox(height: 12),
              _buildNearbyPlacesSection(),
            ],

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

  /// 周辺POI候補セクション
  Widget _buildNearbyPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.store, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 5),
            Text(
              'この付近の場所・お店',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
            ),
            const Spacer(),
            if (_loadingNearby)
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_nearbyPlaces.isEmpty && !_loadingNearby)
          Text(
            '付近に登録された場所が見つかりませんでした',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyPlaces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final place = _nearbyPlaces[i];
                final isSelected = _selectedPlace == place;
                return GestureDetector(
                  onTap: () => _selectPlace(place),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                          : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _placeIcon(place.category, place.type),
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Text(
                            place.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.check_circle, size: 14, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
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
          Text('マップ上の好きな場所をタップするか、\n検索バーで場所・お店を検索してください', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
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
          if (_selectedPlace != null) ...[
            Text(_selectedPlace!.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(_formatLatLng(ll), style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ] else ...[
            Text('ピン位置を選択しました ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            const SizedBox(height: 3),
            Text(_formatLatLng(ll), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ])),
        GestureDetector(
          onTap: () => setState(() {
            _picked = null;
            _selectedPlace = null;
            _nearbyPlaces = [];
          }),
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

class _PlaceResult {
  final String name;
  final String fullName;
  final double lat;
  final double lng;
  final String type;
  final String category;
  final bool isReverseGeocode;

  const _PlaceResult({
    required this.name,
    required this.fullName,
    required this.lat,
    required this.lng,
    required this.type,
    required this.category,
    this.isReverseGeocode = false,
  });
}
