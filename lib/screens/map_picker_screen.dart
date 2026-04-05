/// MapPickerScreen  ─  投稿画面のマップ選択
///
/// プラットフォーム別に実装を切り替える:
///   iOS / Android : map_picker_mobile.dart  (Google Maps SDK)
///   Web preview   : map_picker_web.dart     (flutter_map + ArcGIS)
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../map_api/map_picker_mobile.dart';
import '../map_api/map_picker_web.dart';

export 'package:latlong2/latlong.dart' show LatLng;

/// 外部から使うクラス名は MapPickerScreen のまま維持
class MapPickerScreen extends StatelessWidget {
  final ll.LatLng? initialCenter;

  const MapPickerScreen({super.key, this.initialCenter});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MapPickerWeb(initialCenter: initialCenter);
    } else {
      return MapPickerMobile(initialCenter: initialCenter);
    }
  }
}
