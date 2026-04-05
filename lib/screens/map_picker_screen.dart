import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

// ─── Google Maps / Places API キー ───
// ⚠️ 本番ビルド前に必ず実際のAPIキーに差し替えてください
// Google Cloud Console で以下を有効化：
//   Maps SDK for Android / Maps SDK for iOS / Maps JavaScript API / Places API (New)
const String _kMapsApiKey = 'AIzaSyB8bm3RjpQ29OAw92YZiyaT7t23jQQFoJA';

/// マップピッカー画面
/// ・Google Maps SDK（衛星表示デフォルト）
/// ・検索バー → Google Places Autocomplete API（日本語・日本優先）
/// ・マップタップで自由にピンを立てる
/// ・タップ位置でリバースジオコーディング → 名称・住所を自動取得
/// ・POIタップ → 名称・住所・座標を自動入力
class MapPickerScreen extends StatefulWidget {
  final LatLng? initialCenter;
  const MapPickerScreen({super.key, this.initialCenter});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _picked;
  bool _showSatellite = true;

  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  // ── Places Autocomplete 候補リスト ──
  List<_PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  // ── 選択済み場所情報 ──
  _PlaceDetail? _selectedPlace;

  // ── マーカー ──
  Set<Marker> _markers = {};

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
    _mapController?.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── Places Autocomplete（入力中にリアルタイム候補）───
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchAutocompleteSuggestions(q);
    });
  }

  Future<void> _fetchAutocompleteSuggestions(String query) async {
    if (_kMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      // APIキー未設定の場合はNominatimフォールバック
      await _fetchNominatimSuggestions(query);
      return;
    }
    try {
      // Places Autocomplete API (New) を使用
      // 日本語・日本エリア優先
      final currentCenter = _picked ??
          widget.initialCenter ??
          const LatLng(35.6895, 139.6917);
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&language=ja'
        '&region=jp'
        '&location=${currentCenter.latitude},${currentCenter.longitude}'
        '&radius=50000'
        '&key=$_kMapsApiKey',
      );
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final predictions = (data['predictions'] as List).cast<Map<String, dynamic>>();
          setState(() {
            _suggestions = predictions.map((p) => _PlaceSuggestion(
              placeId: p['place_id'] as String? ?? '',
              mainText: (p['structured_formatting']?['main_text'] as String?) ?? (p['description'] as String? ?? ''),
              secondaryText: (p['structured_formatting']?['secondary_text'] as String?) ?? '',
              description: p['description'] as String? ?? '',
            )).toList();
            _showSuggestions = _suggestions.isNotEmpty;
          });
        }
      }
    } catch (_) {
      // Places API 失敗時はNominatimにフォールバック
      await _fetchNominatimSuggestions(query);
    }
  }

  // フォールバック: Nominatim（APIキー不要）
  Future<void> _fetchNominatimSuggestions(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=8&accept-language=ja&countrycodes=jp&addressdetails=1',
      );
      final res = await http.get(url, headers: {'User-Agent': 'ShotMapApp/1.0'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _suggestions = data.map((item) {
            final displayName = item['display_name'] as String? ?? '';
            final parts = displayName.split(',');
            final main = parts.isNotEmpty ? parts[0].trim() : displayName;
            final secondary = parts.length > 1 ? parts.sublist(1).take(2).map((s) => s.trim()).join(', ') : '';
            return _PlaceSuggestion(
              placeId: '', // Nominatimにはplace_idなし
              mainText: main,
              secondaryText: secondary,
              description: displayName,
              lat: double.tryParse(item['lat'] as String? ?? ''),
              lng: double.tryParse(item['lon'] as String? ?? ''),
            );
          }).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {
      // 無視
    }
  }

  // ─── Places Detail 取得（place_idから座標・住所を取得）───
  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _isSearching = true;
    });
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();

    // Nominatimフォールバックの場合は既に座標がある
    if (suggestion.lat != null && suggestion.lng != null) {
      final latlng = LatLng(suggestion.lat!, suggestion.lng!);
      _placePin(latlng, detail: _PlaceDetail(
        name: suggestion.mainText,
        address: suggestion.description,
        lat: suggestion.lat!,
        lng: suggestion.lng!,
      ));
      setState(() => _isSearching = false);
      return;
    }

    if (_kMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY' || suggestion.placeId.isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${suggestion.placeId}'
        '&fields=name,formatted_address,geometry'
        '&language=ja'
        '&key=$_kMapsApiKey',
      );
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK') {
          final result = data['result'] as Map<String, dynamic>;
          final loc = result['geometry']['location'];
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final name = result['name'] as String? ?? suggestion.mainText;
          final address = result['formatted_address'] as String? ?? suggestion.description;
          _placePin(LatLng(lat, lng), detail: _PlaceDetail(
            name: name,
            address: address,
            lat: lat,
            lng: lng,
          ));
        }
      }
    } catch (_) {
      if (mounted) _showSnack('場所の詳細を取得できませんでした');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ─── マップタップ → リバースジオコーディング ───
  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _showSuggestions = false;
    });
    FocusScope.of(context).unfocus();
    _placePin(latLng);
    // バックグラウンドでリバースジオコーディング
    _reverseGeocode(latLng);
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (_kMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      // Nominatimフォールバック
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse'
          '?lat=${latLng.latitude}&lon=${latLng.longitude}'
          '&format=json&accept-language=ja&zoom=18&addressdetails=1',
        );
        final res = await http.get(url, headers: {'User-Agent': 'ShotMapApp/1.0'});
        if (!mounted) return;
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is Map && data['display_name'] != null) {
            final name = (data['display_name'] as String).split(',').first.trim();
            final address = data['display_name'] as String;
            setState(() {
              _selectedPlace = _PlaceDetail(
                name: name,
                address: address,
                lat: latLng.latitude,
                lng: latLng.longitude,
              );
            });
          }
        }
      } catch (_) {}
      return;
    }
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${latLng.latitude},${latLng.longitude}'
        '&language=ja'
        '&region=jp'
        '&key=$_kMapsApiKey',
      );
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final first = results[0] as Map<String, dynamic>;
            final components = first['address_components'] as List;
            // 場所名 = 最初のコンポーネント
            final name = (components.isNotEmpty)
                ? (components[0]['long_name'] as String? ?? '')
                : '';
            final address = first['formatted_address'] as String? ?? '';
            setState(() {
              _selectedPlace = _PlaceDetail(
                name: name,
                address: address,
                lat: latLng.latitude,
                lng: latLng.longitude,
              );
            });
          }
        }
      }
    } catch (_) {}
  }

  void _placePin(LatLng latLng, {_PlaceDetail? detail}) {
    setState(() {
      _picked = latLng;
      _selectedPlace = detail;
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      };
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 16.0),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
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
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, zoom));
  }

  String _formatLatLng(LatLng ll) {
    return 'N${ll.latitude.toStringAsFixed(5)}, E${ll.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialCenter ?? const LatLng(36.5, 137.0),
              zoom: 5.5,
            ),
            mapType: _showSatellite ? MapType.satellite : MapType.normal,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
          ),

          // ── 衛星/地図切り替えボタン ──
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

          // ── ヘッダー（検索バー + クイックスポット） ──
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

          // ── 検索候補ドロップダウン ──
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 62, right: 12,
              child: _buildSuggestionsList(),
            ),

          // ── 中央ヒント（ピン未選択時） ──
          if (_picked == null && !_showSuggestions)
            Center(
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('マップをタップしてピンを立てる', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ),
              ),
            ),

          // ── ボトムパネル ──
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
                    style: const TextStyle(fontSize: 13),
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: (v) {
                      if (_suggestions.isNotEmpty) {
                        _selectSuggestion(_suggestions.first);
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: '場所・施設・住所を検索...',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                else if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _suggestions = [];
                        _showSuggestions = false;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.clear, size: 18, color: AppColors.textHint),
                    ),
                  )
                else
                  const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.search, size: 20, color: AppColors.primary)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border, indent: 56),
          itemBuilder: (_, i) {
            final s = _suggestions[i];
            return ListTile(
              dense: true,
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.place, size: 18, color: AppColors.primary),
              ),
              title: Text(
                s.mainText,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: s.secondaryText.isNotEmpty
                  ? Text(
                      s.secondaryText,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryVeryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('選択', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              onTap: () => _selectSuggestion(s),
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
            Text(
              _picked == null ? 'マップをタップしてピンを選択' : 'ピン選択済み　再タップで移動',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
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
              child: Text(spot.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_picked == null ? Icons.location_off : Icons.check_circle, size: 20, color: _picked == null ? AppColors.textHint : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _picked == null ? 'マップをタップして場所を選んでください' : 'この場所を投稿先に設定する',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _picked == null ? AppColors.textHint : Colors.white),
                  ),
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
          const Text('まだ場所が選択されていません', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Text('マップ上の好きな場所をタップするか、\n検索バーで場所・施設名を検索してください', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildPickedInfo(LatLng ll) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE3F4FC), Color(0xFFD0EBFA)]), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primaryLight)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]),
          child: const Icon(Icons.location_on, size: 24, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_selectedPlace != null && _selectedPlace!.name.isNotEmpty) ...[
            Text(_selectedPlace!.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_selectedPlace!.address.isNotEmpty)
              Text(_selectedPlace!.address, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_formatLatLng(ll), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ] else ...[
            const Text('ピン位置を選択しました ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
            const SizedBox(height: 3),
            Text(_formatLatLng(ll), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ])),
        GestureDetector(
          onTap: () => setState(() {
            _picked = null;
            _selectedPlace = null;
            _markers = {};
          }),
          child: Container(width: 28, height: 28, decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: AppColors.textSecondary)),
        ),
      ]),
    );
  }
}

// ─── データモデル ───
class _QuickSpot {
  final String name;
  final LatLng latLng;
  const _QuickSpot(this.name, this.latLng);
}

class _PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;
  final double? lat; // Nominatimフォールバック用
  final double? lng;

  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
    this.lat,
    this.lng,
  });
}

class _PlaceDetail {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const _PlaceDetail({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}
