// ignore_for_file: unused_field, dangling_library_doc_comments
/// Web プレビュー用 MapPicker（flutter_map + ArcGIS 衛星タイル）
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../models/data_models.dart';

class MapPickerWeb extends StatefulWidget {
  final ll.LatLng? initialCenter;
  const MapPickerWeb({super.key, this.initialCenter});

  @override
  State<MapPickerWeb> createState() => _MapPickerWebState();
}

class _MapPickerWebState extends State<MapPickerWeb> {
  final fmap.MapController _ctrl = fmap.MapController();

  ll.LatLng? _picked;
  String _pickedName    = '';
  String _pickedAddress = '';

  SpotPin? _selectedSpot;
  ll.LatLng? _customPin;
  String _customPinAddress = '';
  bool _isGeocoding    = false;
  bool _showCustomInput = false;

  bool _showSatellite = true;

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
    _ctrl.dispose();
    _searchCtrl.dispose();
    _customNameCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── 検索 ──────────────────────────────────────────────────────
  void _onSearchChanged(String q) {
    _debounce?.cancel();
    q = q.trim();
    if (q.length < 2) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 420), () => _nominatim(q));
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

  void _selectSug(_Sug s) {
    setState(() { _suggestions = []; _showSuggestions = false; });
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    _setPicked(ll.LatLng(s.lat, s.lng), name: s.main, address: s.sub);
  }

  // ── 逆ジオコーディング ──────────────────────────────────────
  Future<void> _reverseGeocode(ll.LatLng pos) async {
    setState(() => _isGeocoding = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}'
        '&format=json&accept-language=ja&zoom=18',
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
            _customPinAddress = address;
            if (nm.isNotEmpty && _customNameCtrl.text.isEmpty) {
              _customNameCtrl.text = nm;
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
  void _setPicked(ll.LatLng pos, {String name = '', String address = ''}) {
    setState(() {
      _picked          = pos;
      _pickedName      = name;
      _pickedAddress   = address;
      _customPin       = null;
      _selectedSpot    = null;
      _customPinAddress = '';
      _showCustomInput = false;
      _customNameCtrl.clear();
    });
    _ctrl.move(pos, 15.0);
  }

  void _onSpotTap(SpotPin spot) {
    final pos = ll.LatLng(spot.lat, spot.lng);
    setState(() {
      _picked          = pos;
      _pickedName      = spot.title;
      _pickedAddress   = spot.prefecture;
      _selectedSpot    = spot;
      _customPin       = null;
      _showCustomInput = false;
    });
    FocusScope.of(context).unfocus();
    _ctrl.move(pos, 15.0);
  }

  Future<void> _onLongPress(ll.LatLng pos) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _customPin        = pos;
      _picked           = pos;
      _pickedName       = '';
      _pickedAddress    = '';
      _customPinAddress = '';
      _selectedSpot     = null;
      _showCustomInput  = true;
      _customNameCtrl.clear();
    });
    await _reverseGeocode(pos);
  }

  void _resetPin() {
    setState(() {
      _picked           = null;
      _pickedName       = '';
      _pickedAddress    = '';
      _customPin        = null;
      _customPinAddress = '';
      _selectedSpot     = null;
      _showCustomInput  = false;
      _customNameCtrl.clear();
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
    final tileUrl = _showSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        // ── FlutterMap ────────────────────────────────────────
        fmap.FlutterMap(
          mapController: _ctrl,
          options: fmap.MapOptions(
            initialCenter: widget.initialCenter ?? const ll.LatLng(36.5, 137.0),
            initialZoom: 6.0,
            onLongPress: (_, pos) => _onLongPress(pos),
            onTap: (_, __) {
              if (_showSuggestions) setState(() => _showSuggestions = false);
            },
          ),
          children: [
            fmap.TileLayer(urlTemplate: tileUrl,
                userAgentPackageName: 'com.shotmap.pins'),

            // 既存スポットピン
            fmap.MarkerLayer(
              markers: SampleData.pins.map((spot) {
                final isSel = _selectedSpot?.id == spot.id;
                final isSight = spot.pinType == PinType.sightseeing;
                final clr = isSight ? const Color(0xFFE53935) : const Color(0xFF1565C0);
                final sz = isSel ? 52.0 : 40.0;
                return fmap.Marker(
                  point: ll.LatLng(spot.lat, spot.lng),
                  width: sz, height: sz + 8,
                  child: GestureDetector(
                    onTap: () => _onSpotTap(spot),
                    child: _spotPin(clr, isSight ? '🏔' : '🍴', isSel),
                  ),
                );
              }).toList(),
            ),

            // 選択ピン
            if (_picked != null && _selectedSpot == null)
              fmap.MarkerLayer(markers: [
                fmap.Marker(
                  point: _picked!,
                  width: 48, height: 56,
                  child: _customPinWidget(_customPin != null),
                ),
              ]),
          ],
        ),

        // ── 衛星/地図 切替 ────────────────────────────────────
        Positioned(
          right: 16,
          bottom: _showCustomInput ? 270 : 210,
          child: GestureDetector(
            onTap: () => setState(() => _showSatellite = !_showSatellite),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(_showSatellite ? Icons.map_outlined : Icons.satellite_alt,
                  size: 22, color: AppColors.primary),
            ),
          ),
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
          child: GestureDetector(
            onTap: () => _ctrl.move(const ll.LatLng(35.6762, 139.6503), 13.0),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.my_location, size: 22, color: AppColors.primary),
            ),
          ),
        ),

        // ── ボトムパネル ──────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0, child: _buildBottom()),
      ]),
    );
  }

  // ── ウィジェット群 ─────────────────────────────────────────────
  Widget _spotPin(Color clr, String emoji, bool sel) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: sel ? 44 : 32, height: sel ? 44 : 32,
        decoration: BoxDecoration(
          color: sel ? Colors.white : clr, shape: BoxShape.circle,
          border: Border.all(color: sel ? clr : Colors.white, width: sel ? 3 : 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: sel ? 0.4 : 0.22),
              blurRadius: sel ? 10 : 5, offset: const Offset(0, 2))],
        ),
        child: Center(child: Text(emoji, style: TextStyle(fontSize: sel ? 20 : 15))),
      ),
      CustomPaint(size: const Size(10, 6), painter: _TP(color: clr)),
    ]);
  }

  Widget _customPinWidget(bool isCustom) {
    final clr = isCustom ? const Color(0xFF1565C0) : const Color(0xFFC62828);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCustom
                ? [const Color(0xFF42A5F5), const Color(0xFF1565C0)]
                : [const Color(0xFFEF5350), const Color(0xFFC62828)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: clr.withValues(alpha: 0.5),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: _isGeocoding && isCustom
            ? const Center(child: SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white))))
            : Center(child: Text(isCustom ? '📍' : '📌',
                style: const TextStyle(fontSize: 18))),
      ),
      CustomPaint(size: const Size(10, 6), painter: _TP(color: clr)),
    ]);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        GestureDetector(
          onTap: _cancel,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
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
            onTap: () => _ctrl.move(ll.LatLng(s.lat, s.lng), 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 4)],
              ),
              child: Text(s.name, style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
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
              title: Text(s.main, style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: s.sub.isNotEmpty
                  ? Text(s.sub, style: const TextStyle(fontSize: 10,
                  color: AppColors.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () => _selectSug(s),
            );
          },
        ),
      ),
    );
  }

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

            if (_picked == null)
              _noPickCard()
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
          Text('スポットピンをタップ  または  長押しで任意の場所を選択',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _placeCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE3F4FC), Color(0xFFD0EBFA)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Center(child: Text(
            _selectedSpot?.pinType == PinType.sightseeing ? '🏔' :
            _selectedSpot != null ? '🍴' : '📌',
            style: const TextStyle(fontSize: 20),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_pickedName.isNotEmpty) ...[
            Text(_pickedName, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
          ],
          if (_pickedAddress.isNotEmpty) ...[
            Text(_pickedAddress, style: const TextStyle(fontSize: 11,
                color: AppColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
          ],
          Text(_fmt(_picked!), style: const TextStyle(fontSize: 10,
              color: AppColors.textSecondary)),
        ])),
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
            const Text('カスタムピン（長押しで設置）',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
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

class _TP extends CustomPainter {
  final Color color;
  const _TP({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_TP old) => old.color != color;
}

class _QS { final String name; final double lat, lng;
  const _QS(this.name, this.lat, this.lng); }
class _Sug {
  final String main, sub;
  final double lat, lng;
  const _Sug({required this.main, required this.sub, required this.lat, required this.lng});
}
