// ignore_for_file: unused_field, dangling_library_doc_comments, unused_import
/// iOS / Android 用 MapPicker の実装（google_maps_flutter）
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;
import '../theme/app_theme.dart';
import '../models/data_models.dart';

// ──────────────────────────────────────────────────────────────────────────────
//  MapPickerMobile
// ──────────────────────────────────────────────────────────────────────────────
class MapPickerMobile extends StatefulWidget {
  final ll.LatLng? initialCenter;
  const MapPickerMobile({super.key, this.initialCenter});

  @override
  State<MapPickerMobile> createState() => _MapPickerMobileState();
}

class _MapPickerMobileState extends State<MapPickerMobile> {
  // ── State ──────────────────────────────────────────────────────────
  GoogleMapController? _ctrl;
  Set<Marker> _markers = {};
  MapType _mapType = MapType.satellite;

  ll.LatLng? _picked;
  String _pickedName     = '';
  String _pickedAddress  = '';
  String _pickedCategory = '';   // POI カテゴリ（例: レストラン、コンビニ）
  bool   _isFetchingPOI  = false; // Nearby Search / Place Detail のローディング

  ll.LatLng? _customPin;
  String _customPinAddress = '';
  bool _isGeocoding    = false;   // 長押し用 逆ジオコーディング
  bool _showCustomInput = false;

  final TextEditingController _searchCtrl     = TextEditingController();
  final TextEditingController _customNameCtrl = TextEditingController();

  List<_Sug> _suggestions     = [];
  bool       _showSuggestions = false;
  Timer?     _debounce;

  static const String _apiKey = 'AIzaSyB8bm3RjpQ29OAw92YZiyaT7t23jQQFoJA';

  static const List<_QS> _quickSpots = [
    _QS('東京', 35.6895, 139.6917), _QS('大阪', 34.6937, 135.5023),
    _QS('京都', 35.0116, 135.7681), _QS('北海道', 43.0642, 141.3469),
    _QS('沖縄', 26.2124, 127.6809), _QS('富士山', 35.3606, 138.7274),
    _QS('広島', 34.3963, 132.4596), _QS('福岡', 33.5904, 130.4017),
  ];

  @override
  void dispose() {
    _ctrl?.dispose();
    _searchCtrl.dispose();
    _customNameCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── 検索（Places Autocomplete）──────────────────────────────────
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    q = q.trim();
    if (q.length < 2) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 420), () => _autoComplete(q));
  }

  Future<void> _autoComplete(String q) async {
    try {
      final center = _picked ?? (widget.initialCenter ?? const ll.LatLng(35.6895, 139.6917));
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(q)}'
        '&language=ja&region=jp'
        '&location=${center.latitude},${center.longitude}&radius=50000'
        '&key=$_apiKey',
      );
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final preds = (jsonDecode(res.body)['predictions'] as List?) ?? [];
        setState(() {
          _suggestions = preds.map((p) => _Sug(
            placeId: p['place_id'] as String? ?? '',
            main: (p['structured_formatting']?['main_text'] as String?)
                ?? p['description'] as String? ?? '',
            sub: (p['structured_formatting']?['secondary_text'] as String?) ?? '',
          )).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {
      // fallback Nominatim
      await _nominatim(q);
    }
  }

  Future<void> _nominatim(String q) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(q)}'
        '&format=json&limit=6&accept-language=ja&countrycodes=jp',
      );
      final res = await http.get(url, headers: {'User-Agent': 'ShotMapApp/1.0'});
      if (!mounted) return;
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _suggestions = list.map((it) {
            final parts = (it['display_name'] as String? ?? '').split(',');
            return _Sug(
              placeId: '',
              main: parts[0].trim(),
              sub: parts.length > 1
                  ? parts.sublist(1).take(2).map((s) => s.trim()).join(', ')
                  : '',
              lat: double.tryParse(it['lat'] as String? ?? '') ?? 0,
              lng: double.tryParse(it['lon'] as String? ?? '') ?? 0,
            );
          }).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _selectSug(_Sug s) async {
    setState(() { _suggestions = []; _showSuggestions = false; });
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();

    if (s.placeId.isNotEmpty) {
      await _placeDetail(s.placeId, fallbackName: s.main);
    } else if (s.lat != null) {
      _setPicked(ll.LatLng(s.lat!, s.lng!), name: s.main, address: s.sub);
    }
  }

  // ── Places Detail（name, address, types 取得）────────────────────
  Future<void> _placeDetail(String id, {String fallbackName = ''}) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$id'
        '&fields=name,formatted_address,geometry,types'
        '&language=ja&key=$_apiKey',
      );
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final r = (jsonDecode(res.body)['result'] as Map<String, dynamic>?) ?? {};
        final lat = (r['geometry']?['location']?['lat'] as num?)?.toDouble() ?? 0;
        final lng = (r['geometry']?['location']?['lng'] as num?)?.toDouble() ?? 0;
        final types = (r['types'] as List?)?.cast<String>() ?? [];
        final category = _categoryLabel(types);
        _setPicked(
          ll.LatLng(lat, lng),
          name: r['name'] as String? ?? fallbackName,
          address: r['formatted_address'] as String? ?? '',
          category: category,
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetchingPOI = false);
  }

  // ── Google Place types → 日本語カテゴリ ──────────────────────────
  String _categoryLabel(List<String> types) {
    const Map<String, String> map = {
      'restaurant': 'レストラン', 'food': '飲食店',
      'cafe': 'カフェ', 'bar': 'バー', 'bakery': 'ベーカリー',
      'meal_takeaway': 'テイクアウト', 'meal_delivery': 'デリバリー',
      'convenience_store': 'コンビニ', 'supermarket': 'スーパー',
      'grocery_or_supermarket': 'スーパー', 'drugstore': 'ドラッグストア',
      'pharmacy': '薬局', 'department_store': 'デパート',
      'shopping_mall': 'ショッピングモール', 'clothing_store': 'アパレル',
      'electronics_store': '家電', 'book_store': '書店',
      'tourist_attraction': '観光スポット', 'museum': '博物館・美術館',
      'park': '公園', 'amusement_park': '遊園地',
      'zoo': '動物園', 'aquarium': '水族館',
      'stadium': 'スタジアム', 'movie_theater': '映画館',
      'night_club': 'ナイトクラブ', 'casino': 'カジノ',
      'lodging': 'ホテル・宿泊', 'hotel': 'ホテル',
      'hospital': '病院', 'doctor': 'クリニック', 'dentist': '歯科',
      'bank': '銀行', 'atm': 'ATM', 'insurance_agency': '保険',
      'gas_station': 'ガソリンスタンド', 'car_dealer': '自動車販売',
      'car_repair': '自動車修理', 'car_wash': '洗車',
      'parking': '駐車場', 'subway_station': '地下鉄駅',
      'train_station': '鉄道駅', 'bus_station': 'バス停',
      'airport': '空港', 'taxi_stand': 'タクシー乗り場',
      'school': '学校', 'university': '大学',
      'library': '図書館', 'post_office': '郵便局',
      'city_hall': '市役所', 'courthouse': '裁判所',
      'police': '警察', 'fire_station': '消防署',
      'church': '教会', 'mosque': 'モスク', 'synagogue': 'シナゴーグ',
      'hindu_temple': 'ヒンドゥー寺院', 'place_of_worship': '宗教施設',
      'gym': 'ジム', 'spa': 'スパ', 'beauty_salon': '美容院',
      'hair_care': 'ヘアケア', 'laundry': 'コインランドリー',
      'veterinary_care': '動物病院', 'florist': '花屋',
      'jewelry_store': 'ジュエリー', 'pet_store': 'ペットショップ',
      'home_goods_store': 'ホームグッズ', 'hardware_store': 'ホームセンター',
      'furniture_store': '家具店', 'art_gallery': 'ギャラリー',
      'campground': 'キャンプ場', 'rv_park': 'RVパーク',
      'natural_feature': '自然名所', 'premise': '施設',
      'establishment': '施設',
    };
    for (final t in types) {
      if (map.containsKey(t)) return map[t]!;
    }
    return '';
  }

  // ── 逆ジオコーディング ─────────────────────────────────────────
  Future<void> _reverseGeocode(ll.LatLng pos) async {
    setState(() => _isGeocoding = true);
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${pos.latitude},${pos.longitude}&language=ja&key=$_apiKey',
      );
      final res = await http.get(url);
      if (mounted && res.statusCode == 200) {
        final results = (jsonDecode(res.body)['results'] as List?) ?? [];
        if (results.isNotEmpty) {
          final addr = results[0]['formatted_address'] as String? ?? '';
          final name = (results[0]['address_components'] as List?)
              ?.firstWhere((c) => (c['types'] as List).contains('establishment'),
                  orElse: () => null)?['long_name'] as String? ?? '';
          if (mounted) {
            setState(() {
              if (_showCustomInput) {
                _customPinAddress = addr;
                if (name.isNotEmpty && _customNameCtrl.text.isEmpty) {
                  _customNameCtrl.text = name;
                }
              } else {
                _pickedAddress = addr;
              }
              _isGeocoding = false;
            });
          }
          return;
        }
      }
    } catch (_) {}
    // Nominatim fallback
    await _nominatimReverse(pos);
  }

  Future<void> _nominatimReverse(ll.LatLng pos) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json&accept-language=ja&zoom=18',
      );
      final res = await http.get(url, headers: {'User-Agent': 'ShotMapApp/1.0'});
      if (mounted && res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        String address = '';
        for (final k in ['state','city','town','village','suburb','neighbourhood','road']) {
          final v = addr[k] as String?;
          if (v != null) address += v;
        }
        if (address.isEmpty) {
          address = (data['display_name'] as String? ?? '')
              .split(',').take(3).map((s) => s.trim()).join(', ');
        }
        final nm = addr['name'] as String? ?? '';
        if (mounted) {
          setState(() {
            if (_showCustomInput) {
              _customPinAddress = address;
              if (nm.isNotEmpty && _customNameCtrl.text.isEmpty) {
                _customNameCtrl.text = nm;
              }
            } else {
              _pickedAddress = address;
            }
            _isGeocoding = false;
          });
        }
      } else {
        if (mounted) setState(() => _isGeocoding = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  // ── 座標確定 ──────────────────────────────────────────────────
  void _setPicked(ll.LatLng pos,
      {String name = '', String address = '', String category = ''}) {
    setState(() {
      _picked          = pos;
      _pickedName      = name;
      _pickedAddress   = address;
      _pickedCategory  = category;
      _customPin       = null;
      _customPinAddress = '';
      _showCustomInput = false;
      _isFetchingPOI   = false;
      _customNameCtrl.clear();
    });
    _ctrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15.0));
    _setMarker(pos, name: name, isCustom: false);
  }

  // ── 長押しでカスタムピン ────────────────────────────────────
  Future<void> _onLongPress(LatLng gmPos) async {
    FocusScope.of(context).unfocus();
    final pos = ll.LatLng(gmPos.latitude, gmPos.longitude);
    setState(() {
      _customPin        = pos;
      _picked           = pos;
      _pickedName       = '';
      _pickedAddress    = '';
      _customPinAddress = '';
      _showCustomInput  = true;
      _customNameCtrl.clear();
    });
    _setMarker(pos, name: '', isCustom: true);
    await _reverseGeocode(pos);
  }

  // ── タップ時: 近くのPOIを検索 ─────────────────────────────
  Future<void> _onMapTap(LatLng gmPos) async {
    if (_showSuggestions) {
      setState(() => _showSuggestions = false);
      return;
    }
    // タップ地点の近くにPOIがあれば取得（Nearby Search）
    await _fetchNearbyPOI(ll.LatLng(gmPos.latitude, gmPos.longitude));
  }

  Future<void> _fetchNearbyPOI(ll.LatLng pos) async {
    // ローディング開始
    setState(() {
      _isFetchingPOI   = true;
      _picked          = null;
      _pickedName      = '';
      _pickedAddress   = '';
      _pickedCategory  = '';
      _customPin       = null;
      _showCustomInput = false;
    });
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${pos.latitude},${pos.longitude}'
        '&radius=50&language=ja&rankby=distance&key=$_apiKey',
      );
      final res = await http.get(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final results = (jsonDecode(res.body)['results'] as List?) ?? [];
        if (results.isNotEmpty) {
          final place   = results[0] as Map<String, dynamic>;
          final placeId = place['place_id'] as String? ?? '';
          final name    = place['name']     as String? ?? '';
          final vicinity = place['vicinity'] as String? ?? '';
          final types   = (place['types'] as List?)?.cast<String>() ?? [];
          final lat = (place['geometry']?['location']?['lat'] as num?)?.toDouble()
              ?? pos.latitude;
          final lng = (place['geometry']?['location']?['lng'] as num?)?.toDouble()
              ?? pos.longitude;
          final pPos = ll.LatLng(lat, lng);

          // 仮セット（vicinity + types で即カード表示）
          setState(() {
            _picked         = pPos;
            _pickedName     = name;
            _pickedAddress  = vicinity;
            _pickedCategory = _categoryLabel(types);
            _customPin      = null;
            _showCustomInput = false;
            // _isFetchingPOI は true のまま → Place Detail 取得中を示す
          });
          _setMarker(pPos, name: name, isCustom: false);

          // Place Detail で正確な住所・カテゴリを上書き（_isFetchingPOI を落とす）
          if (placeId.isNotEmpty) {
            await _placeDetail(placeId, fallbackName: name);
          } else {
            if (mounted) setState(() => _isFetchingPOI = false);
          }
          return;
        }
      }
    } catch (_) {}

    // ─ POI なし：タップ地点に汎用ピンを立て、逆ジオコーディングで住所取得 ─
    setState(() {
      _picked          = pos;
      _pickedName      = '';
      _pickedAddress   = '';
      _pickedCategory  = '';
      _isFetchingPOI   = false;
      _customPin       = null;
      _showCustomInput = false;
    });
    _setMarker(pos, name: '', isCustom: false);
    await _reverseGeocode(pos);
  }

  void _setMarker(ll.LatLng pos, {required String name, required bool isCustom}) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('sel'),
          position: LatLng(pos.latitude, pos.longitude),
          infoWindow: InfoWindow(title: name.isNotEmpty ? name : '選択した場所'),
          icon: isCustom
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
    _ctrl?.showMarkerInfoWindow(const MarkerId('sel'));
  }

  void _resetPin() {
    setState(() {
      _picked           = null;
      _pickedName       = '';
      _pickedAddress    = '';
      _pickedCategory   = '';
      _isFetchingPOI    = false;
      _customPin        = null;
      _customPinAddress = '';
      _showCustomInput  = false;
      _customNameCtrl.clear();
      _markers          = {};
    });
  }

  void _confirm() {
    if (_customPin != null && _customNameCtrl.text.trim().isNotEmpty) {
      _pickedName = _customNameCtrl.text.trim();
    }
    Navigator.of(context).pop(_picked);
  }

  void _cancel() => Navigator.of(context).pop(null);

  String _fmt(ll.LatLng p) =>
      'N${p.latitude.toStringAsFixed(5)}, E${p.longitude.toStringAsFixed(5)}';

  // ── build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final initPos = widget.initialCenter != null
        ? LatLng(widget.initialCenter!.latitude, widget.initialCenter!.longitude)
        : const LatLng(36.5, 137.0);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        // ── Google Map ────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initPos, zoom: 6.0),
          mapType: _mapType,
          markers: _markers,
          onMapCreated: (c) => _ctrl = c,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: false,
          onLongPress: _onLongPress,
          onTap: _onMapTap,
        ),

        // ── ヘッダー ──────────────────────────────────────────
        SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildHeader(),
            const SizedBox(height: 6),
            _buildHint(),
            const SizedBox(height: 6),
            _buildQuickSpots(),
          ]),
        ),

        // ── 検索候補 ──────────────────────────────────────────
        if (_showSuggestions && _suggestions.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            left: 60, right: 12,
            child: _buildSugList(),
          ),

        // ── 現在地ボタン ──────────────────────────────────────
        Positioned(
          right: 16,
          bottom: _showCustomInput ? 330 : 270,
          child: _myLocBtn(),
        ),

        // ── ボトムパネル ──────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottom()),
      ]),
    );
  }

  // ── ヘッダー ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // 戻るボタン
        GestureDetector(
          onTap: _cancel,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        // 検索バー
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
            ),
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
                    if (_suggestions.isNotEmpty) _selectSug(_suggestions.first);
                  },
                  decoration: const InputDecoration(
                    hintText: '場所・住所・施設名を検索...',
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
                    setState(() { _suggestions = []; _showSuggestions = false; });
                  },
                  child: const Padding(padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.clear, size: 18, color: AppColors.textHint)),
                )
              else
                const Padding(padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.search, size: 20, color: AppColors.primary)),
            ]),
          ),
        ),
        // 衛星/地図 切替
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() =>
              _mapType = _mapType == MapType.satellite ? MapType.normal : MapType.satellite),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
            ),
            child: Icon(
              _mapType == MapType.satellite ? Icons.map_outlined : Icons.satellite_alt,
              size: 20, color: AppColors.primary,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHint() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app, color: Colors.white, size: 13),
            SizedBox(width: 5),
            Text('ピンをタップで選択  ／  長押しで好きな場所にピンを設置',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
        ),
      ),
    );
  }

  Widget _buildQuickSpots() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickSpots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = _quickSpots[i];
          return GestureDetector(
            onTap: () => _ctrl?.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(s.lat, s.lng), 12.0)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 4)],
              ),
              child: Text(s.name, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSugList() {
    return Material(
      elevation: 8, borderRadius: BorderRadius.circular(16), color: Colors.white,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: AppColors.border, indent: 50),
          itemBuilder: (_, i) {
            final s = _suggestions[i];
            return ListTile(
              dense: true,
              leading: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.place, size: 18, color: AppColors.primary),
              ),
              title: Text(s.main,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: s.sub.isNotEmpty
                  ? Text(s.sub,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () => _selectSug(s),
            );
          },
        ),
      ),
    );
  }

  Widget _myLocBtn() {
    return GestureDetector(
      onTap: () => _ctrl?.animateCamera(
          CameraUpdate.newLatLng(const LatLng(35.6762, 139.6503))),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.my_location, size: 22, color: AppColors.primary),
      ),
    );
  }

  // ── ボトムパネル ─────────────────────────────────────────────
  Widget _buildBottom() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),

            if (_picked == null && !_isFetchingPOI)
              _noPickCard()
            else if (_isFetchingPOI && _picked == null)
              _loadingCard()
            else if (_showCustomInput || _customPin != null)
              _customCard()
            else
              _placeCard(),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _picked == null ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(_picked == null ? Icons.location_off : Icons.check_circle,
                      size: 20,
                      color: _picked == null ? AppColors.textHint : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _picked == null ? 'マップで場所を選んでください' : 'この場所を投稿先に設定する',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: _picked == null ? AppColors.textHint : Colors.white),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _noPickCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryVeryLight, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(children: [
        Container(width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.3),
                shape: BoxShape.circle),
            child: const Icon(Icons.location_searching, size: 22, color: AppColors.primary)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('まだ場所が選択されていません',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          SizedBox(height: 2),
          Text('POIピンをタップ  または  長押しで任意の場所を選択',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  // ── ローディングカード（POI 検索中） ───────────────────────────
  Widget _loadingCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryVeryLight, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(children: [
        SizedBox(width: 40, height: 40,
          child: Center(child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          )),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('場所情報を取得中...', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 2),
          Text('Google Maps から場所名・住所・カテゴリを取得しています',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  // ── POI / 検索結果のカード ─────────────────────────────────────
  Widget _placeCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE3F4FC), Color(0xFFD0EBFA)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(children: [
        // アイコン
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Center(child: Text(
            _poiEmoji(_pickedCategory),
            style: const TextStyle(fontSize: 20),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // カテゴリバッジ
          if (_pickedCategory.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_pickedCategory, style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(height: 4),
          ],
          // 場所名
          if (_pickedName.isNotEmpty) ...[
            Row(children: [
              Expanded(
                child: Text(_pickedName, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              // Place Detail 取得中は小さいローディング
              if (_isFetchingPOI)
                const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
            ]),
            const SizedBox(height: 2),
          ],
          // 住所
          if (_pickedAddress.isNotEmpty) ...[
            Row(children: [
              const Icon(Icons.location_on, size: 11, color: AppColors.primary),
              const SizedBox(width: 3),
              Expanded(child: Text(_pickedAddress, style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
          ],
          // 座標
          Text(_fmt(_picked!), style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary)),
        ])),
        // リセットボタン
        GestureDetector(
          onTap: _resetPin,
          child: Container(width: 26, height: 26,
              decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 13, color: AppColors.textSecondary)),
        ),
      ]),
    );
  }

  // ── POI カテゴリ → 絵文字 ─────────────────────────────────────
  String _poiEmoji(String category) {
    const Map<String, String> map = {
      'レストラン': '🍽️', '飲食店': '🍽️', 'カフェ': '☕', 'バー': '🍺',
      'ベーカリー': '🥐', 'テイクアウト': '🥡', 'デリバリー': '🛵',
      'コンビニ': '🏪', 'スーパー': '🛒', 'ドラッグストア': '💊', '薬局': '💊',
      'デパート': '🏬', 'ショッピングモール': '🛍️', 'アパレル': '👗',
      '家電': '📱', '書店': '📚', '観光スポット': '📸',
      '博物館・美術館': '🏛️', '公園': '🌳', '遊園地': '🎡',
      '動物園': '🦁', '水族館': '🐠', 'スタジアム': '🏟️', '映画館': '🎬',
      'ホテル・宿泊': '🏨', 'ホテル': '🏨', '病院': '🏥', 'クリニック': '🏥',
      '歯科': '🦷', '銀行': '🏦', 'ATM': '💳', 'ガソリンスタンド': '⛽',
      '駐車場': '🅿️', '地下鉄駅': '🚇', '鉄道駅': '🚉', 'バス停': '🚌',
      '空港': '✈️', '学校': '🏫', '大学': '🎓', '図書館': '📖',
      '郵便局': '📮', '警察': '👮', 'ジム': '💪', 'スパ': '♨️',
      '美容院': '💇', '花屋': '💐', 'ペットショップ': '🐾',
      'キャンプ場': '⛺', '自然名所': '🌿', '施設': '🏢',
    };
    return map[category] ?? '📌';
  }

  Widget _customCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFDCEDC8)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0), shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Center(child: Text('📍', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('カスタムピン', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32))),
            if (_customPin != null)
              Text(_fmt(_customPin!),
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ])),
          GestureDetector(
            onTap: _resetPin,
            child: Container(width: 26, height: 26,
                decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 13, color: AppColors.textSecondary)),
          ),
        ]),
        if (_isGeocoding) ...[
          const SizedBox(height: 8),
          const Row(children: [
            SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
            SizedBox(width: 8),
            Text('住所を取得中...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ] else if (_customPinAddress.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(child: Text(_customPinAddress,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
          ]),
        ],
        const SizedBox(height: 10),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: Row(children: [
            const SizedBox(width: 10),
            const Icon(Icons.edit_location_alt, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _customNameCtrl,
                style: const TextStyle(fontSize: 13),
                onChanged: (v) => _pickedName = v,
                decoration: const InputDecoration(
                  hintText: '場所名を入力（任意）',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────
class _QS { final String name; final double lat, lng;
  const _QS(this.name, this.lat, this.lng); }
class _Sug {
  final String placeId, main, sub;
  final double? lat, lng;
  const _Sug({required this.placeId, required this.main, required this.sub,
    this.lat, this.lng});
}
