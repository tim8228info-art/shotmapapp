// ignore_for_file: unused_import
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// ピン種別（風景 = 赤ピン / グルメ = 青ピン）
// ─────────────────────────────────────────────
enum PinType { sightseeing, gourmet }

extension PinTypeExtension on PinType {
  String get label => this == PinType.sightseeing ? '風景' : 'グルメ';
  Color get color =>
      this == PinType.sightseeing ? const Color(0xFFE53935) : const Color(0xFF1565C0);
  Color get lightColor =>
      this == PinType.sightseeing ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD);
  IconData get icon =>
      this == PinType.sightseeing ? Icons.landscape : Icons.restaurant;
}

class SpotPin {
  final String id;
  final String title;
  final String imageUrl;
  final double lat;
  final double lng;
  final String prefecture;
  final List<String> tags;
  final int likeCount;
  final String authorName;
  final String authorAvatar;
  final PinType pinType;

  const SpotPin({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.prefecture,
    required this.tags,
    required this.likeCount,
    required this.authorName,
    required this.authorAvatar,
    this.pinType = PinType.sightseeing,
  });
}

class TrendSpot {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> tags;
  final int likeCount;
  final String prefecture;
  final double lat;
  final double lng;
  final bool isHot;

  const TrendSpot({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tags,
    required this.likeCount,
    required this.prefecture,
    required this.lat,
    required this.lng,
    this.isHot = false,
  });
}

class MovieItem {
  final String id;
  final String title;
  final String channelName;
  final String thumbnailUrl;
  final String videoUrl;
  final String description;
  final double spotLat;
  final double spotLng;
  final String spotName;
  final int viewCount;
  final String duration;

  const MovieItem({
    required this.id,
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.description,
    required this.spotLat,
    required this.spotLng,
    required this.spotName,
    required this.viewCount,
    required this.duration,
  });
}

// ─────────────────────────────────────────────
// おすすめ情報モデル（観光地・カフェ・ホテル）
// ─────────────────────────────────────────────

enum RecommendGenre { sightseeing, cafe, hotel }

class RecommendItem {
  final String id;
  final String title;
  final String siteName;
  final String imageUrl;
  final String url;
  final String description;
  final String area;
  final List<String> tags;
  final double? rating;
  final RecommendGenre genre;

  const RecommendItem({
    required this.id,
    required this.title,
    required this.siteName,
    required this.imageUrl,
    required this.url,
    required this.description,
    required this.area,
    required this.tags,
    this.rating,
    required this.genre,
  });
}

// ─────────────────────────────────────────────
// 保存済みスポット（マップピン or トレンド）
// ─────────────────────────────────────────────
enum SavedSpotType { pin, trend }

class SavedSpot {
  final String id;
  final String title;
  final String imageUrl;
  final String prefecture;
  final List<String> tags;
  final SavedSpotType type;
  final DateTime savedAt;

  SavedSpot({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.prefecture,
    required this.tags,
    required this.type,
    required this.savedAt,
  });

  factory SavedSpot.fromPin(SpotPin pin) => SavedSpot(
        id: pin.id,
        title: pin.title,
        imageUrl: pin.imageUrl,
        prefecture: pin.prefecture,
        tags: pin.tags,
        type: SavedSpotType.pin,
        savedAt: DateTime.now(),
      );

  factory SavedSpot.fromTrend(TrendSpot trend) => SavedSpot(
        id: trend.id,
        title: trend.title,
        imageUrl: trend.imageUrl,
        prefecture: trend.prefecture,
        tags: trend.tags,
        type: SavedSpotType.trend,
        savedAt: DateTime.now(),
      );
}

// ─────────────────────────────────────────────
// フォローユーザーモデル（サンプル）
// ─────────────────────────────────────────────
class AppUser {
  final String uid;         // 固定システムID
  final String customId;   // ユーザーが設定するカスタムID
  final String name;
  final String avatarUrl;
  final String bio;
  final int pinCount;
  final int followerCount;
  final int followingCount;

  const AppUser({
    required this.uid,
    required this.customId,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.pinCount,
    required this.followerCount,
    required this.followingCount,
  });
}

/// ユーザープロフィールモデル
class UserProfile {
  final String id;
  final String name;
  final String avatarUrl;
  final int pinCount;
  final int likeCount;
  final String bio;
  final String customId; // ユーザーが設定するカスタムID（@以降）

  // SNS URLs（空文字 = 未設定）
  final String instagramUrl;
  final String youtubeUrl;
  final String xUrl;
  final String tiktokUrl;

  /// フォロー一覧を他のユーザーから非公開にするか
  final bool hideFollowing;

  const UserProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.pinCount,
    required this.likeCount,
    required this.bio,
    this.customId = '',
    this.instagramUrl = '',
    this.youtubeUrl = '',
    this.xUrl = '',
    this.tiktokUrl = '',
    this.hideFollowing = false,
  });

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    int? pinCount,
    int? likeCount,
    String? bio,
    String? customId,
    String? instagramUrl,
    String? youtubeUrl,
    String? xUrl,
    String? tiktokUrl,
    bool? hideFollowing,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pinCount: pinCount ?? this.pinCount,
      likeCount: likeCount ?? this.likeCount,
      bio: bio ?? this.bio,
      customId: customId ?? this.customId,
      hideFollowing: hideFollowing ?? this.hideFollowing,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      xUrl: xUrl ?? this.xUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
    );
  }
}

// ─────────────────────────────────────────────
// サンプルデータ
// ─────────────────────────────────────────────
class SampleData {
  static final List<SpotPin> pins = [
    const SpotPin(
      id: '1',
      title: '竹林の小径',
      imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400',
      lat: 35.0168,
      lng: 135.6710,
      prefecture: '京都府',
      tags: ['#写真映え', '#竹林', '#京都'],
      likeCount: 342,
      authorName: 'Yuki Tanaka',
      authorAvatar: 'https://i.pravatar.cc/100?img=1',
      pinType: PinType.sightseeing,
    ),
    const SpotPin(
      id: '2',
      title: '河口湖と富士山',
      imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400',
      lat: 35.5112,
      lng: 138.7676,
      prefecture: '山梨県',
      tags: ['#富士山', '#湖', '#絶景'],
      likeCount: 891,
      authorName: 'Mio Sato',
      authorAvatar: 'https://i.pravatar.cc/100?img=5',
      pinType: PinType.sightseeing,
    ),
    const SpotPin(
      id: '3',
      title: '渋谷スクランブル交差点',
      imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400',
      lat: 35.6595,
      lng: 139.7004,
      prefecture: '東京都',
      tags: ['#夜景', '#東京', '#都市'],
      likeCount: 1203,
      authorName: 'Kenji Suzuki',
      authorAvatar: 'https://i.pravatar.cc/100?img=3',
      pinType: PinType.sightseeing,
    ),
    const SpotPin(
      id: '4',
      title: '嵐山渡月橋',
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400',
      lat: 35.0094,
      lng: 135.6780,
      prefecture: '京都府',
      tags: ['#紅葉', '#橋', '#京都'],
      likeCount: 567,
      authorName: 'Hana Nakamura',
      authorAvatar: 'https://i.pravatar.cc/100?img=9',
      pinType: PinType.sightseeing,
    ),
    const SpotPin(
      id: '5',
      title: '道頓堀 金龍ラーメン',
      imageUrl: 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400',
      lat: 34.6687,
      lng: 135.5013,
      prefecture: '大阪府',
      tags: ['#グルメ', '#大阪', '#ラーメン'],
      likeCount: 445,
      authorName: 'Sota Yamamoto',
      authorAvatar: 'https://i.pravatar.cc/100?img=7',
      pinType: PinType.gourmet,
    ),
    const SpotPin(
      id: '6',
      title: '浅草 天ぷら 三定',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      lat: 35.7148,
      lng: 139.7967,
      prefecture: '東京都',
      tags: ['#天ぷら', '#浅草', '#老舗'],
      likeCount: 776,
      authorName: 'Aoi Watanabe',
      authorAvatar: 'https://i.pravatar.cc/100?img=11',
      pinType: PinType.gourmet,
    ),
    const SpotPin(
      id: '7',
      title: '伏見稲荷大社',
      imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400',
      lat: 34.9671,
      lng: 135.7727,
      prefecture: '京都府',
      tags: ['#鳥居', '#神社', '#京都'],
      likeCount: 1089,
      authorName: 'Riku Ito',
      authorAvatar: 'https://i.pravatar.cc/100?img=13',
      pinType: PinType.sightseeing,
    ),
    const SpotPin(
      id: '8',
      title: '白川郷合掌造り',
      imageUrl: 'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=400',
      lat: 36.2572,
      lng: 136.9050,
      prefecture: '岐阜県',
      tags: ['#合掌造り', '#世界遺産', '#雪景色'],
      likeCount: 634,
      authorName: 'Nana Kobayashi',
      authorAvatar: 'https://i.pravatar.cc/100?img=15',
      pinType: PinType.sightseeing,
    ),
    const SpotPin(
      id: '9',
      title: '京都 錦市場の食べ歩き',
      imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400',
      lat: 35.0050,
      lng: 135.7680,
      prefecture: '京都府',
      tags: ['#食べ歩き', '#市場', '#京都グルメ'],
      likeCount: 523,
      authorName: 'Hana Nakamura',
      authorAvatar: 'https://i.pravatar.cc/100?img=9',
      pinType: PinType.gourmet,
    ),
    const SpotPin(
      id: '10',
      title: '築地場外市場 海鮮丼',
      imageUrl: 'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400',
      lat: 35.6654,
      lng: 139.7707,
      prefecture: '東京都',
      tags: ['#海鮮', '#築地', '#朝食'],
      likeCount: 988,
      authorName: 'Kenji Suzuki',
      authorAvatar: 'https://i.pravatar.cc/100?img=3',
      pinType: PinType.gourmet,
    ),
  ];

  static final List<TrendSpot> trends = [
    const TrendSpot(
      id: 't1',
      title: '伏見稲荷の千本鳥居',
      description: '朱色の鳥居が連なる幻想的な道。早朝の光が差し込む時間帯が最高の撮影チャンス！',
      imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=600',
      tags: ['#今週のトレンド', '#写真映え', '#京都'],
      likeCount: 1089,
      prefecture: '京都府',
      lat: 34.9671,
      lng: 135.7727,
      isHot: true,
    ),
    const TrendSpot(
      id: 't2',
      title: '河口湖の逆さ富士',
      description: '風のない早朝だけ見られる逆さ富士。SNSで急上昇中の撮影スポット！',
      imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=600',
      tags: ['#絶景', '#富士山', '#山梨'],
      likeCount: 891,
      prefecture: '山梨県',
      lat: 35.5112,
      lng: 138.7676,
      isHot: true,
    ),
    const TrendSpot(
      id: 't3',
      title: '渋谷スクランブル交差点',
      description: '世界一有名な交差点。雨の夜の反射が特に美しい。夜間撮影がオススメ！',
      imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=600',
      tags: ['#夜景', '#東京', '#都市写真'],
      likeCount: 1203,
      prefecture: '東京都',
      lat: 35.6595,
      lng: 139.7004,
      isHot: false,
    ),
    const TrendSpot(
      id: 't4',
      title: '白川郷冬の合掌造り',
      description: '雪に覆われた合掌造りの集落。世界遺産の絶景がここに。ライトアップ期間は幻想的！',
      imageUrl: 'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=600',
      tags: ['#世界遺産', '#雪景色', '#岐阜'],
      likeCount: 634,
      prefecture: '岐阜県',
      lat: 36.2572,
      lng: 136.9050,
      isHot: false,
    ),
    const TrendSpot(
      id: 't5',
      title: '浅草寺と東京スカイツリー',
      description: '江戸の風情と現代の象徴が一枚に収まる奇跡のアングル。観光客に人気No.1！',
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
      tags: ['#浅草', '#スカイツリー', '#東京'],
      likeCount: 776,
      prefecture: '東京都',
      lat: 35.7148,
      lng: 139.7967,
      isHot: false,
    ),
  ];

  static final List<MovieItem> movies = [
    const MovieItem(
      id: 'm1',
      title: '【京都vlog】竹林と千本鳥居を一日で巡る最強ルート',
      channelName: 'Yuki Travel Japan',
      thumbnailUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=800',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: '嵐山の竹林から伏見稲荷まで、京都の映えスポットを全部回りました！早起きが鍵です✨',
      spotLat: 35.0168,
      spotLng: 135.6710,
      spotName: '嵐山 竹林の小径（京都府）',
      viewCount: 284000,
      duration: '12:34',
    ),
    const MovieItem(
      id: 'm2',
      title: '富士山麓ゴールデンタイム撮影チャレンジ🗻',
      channelName: 'Mount Fuji Photographer',
      thumbnailUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=800',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: '夜明け前から待機して撮影した幻の逆さ富士。機材・設定まで全部公開！',
      spotLat: 35.5112,
      spotLng: 138.7676,
      spotName: '河口湖（山梨県）',
      viewCount: 512000,
      duration: '18:20',
    ),
    const MovieItem(
      id: 'm3',
      title: '渋谷・新宿夜景フォトウォーク【雨の夜が最高すぎた】',
      channelName: 'Tokyo Night Shots',
      thumbnailUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: '雨の夜の東京は最高の被写体。スマホでここまで撮れる設定を教えます📱',
      spotLat: 35.6595,
      spotLng: 139.7004,
      spotName: '渋谷スクランブル交差点（東京都）',
      viewCount: 178000,
      duration: '9:55',
    ),
    const MovieItem(
      id: 'm4',
      title: '白川郷ライトアップ完全ガイド🏔️雪景色が幻想的すぎる',
      channelName: 'Japan Hidden Gems',
      thumbnailUrl: 'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=800',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: '年に数回しかない白川郷のライトアップ。予約方法から撮影ポイントまで完全解説！',
      spotLat: 36.2572,
      spotLng: 136.9050,
      spotName: '白川郷（岐阜県）',
      viewCount: 342000,
      duration: '15:47',
    ),
    const MovieItem(
      id: 'm5',
      title: '大阪ディープスポット案内 道頓堀〜新世界を歩く',
      channelName: 'Osaka Street Walker',
      thumbnailUrl: 'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=800',
      videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: '観光客が知らない大阪の路地裏。ネオンと文化が混在する最高の撮影地！',
      spotLat: 34.6687,
      spotLng: 135.5013,
      spotName: '道頓堀（大阪府）',
      viewCount: 96000,
      duration: '21:03',
    ),
  ];

  /// 初期ユーザープロフィール
  static final UserProfile initialUser = UserProfile(
    id: 'user1',
    name: 'あなたの名前',
    avatarUrl: 'https://i.pravatar.cc/200?img=23',
    pinCount: 0,
    likeCount: 0,
    bio: 'お気に入りのスポットを発見・共有中 📍',
    customId: '',
    instagramUrl: '',
    youtubeUrl: '',
    xUrl: '',
    tiktokUrl: '',
  );

  // ─── サンプルユーザー（ID検索用） ───
  static const List<AppUser> sampleUsers = [
    AppUser(
      uid: 'u001',
      customId: 'yuki_travel',
      name: 'Yuki Tanaka',
      avatarUrl: 'https://i.pravatar.cc/100?img=1',
      bio: '京都・奈良を中心に日本の古都を旅しています🏯',
      pinCount: 42,
      followerCount: 1280,
      followingCount: 156,
    ),
    AppUser(
      uid: 'u002',
      customId: 'mio_photo',
      name: 'Mio Sato',
      avatarUrl: 'https://i.pravatar.cc/100?img=5',
      bio: '富士山と湖が大好き🗻 絶景ハンター',
      pinCount: 28,
      followerCount: 890,
      followingCount: 234,
    ),
    AppUser(
      uid: 'u003',
      customId: 'kenji_tokyo',
      name: 'Kenji Suzuki',
      avatarUrl: 'https://i.pravatar.cc/100?img=3',
      bio: '東京の夜景専門カメラマン📷✨',
      pinCount: 67,
      followerCount: 2340,
      followingCount: 89,
    ),
    AppUser(
      uid: 'u004',
      customId: 'hana_kyoto',
      name: 'Hana Nakamura',
      avatarUrl: 'https://i.pravatar.cc/100?img=9',
      bio: '嵐山・嵯峨野エリアの写真スポット開拓中🌸',
      pinCount: 35,
      followerCount: 567,
      followingCount: 312,
    ),
    AppUser(
      uid: 'u005',
      customId: 'osaka_night',
      name: 'Sota Yamamoto',
      avatarUrl: 'https://i.pravatar.cc/100?img=7',
      bio: '大阪の夜と食を記録しています🍜',
      pinCount: 19,
      followerCount: 445,
      followingCount: 178,
    ),
    AppUser(
      uid: 'u006',
      customId: 'aoi_asakusa',
      name: 'Aoi Watanabe',
      avatarUrl: 'https://i.pravatar.cc/100?img=11',
      bio: '浅草・上野エリアの下町文化が好き🏮',
      pinCount: 24,
      followerCount: 776,
      followingCount: 203,
    ),
    AppUser(
      uid: 'u007',
      customId: 'riku_shrine',
      name: 'Riku Ito',
      avatarUrl: 'https://i.pravatar.cc/100?img=13',
      bio: '神社仏閣巡りが趣味。全国の鳥居を制覇したい⛩️',
      pinCount: 88,
      followerCount: 1089,
      followingCount: 421,
    ),
    AppUser(
      uid: 'u008',
      customId: 'nana_shirakawa',
      name: 'Nana Kobayashi',
      avatarUrl: 'https://i.pravatar.cc/100?img=15',
      bio: '合掌造りと雪景色に魅せられた旅人❄️',
      pinCount: 31,
      followerCount: 634,
      followingCount: 267,
    ),
  ];

  // ─── おすすめ観光地（10件） ───
  static const List<RecommendItem> sightseeingList = [
    RecommendItem(
      id: 's1',
      title: '伏見稲荷大社（千本鳥居）',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=600',
      url: 'https://www.jalan.net/kankou/spt_26100ag2130019778/',
      description: '朱色の鳥居が山頂まで続く、京都最古の神社。早朝の静かな時間帯がおすすめ。',
      area: '京都',
      tags: ['#鳥居', '#神社', '#京都'],
      rating: 4.8,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's2',
      title: '河口湖・富士山ビュースポット',
      siteName: 'るるぶ',
      imageUrl: 'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=600',
      url: 'https://www.rurubu.travel/article/detail/2893',
      description: '逆さ富士が湖面に映る絶景ポイント。早朝の無風時が最高の撮影チャンス。',
      area: '山梨',
      tags: ['#富士山', '#湖', '#絶景'],
      rating: 4.9,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's3',
      title: '白川郷・合掌造り集落',
      siteName: 'ことりっぷ',
      imageUrl: 'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=600',
      url: 'https://co-trip.jp/area/8/spot/16291/',
      description: '雪をまとった合掌造りは世界遺産。ライトアップ期間（1〜2月）は特に幻想的。',
      area: '岐阜',
      tags: ['#世界遺産', '#雪景色', '#合掌造り'],
      rating: 4.7,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's4',
      title: '渋谷スクランブル交差点',
      siteName: 'Time Out Tokyo',
      imageUrl: 'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=600',
      url: 'https://www.timeout.jp/tokyo/ja/attractions/shibuya-crossing',
      description: '世界で最も忙しい交差点のひとつ。雨の夜はネオンの反射が圧巻の美しさ。',
      area: '東京',
      tags: ['#夜景', '#東京', '#都市写真'],
      rating: 4.5,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's5',
      title: '浅草寺・仲見世通り',
      siteName: 'トリップアドバイザー',
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600',
      url: 'https://www.tripadvisor.jp/Attraction_Review-g1066456-d321321-Reviews-Senso_ji_Temple-Asakusa_Taito_Tokyo_Tokyo_Prefecture_Kanto.html',
      description: '東京最古の寺院。雷門から続く仲見世通りは食べ歩きもできる観光名所。',
      area: '東京',
      tags: ['#浅草', '#寺院', '#食べ歩き'],
      rating: 4.6,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's6',
      title: '嵐山・竹林の小径',
      siteName: 'ウォーカープラス',
      imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600',
      url: 'https://www.walkerplus.com/spot/ar0726s0009285/',
      description: '青々とした竹が空を覆う幻想的な小道。夜間のライトアップも美しい。',
      area: '京都',
      tags: ['#竹林', '#嵐山', '#写真映え'],
      rating: 4.6,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's7',
      title: '厳島神社（宮島）',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1590077428593-a55bb07c4665?w=600',
      url: 'https://www.jalan.net/kankou/spt_34100bg2140003521/',
      description: '海上に浮かぶ朱色の大鳥居が圧倒的。満潮時の幻想的な景観は絶品。',
      area: '広島',
      tags: ['#世界遺産', '#鳥居', '#島'],
      rating: 4.9,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's8',
      title: '上高地・大正池',
      siteName: 'るるぶ',
      imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600',
      url: 'https://www.rurubu.travel/article/detail/8741',
      description: '焼岳の噴火でできた神秘の池。穂高連峰を背景にした水鏡が圧倒的に美しい。',
      area: '長野',
      tags: ['#絶景', '#湖', '#アルプス'],
      rating: 4.8,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's9',
      title: '金閣寺（鹿苑寺）',
      siteName: 'ことりっぷ',
      imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600',
      url: 'https://co-trip.jp/area/4/spot/13059/',
      description: '金箔に輝く三層の舎利殿と鏡湖池の庭園が美しい世界遺産。朝の光が特に映える。',
      area: '京都',
      tags: ['#世界遺産', '#金閣寺', '#日本庭園'],
      rating: 4.7,
      genre: RecommendGenre.sightseeing,
    ),
    RecommendItem(
      id: 's10',
      title: '沖縄・古宇利島',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=600',
      url: 'https://www.jalan.net/kankou/spt_47322ag2110004978/',
      description: 'エメラルドグリーンの海に浮かぶ恋の島。古宇利大橋からの景色は絶景中の絶景。',
      area: '沖縄',
      tags: ['#沖縄', '#海', '#離島'],
      rating: 4.7,
      genre: RecommendGenre.sightseeing,
    ),
  ];

  // ─── おすすめカフェ（10件） ───
  static const List<RecommendItem> cafeList = [
    RecommendItem(
      id: 'c1',
      title: '% Arabica 京都 嵐山',
      siteName: '食べログ',
      imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600',
      url: 'https://tabelog.com/kyoto/A2601/A260403/26023614/',
      description: '世界的に有名なコーヒーブランドの旗艦店。渡月橋を望むロケーションが最高。',
      area: '京都・嵐山',
      tags: ['#コーヒー', '#おしゃれ', '#インスタ映え'],
      rating: 4.4,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c2',
      title: 'Blue Bottle Coffee 青山カフェ',
      siteName: '食べログ',
      imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600',
      url: 'https://tabelog.com/tokyo/A1306/A130603/13170388/',
      description: 'サードウェーブコーヒーの先駆け。モダンで開放的な空間でゆったりできる。',
      area: '東京・青山',
      tags: ['#ブルーボトル', '#コーヒー', '#青山'],
      rating: 4.2,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c3',
      title: 'Streamer Coffee Company 渋谷',
      siteName: 'ぐるなび',
      imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',
      url: 'https://r.gnavi.co.jp/g833201/',
      description: 'ラテアートの世界大会優勝者が手がけるカフェ。こだわりのエスプレッソを堪能。',
      area: '東京・渋谷',
      tags: ['#ラテアート', '#渋谷', '#スペシャルティコーヒー'],
      rating: 4.3,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c4',
      title: '星乃珈琲店 大阪梅田店',
      siteName: 'ホットペッパーグルメ',
      imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',
      url: 'https://www.hotpepper.jp/strJ001223906/',
      description: '大人気のスフレパンケーキが名物。落ち着いた空間で長居できる喫茶店スタイル。',
      area: '大阪・梅田',
      tags: ['#パンケーキ', '#喫茶店', '#スフレ'],
      rating: 4.1,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c5',
      title: 'SHIRO 北海道発コスメカフェ',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=600',
      url: 'https://www.jalan.net/gourmet/grm_400190/',
      description: '北海道素材を使ったオーガニックスイーツが話題。白を基調とした清潔感ある空間。',
      area: '北海道・札幌',
      tags: ['#オーガニック', '#北海道', '#スイーツ'],
      rating: 4.0,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c6',
      title: 'THE ROASTERY by Nozy Coffee',
      siteName: '食べログ',
      imageUrl: 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=600',
      url: 'https://tabelog.com/tokyo/A1317/A131702/13136904/',
      description: 'シングルオリジン豆にこだわる自家焙煎店。豆の個性を楽しめる本格カフェ。',
      area: '東京・代々木公園',
      tags: ['#自家焙煎', '#シングルオリジン', '#代々木公園'],
      rating: 4.5,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c7',
      title: 'サードウェーブコーヒー 福岡天神',
      siteName: '食べログ',
      imageUrl: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=600',
      url: 'https://tabelog.com/fukuoka/A4001/A400101/',
      description: '福岡発のスペシャルティコーヒーショップ。地元の豆を厳選した一杯が絶品。',
      area: '福岡・天神',
      tags: ['#コーヒー', '#福岡', '#スペシャルティ'],
      rating: 4.3,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c8',
      title: '奈良 鹿のいるカフェ',
      siteName: 'ことりっぷ',
      imageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=600',
      url: 'https://co-trip.jp/area/6/gourmet/',
      description: '奈良公園近くで鹿と一緒に過ごせるユニークなカフェ。抹茶スイーツが人気。',
      area: '奈良',
      tags: ['#奈良', '#鹿', '#抹茶'],
      rating: 4.2,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c9',
      title: '箱根 強羅花壇 茶寮',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=600',
      url: 'https://www.jalan.net/gourmet/grm_014030/',
      description: '箱根の自然に囲まれた高級茶寮。富士山を望みながら味わう抹茶と和菓子は格別。',
      area: '神奈川・箱根',
      tags: ['#抹茶', '#和菓子', '#箱根'],
      rating: 4.6,
      genre: RecommendGenre.cafe,
    ),
    RecommendItem(
      id: 'c10',
      title: 'Fuglen Tokyo 代々木公園',
      siteName: '食べログ',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600',
      url: 'https://tabelog.com/tokyo/A1317/A131702/13155924/',
      description: 'ノルウェー発のコーヒーバー。北欧ヴィンテージ家具と最高の一杯を楽しめる。',
      area: '東京・代々木公園',
      tags: ['#北欧', '#コーヒー', '#ヴィンテージ'],
      rating: 4.4,
      genre: RecommendGenre.cafe,
    ),
  ];

  // ─── おすすめホテル（10件） ───
  static const List<RecommendItem> hotelList = [
    RecommendItem(
      id: 'h1',
      title: '星のや京都',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1540541338537-1220205ac3f4?w=600',
      url: 'https://www.jalan.net/yad337247/',
      description: '嵐山の山懐に佇む水辺のリゾート。専用船でしかアクセスできない秘境感が魅力。',
      area: '京都・嵐山',
      tags: ['#高級旅館', '#嵐山', '#秘境'],
      rating: 4.9,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h2',
      title: 'ホテル雅叙園東京',
      siteName: '一休.com',
      imageUrl: 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600',
      url: 'https://www.ikyu.com/00001398/',
      description: '日本の美を凝縮した「昭和の竜宮城」。アート作品と豪華内装が圧倒的な存在感。',
      area: '東京・目黒',
      tags: ['#ラグジュアリー', '#アート', '#目黒'],
      rating: 4.7,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h3',
      title: '翠嵐 ラグジュアリーコレクションホテル京都',
      siteName: '楽天トラベル',
      imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=600',
      url: 'https://travel.rakuten.co.jp/HOTEL/169772/',
      description: '桂川沿いに建つ5つ星ホテル。日本の美と西洋の優雅さが融合した唯一無二の空間。',
      area: '京都・嵐山',
      tags: ['#5つ星', '#嵐山', '#リバービュー'],
      rating: 4.8,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h4',
      title: 'ザ・リッツ・カールトン大阪',
      siteName: '一休.com',
      imageUrl: 'https://images.unsplash.com/photo-1496417263034-38ec4f0b665a?w=600',
      url: 'https://www.ikyu.com/00001309/',
      description: '大阪梅田に位置する最高峰ホテル。欧州の貴族文化を取り入れたインテリアが圧巻。',
      area: '大阪・梅田',
      tags: ['#リッツカールトン', '#梅田', '#ラグジュアリー'],
      rating: 4.8,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h5',
      title: '界 加賀',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1553653924-39b70295f8da?w=600',
      url: 'https://www.jalan.net/yad349480/',
      description: '温泉旅館ブランド「界」の旗艦店。山中温泉の豊かな自然と伝統工芸を堪能できる。',
      area: '石川・加賀',
      tags: ['#温泉', '#旅館', '#加賀'],
      rating: 4.7,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h6',
      title: 'アンダーズ東京',
      siteName: '楽天トラベル',
      imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600',
      url: 'https://travel.rakuten.co.jp/HOTEL/156987/',
      description: '虎ノ門ヒルズ上層階に位置するデザインホテル。東京タワーを望む絶景ルームが人気。',
      area: '東京・虎ノ門',
      tags: ['#虎ノ門', '#東京タワービュー', '#デザインホテル'],
      rating: 4.6,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h7',
      title: 'ザ・プリンス さくらタワー東京',
      siteName: '一休.com',
      imageUrl: 'https://images.unsplash.com/photo-1506059612708-99d6c258160e?w=600',
      url: 'https://www.ikyu.com/00000437/',
      description: '品川に佇む高層ホテル。東京湾を一望するスカイラウンジからの夜景は絶品。',
      area: '東京・品川',
      tags: ['#夜景', '#東京湾', '#ハイクラス'],
      rating: 4.5,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h8',
      title: 'ホテル・ザ・マンハッタン 千葉',
      siteName: '楽天トラベル',
      imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=600',
      url: 'https://travel.rakuten.co.jp/HOTEL/2537/',
      description: '千葉駅直結の便利なホテル。個性的なテーマルームが揃い、特別な体験を提供。',
      area: '千葉',
      tags: ['#千葉', '#テーマルーム', '#駅直結'],
      rating: 4.3,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h9',
      title: '沖縄残波岬ロイヤルホテル',
      siteName: 'じゃらん',
      imageUrl: 'https://images.unsplash.com/photo-1573843981267-be1999ff37cd?w=600',
      url: 'https://www.jalan.net/yad305023/',
      description: 'エメラルドの海に面した大型リゾート。プールと天然ビーチで沖縄を満喫できる。',
      area: '沖縄',
      tags: ['#リゾート', '#沖縄', '#ビーチ'],
      rating: 4.4,
      genre: RecommendGenre.hotel,
    ),
    RecommendItem(
      id: 'h10',
      title: 'ニセコHANAZONO RESORT',
      siteName: '楽天トラベル',
      imageUrl: 'https://images.unsplash.com/photo-1516939884455-1445c8652f83?w=600',
      url: 'https://travel.rakuten.co.jp/HOTEL/142823/',
      description: '世界最高品質のパウダースノーが楽しめる北海道のスキーリゾート。夏のトレッキングも人気。',
      area: '北海道・ニセコ',
      tags: ['#スキー', '#北海道', '#リゾート'],
      rating: 4.6,
      genre: RecommendGenre.hotel,
    ),
  ];
}
