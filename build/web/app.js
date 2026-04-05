// ═══════════════════════════════════════════════════════════════
// Shot Map - Web App
// Flutter/Dart アプリの完全再現版
// ═══════════════════════════════════════════════════════════════

// ─── Sample Data ───────────────────────────────────────────────
const SampleData = {
  pins: [
    { id:'1', title:'竹林の小径', imageUrl:'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', lat:35.0168, lng:135.6710, prefecture:'京都府', tags:['#写真映え','#竹林','#京都'], likeCount:342, authorName:'Yuki Tanaka', authorAvatar:'https://i.pravatar.cc/100?img=1', pinType:'sightseeing' },
    { id:'2', title:'河口湖と富士山', imageUrl:'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', lat:35.5112, lng:138.7676, prefecture:'山梨県', tags:['#富士山','#湖','#絶景'], likeCount:891, authorName:'Mio Sato', authorAvatar:'https://i.pravatar.cc/100?img=5', pinType:'sightseeing' },
    { id:'3', title:'渋谷スクランブル交差点', imageUrl:'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=400', lat:35.6595, lng:139.7004, prefecture:'東京都', tags:['#夜景','#東京','#都市'], likeCount:1203, authorName:'Kenji Suzuki', authorAvatar:'https://i.pravatar.cc/100?img=3', pinType:'sightseeing' },
    { id:'4', title:'嵐山渡月橋', imageUrl:'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400', lat:35.0094, lng:135.6780, prefecture:'京都府', tags:['#紅葉','#橋','#京都'], likeCount:567, authorName:'Hana Nakamura', authorAvatar:'https://i.pravatar.cc/100?img=9', pinType:'sightseeing' },
    { id:'5', title:'道頓堀 金龍ラーメン', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', lat:34.6687, lng:135.5013, prefecture:'大阪府', tags:['#グルメ','#大阪','#ラーメン'], likeCount:445, authorName:'Sota Yamamoto', authorAvatar:'https://i.pravatar.cc/100?img=7', pinType:'gourmet' },
    { id:'6', title:'浅草 天ぷら 三定', imageUrl:'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400', lat:35.7148, lng:139.7967, prefecture:'東京都', tags:['#天ぷら','#浅草','#老舗'], likeCount:776, authorName:'Aoi Watanabe', authorAvatar:'https://i.pravatar.cc/100?img=11', pinType:'gourmet' },
    { id:'7', title:'伏見稲荷大社', imageUrl:'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', lat:34.9671, lng:135.7727, prefecture:'京都府', tags:['#鳥居','#神社','#京都'], likeCount:1089, authorName:'Riku Ito', authorAvatar:'https://i.pravatar.cc/100?img=13', pinType:'sightseeing' },
    { id:'8', title:'白川郷合掌造り', imageUrl:'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=400', lat:36.2572, lng:136.9050, prefecture:'岐阜県', tags:['#合掌造り','#世界遺産','#雪景色'], likeCount:634, authorName:'Nana Kobayashi', authorAvatar:'https://i.pravatar.cc/100?img=15', pinType:'sightseeing' },
    { id:'9', title:'京都 錦市場の食べ歩き', imageUrl:'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400', lat:35.0050, lng:135.7680, prefecture:'京都府', tags:['#食べ歩き','#市場','#京都グルメ'], likeCount:523, authorName:'Hana Nakamura', authorAvatar:'https://i.pravatar.cc/100?img=9', pinType:'gourmet' },
    { id:'10', title:'築地場外市場 海鮮丼', imageUrl:'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400', lat:35.6654, lng:139.7707, prefecture:'東京都', tags:['#海鮮','#築地','#朝食'], likeCount:988, authorName:'Kenji Suzuki', authorAvatar:'https://i.pravatar.cc/100?img=3', pinType:'gourmet' },
    { id:'11', title:'札幌時計台', imageUrl:'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400', lat:43.0642, lng:141.3469, prefecture:'北海道', tags:['#北海道','#時計台','#札幌'], likeCount:412, authorName:'Yuki Tanaka', authorAvatar:'https://i.pravatar.cc/100?img=1', pinType:'sightseeing' },
    { id:'12', title:'函館山夜景', imageUrl:'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=400', lat:41.7580, lng:140.6945, prefecture:'北海道', tags:['#夜景','#函館','#絶景'], likeCount:856, authorName:'Mio Sato', authorAvatar:'https://i.pravatar.cc/100?img=5', pinType:'sightseeing' },
    { id:'13', title:'仙台 牛タン利久', imageUrl:'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', lat:38.2683, lng:140.8694, prefecture:'宮城県', tags:['#牛タン','#仙台グルメ','#B級グルメ'], likeCount:678, authorName:'Hana Nakamura', authorAvatar:'https://i.pravatar.cc/100?img=9', pinType:'gourmet' },
    { id:'14', title:'日光東照宮', imageUrl:'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400', lat:36.7583, lng:139.5985, prefecture:'栃木県', tags:['#世界遺産','#日光','#歴史'], likeCount:745, authorName:'Sota Yamamoto', authorAvatar:'https://i.pravatar.cc/100?img=7', pinType:'sightseeing' },
    { id:'15', title:'浅草寺仲見世通り', imageUrl:'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400', lat:35.7148, lng:139.7965, prefecture:'東京都', tags:['#浅草','#食べ歩き','#下町'], likeCount:934, authorName:'Aoi Watanabe', authorAvatar:'https://i.pravatar.cc/100?img=11', pinType:'sightseeing' },
    { id:'16', title:'新宿 一蘭ラーメン', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', lat:35.6938, lng:139.7034, prefecture:'東京都', tags:['#ラーメン','#新宿','#豚骨'], likeCount:521, authorName:'Riku Ito', authorAvatar:'https://i.pravatar.cc/100?img=13', pinType:'gourmet' },
    { id:'17', title:'鎌倉大仏', imageUrl:'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=400', lat:35.3167, lng:139.5353, prefecture:'神奈川県', tags:['#鎌倉','#大仏','#歴史'], likeCount:867, authorName:'Nana Kobayashi', authorAvatar:'https://i.pravatar.cc/100?img=15', pinType:'sightseeing' },
    { id:'18', title:'横浜中華街 肉まん', imageUrl:'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400', lat:35.4437, lng:139.6380, prefecture:'神奈川県', tags:['#中華街','#横浜','#食べ歩き'], likeCount:643, authorName:'Kenji Suzuki', authorAvatar:'https://i.pravatar.cc/100?img=3', pinType:'gourmet' },
    { id:'19', title:'金沢兼六園', imageUrl:'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=400', lat:36.5613, lng:136.6623, prefecture:'石川県', tags:['#日本庭園','#金沢','#名勝'], likeCount:712, authorName:'Yuki Tanaka', authorAvatar:'https://i.pravatar.cc/100?img=1', pinType:'sightseeing' },
    { id:'20', title:'名古屋 矢場とん 味噌カツ', imageUrl:'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=400', lat:35.1709, lng:136.8815, prefecture:'愛知県', tags:['#味噌カツ','#名古屋めし','#B級グルメ'], likeCount:589, authorName:'Mio Sato', authorAvatar:'https://i.pravatar.cc/100?img=5', pinType:'gourmet' },
    { id:'21', title:'姫路城', imageUrl:'https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=400', lat:34.8394, lng:134.6939, prefecture:'兵庫県', tags:['#世界遺産','#城','#姫路'], likeCount:923, authorName:'Hana Nakamura', authorAvatar:'https://i.pravatar.cc/100?img=9', pinType:'sightseeing' },
    { id:'22', title:'大阪 道頓堀たこ焼き', imageUrl:'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400', lat:34.6688, lng:135.5015, prefecture:'大阪府', tags:['#たこ焼き','#道頓堀','#大阪グルメ'], likeCount:1156, authorName:'Sota Yamamoto', authorAvatar:'https://i.pravatar.cc/100?img=7', pinType:'gourmet' },
    { id:'23', title:'宮島 厳島神社', imageUrl:'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=400', lat:34.2958, lng:132.3196, prefecture:'広島県', tags:['#世界遺産','#鳥居','#海上神社'], likeCount:1078, authorName:'Aoi Watanabe', authorAvatar:'https://i.pravatar.cc/100?img=11', pinType:'sightseeing' },
    { id:'24', title:'広島 お好み焼き みっちゃん', imageUrl:'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400', lat:34.3853, lng:132.4553, prefecture:'広島県', tags:['#お好み焼き','#広島グルメ','#ソウルフード'], likeCount:445, authorName:'Riku Ito', authorAvatar:'https://i.pravatar.cc/100?img=13', pinType:'gourmet' },
    { id:'25', title:'高千穂峡', imageUrl:'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400', lat:32.7127, lng:131.3070, prefecture:'宮崎県', tags:['#渓谷','#ボート','#絶景'], likeCount:734, authorName:'Nana Kobayashi', authorAvatar:'https://i.pravatar.cc/100?img=15', pinType:'sightseeing' },
    { id:'26', title:'福岡 中洲屋台', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=400', lat:33.5904, lng:130.4017, prefecture:'福岡県', tags:['#屋台','#博多グルメ','#夜の福岡'], likeCount:867, authorName:'Kenji Suzuki', authorAvatar:'https://i.pravatar.cc/100?img=3', pinType:'gourmet' },
    { id:'27', title:'沖縄 美ら海水族館', imageUrl:'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=400', lat:26.6939, lng:127.8779, prefecture:'沖縄県', tags:['#水族館','#沖縄','#ジンベイザメ'], likeCount:1124, authorName:'Yuki Tanaka', authorAvatar:'https://i.pravatar.cc/100?img=1', pinType:'sightseeing' },
    { id:'28', title:'沖縄 Blue Seal アイスクリーム', imageUrl:'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400', lat:26.2124, lng:127.6791, prefecture:'沖縄県', tags:['#アイス','#沖縄グルメ','#ブルーシール'], likeCount:398, authorName:'Mio Sato', authorAvatar:'https://i.pravatar.cc/100?img=5', pinType:'gourmet' },
    { id:'29', title:'富士山 五合目', imageUrl:'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=400', lat:35.3606, lng:138.7274, prefecture:'静岡県', tags:['#富士山','#登山','#絶景'], likeCount:1345, authorName:'Hana Nakamura', authorAvatar:'https://i.pravatar.cc/100?img=9', pinType:'sightseeing' },
    { id:'30', title:'京都 先斗町 割烹料理', imageUrl:'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400', lat:35.0067, lng:135.7715, prefecture:'京都府', tags:['#京料理','#先斗町','#和食'], likeCount:678, authorName:'Sota Yamamoto', authorAvatar:'https://i.pravatar.cc/100?img=7', pinType:'gourmet' },
  ],

  trends: [
    { id:'t1', title:'伏見稲荷の千本鳥居', description:'朱色の鳥居が連なる幻想的な道。早朝の光が差し込む時間帯が最高の撮影チャンス！', imageUrl:'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=600', tags:['#今週のトレンド','#写真映え','#京都'], likeCount:1089, saveCount:856, prefecture:'京都府', lat:34.9671, lng:135.7727, isHot:true, pinType:'sightseeing' },
    { id:'t2', title:'河口湖の逆さ富士', description:'風のない早朝だけ見られる逆さ富士。SNSで急上昇中の撮影スポット！', imageUrl:'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=600', tags:['#絶景','#富士山','#山梨'], likeCount:891, saveCount:723, prefecture:'山梨県', lat:35.5112, lng:138.7676, isHot:true, pinType:'sightseeing' },
    { id:'t3', title:'渋谷スクランブル交差点', description:'世界一有名な交差点。雨の夜の反射が特に美しい。夜間撮影がオススメ！', imageUrl:'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=600', tags:['#夜景','#東京','#都市写真'], likeCount:1203, saveCount:534, prefecture:'東京都', lat:35.6595, lng:139.7004, isHot:false, pinType:'sightseeing' },
    { id:'t4', title:'白川郷冬の合掌造り', description:'雪に覆われた合掌造りの集落。世界遺産の絶景がここに。ライトアップ期間は幻想的！', imageUrl:'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=600', tags:['#世界遺産','#雪景色','#岐阜'], likeCount:634, saveCount:421, prefecture:'岐阜県', lat:36.2572, lng:136.9050, isHot:false, pinType:'sightseeing' },
    { id:'t5', title:'浅草寺と東京スカイツリー', description:'江戸の風情と現代の象徴が一枚に収まる奇跡のアングル。観光客に人気No.1！', imageUrl:'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=600', tags:['#浅草','#スカイツリー','#東京'], likeCount:776, saveCount:389, prefecture:'東京都', lat:35.7148, lng:139.7967, isHot:false, pinType:'sightseeing' },
    { id:'g1', title:'築地場外市場の海鮮丼', description:'新鮮なネタが山盛りの海鮮丼。行列必至の人気店が立ち並ぶ東京の食の聖地！', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=600', tags:['#グルメ','#海鮮','#東京'], likeCount:943, saveCount:812, prefecture:'東京都', lat:35.6654, lng:139.7706, isHot:true, pinType:'gourmet' },
    { id:'g2', title:'道頓堀のたこ焼き巡り', description:'ふわとろ食感の本場たこ焼き。食べ歩きしながら大阪の活気を全身で感じよう！', imageUrl:'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=600', tags:['#たこ焼き','#大阪','#食べ歩き'], likeCount:1124, saveCount:978, prefecture:'大阪府', lat:34.6687, lng:135.5009, isHot:true, pinType:'gourmet' },
    { id:'g3', title:'京都の京料理・懐石', description:'四季折々の食材を使った繊細な京懐石。目でも舌でも楽しめる日本の食文化の粋！', imageUrl:'https://images.unsplash.com/photo-1547592180-85f173990554?w=600', tags:['#京料理','#懐石','#京都'], likeCount:678, saveCount:534, prefecture:'京都府', lat:35.0116, lng:135.7681, isHot:false, pinType:'gourmet' },
    { id:'g4', title:'札幌ラーメン横丁', description:'濃厚な味噌・醤油・塩の名店が集結。北海道の寒さを吹き飛ばす絶品ラーメン！', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=600', tags:['#ラーメン','#北海道','#グルメ'], likeCount:812, saveCount:667, prefecture:'北海道', lat:43.0618, lng:141.3545, isHot:false, pinType:'gourmet' },
    { id:'g5', title:'福岡・中洲の屋台文化', description:'博多ラーメン・もつ鍋・焼き鳥…地元の人と旅人が肩を並べる屋台は最高のグルメ体験！', imageUrl:'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600', tags:['#屋台','#博多','#福岡'], likeCount:756, saveCount:598, prefecture:'福岡県', lat:33.5904, lng:130.4017, isHot:false, pinType:'gourmet' },
  ],

  sampleUsers: [
    { uid:'u1', customId:'yuki_travel', name:'Yuki Tanaka', avatarUrl:'https://i.pravatar.cc/100?img=1', bio:'日本全国の絶景スポットを巡る旅人📸', pinCount:48, followerCount:1234, followingCount:89 },
    { uid:'u2', customId:'mio_photo', name:'Mio Sato', avatarUrl:'https://i.pravatar.cc/100?img=5', bio:'フォトジェニックなカフェ巡り☕', pinCount:92, followerCount:3456, followingCount:124 },
    { uid:'u3', customId:'kenji_snap', name:'Kenji Suzuki', avatarUrl:'https://i.pravatar.cc/100?img=3', bio:'夜景専門カメラマン🌙', pinCount:156, followerCount:8921, followingCount:45 },
    { uid:'u4', customId:'hana_foodie', name:'Hana Nakamura', avatarUrl:'https://i.pravatar.cc/100?img=9', bio:'グルメ旅行が大好き🍜', pinCount:203, followerCount:12450, followingCount:312 },
    { uid:'u5', customId:'sota_explore', name:'Sota Yamamoto', avatarUrl:'https://i.pravatar.cc/100?img=7', bio:'世界遺産コレクター🏯', pinCount:67, followerCount:2100, followingCount:56 },
    { uid:'u6', customId:'aoi_art', name:'Aoi Watanabe', avatarUrl:'https://i.pravatar.cc/100?img=11', bio:'伝統文化と現代アートの融合✨', pinCount:134, followerCount:5678, followingCount:203 },
    { uid:'u7', customId:'riku_outdoor', name:'Riku Ito', avatarUrl:'https://i.pravatar.cc/100?img=13', bio:'山登りと星空撮影が趣味⛰️', pinCount:78, followerCount:4321, followingCount:98 },
    { uid:'u8', customId:'nana_sweets', name:'Nana Kobayashi', avatarUrl:'https://i.pravatar.cc/100?img=15', bio:'和菓子と甘味処を巡る旅🍡', pinCount:165, followerCount:9870, followingCount:445 },
  ],

  sightseeingList: [
    { id:'s1', title:'伏見稲荷大社', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=600', url:'https://www.jalan.net/', description:'千本鳥居で有名な全国に3万社ある稲荷神社の総本宮。朱色の鳥居が連なる山道は幻想的。', area:'京都・伏見', prefecture:'京都府', tags:['#鳥居','#写真映え','#パワースポット'], rating:4.8 },
    { id:'s2', title:'河口湖', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=600', url:'https://travel.rakuten.co.jp/', description:'富士山を望む富士五湖のひとつ。逆さ富士の絶景が楽しめる人気観光スポット。', area:'山梨・富士河口湖', prefecture:'山梨県', tags:['#富士山','#湖','#絶景'], rating:4.7 },
    { id:'s3', title:'嵐山竹林の小径', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=600', url:'https://www.ikyu.com/', description:'青々とした竹が天に向かって伸びる神秘的な空間。早朝の散策がおすすめ。', area:'京都・嵐山', prefecture:'京都府', tags:['#竹林','#写真映え','#京都'], rating:4.6 },
    { id:'s4', title:'白川郷', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=600', url:'https://www.jalan.net/', description:'ユネスコ世界遺産。合掌造りの集落が雪景色に映える冬の景観は圧倒的。', area:'岐阜・白川村', prefecture:'岐阜県', tags:['#世界遺産','#合掌造り','#雪景色'], rating:4.8 },
    { id:'s5', title:'渋谷スクランブル交差点', siteName:'るるぶ', imageUrl:'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=600', url:'https://www.rurubu.travel/', description:'世界最多の歩行者が行き交う交差点。雨の夜は路面の反射が特に美しい。', area:'東京・渋谷', prefecture:'東京都', tags:['#夜景','#都市','#東京'], rating:4.5 },
    { id:'s6', title:'姫路城', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=600', url:'https://travel.rakuten.co.jp/', description:'「白鷺城」の愛称で知られる世界文化遺産。桜の季節は特に美しい。', area:'兵庫・姫路', prefecture:'兵庫県', tags:['#世界遺産','#城','#桜'], rating:4.9 },
    { id:'s7', title:'宮島・厳島神社', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=600', url:'https://www.jalan.net/', description:'海上に建つ大鳥居が有名な世界遺産。満潮時に鳥居が海に浮かぶ幻想的な光景。', area:'広島・宮島', prefecture:'広島県', tags:['#鳥居','#世界遺産','#瀬戸内'], rating:4.8 },
    { id:'s8', title:'鎌倉大仏', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1590559899731-a382839e5549?w=600', url:'https://www.ikyu.com/', description:'国宝に指定された高さ13.35mの阿弥陀如来坐像。東大寺と並ぶ日本の二大大仏のひとつ。', area:'神奈川・鎌倉', prefecture:'神奈川県', tags:['#大仏','#歴史','#鎌倉'], rating:4.6 },
    { id:'s9', title:'金沢兼六園', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1589530099906-b720bff68a09?w=600', url:'https://travel.rakuten.co.jp/', description:'日本三名園のひとつ。雪吊りで有名な冬の風景と日本庭園の美が楽しめる。', area:'石川・金沢', prefecture:'石川県', tags:['#日本庭園','#名勝','#金沢'], rating:4.7 },
    { id:'s10', title:'函館山夜景', siteName:'るるぶ', imageUrl:'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=600', url:'https://www.rurubu.travel/', description:'「世界三大夜景」のひとつとされる函館の夜景。山頂からの眺望は息をのむ美しさ。', area:'北海道・函館', prefecture:'北海道', tags:['#夜景','#世界三大夜景','#函館'], rating:4.8 },
    { id:'s11', title:'高千穂峡', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600', url:'https://www.jalan.net/', description:'柱状節理の断崖が続く峡谷。真名井の滝からの滝ボートが人気アクティビティ。', area:'宮崎・高千穂', prefecture:'宮崎県', tags:['#渓谷','#絶景','#ボート'], rating:4.7 },
    { id:'s12', title:'美ら海水族館', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1534430480872-3498386e7856?w=600', url:'https://www.ikyu.com/', description:'世界最大級の水槽で泳ぐジンベイザメが圧巻。沖縄の豊かな海を体験できる。', area:'沖縄・本部', prefecture:'沖縄県', tags:['#水族館','#ジンベイザメ','#沖縄'], rating:4.7 },
    { id:'s13', title:'日光東照宮', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600', url:'https://travel.rakuten.co.jp/', description:'徳川家康を祀る豪華絢爛な世界遺産。「見ざる聞かざる言わざる」の三猿でも有名。', area:'栃木・日光', prefecture:'栃木県', tags:['#世界遺産','#歴史','#日光'], rating:4.7 },
    { id:'s14', title:'嵐山渡月橋', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=600', url:'https://www.jalan.net/', description:'保津川に架かる風光明媚な橋。紅葉や桜の季節は特に美しく、京都を代表する名所。', area:'京都・嵐山', prefecture:'京都府', tags:['#紅葉','#桜','#渡月橋'], rating:4.5 },
    { id:'s15', title:'富士山五合目', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=600', url:'https://travel.rakuten.co.jp/', description:'日本最高峰・富士山の五合目。雲海に浮かぶ富士山頂や眼下に広がる絶景が魅力。', area:'静岡・山梨', prefecture:'静岡県', tags:['#富士山','#登山','#絶景'], rating:4.6 },
  ],

  gourmetList: [
    { id:'g1', title:'築地場外市場', siteName:'食べログ', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=600', url:'https://tabelog.com/', description:'東京の台所。朝獲れの海鮮を使った海鮮丼が人気。朝6時から多くの店が開く。', area:'東京・築地', prefecture:'東京都', tags:['#海鮮丼','#市場','#朝食'], rating:4.5 },
    { id:'g2', title:'道頓堀のたこ焼き', siteName:'ぐるなび', imageUrl:'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=600', url:'https://gnavi.co.jp/', description:'大阪名物たこ焼きの激戦区。ふわとろ生地に大きめのタコが特徴。食べ歩きが楽しい。', area:'大阪・道頓堀', prefecture:'大阪府', tags:['#たこ焼き','#大阪','#食べ歩き'], rating:4.4 },
    { id:'g3', title:'京都・錦市場', siteName:'食べログ', imageUrl:'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600', url:'https://tabelog.com/', description:'「京の台所」と呼ばれる市場。漬物・豆腐・湯葉など京の食材が集まり食べ歩きが楽しい。', area:'京都・中京区', prefecture:'京都府', tags:['#食べ歩き','#市場','#京料理'], rating:4.3 },
    { id:'g4', title:'札幌ラーメン横丁', siteName:'ぐるなび', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=600', url:'https://gnavi.co.jp/', description:'昭和26年創業の老舗横丁。濃厚な味噌ラーメンをはじめ、醤油・塩の名店が集結。', area:'北海道・札幌', prefecture:'北海道', tags:['#ラーメン','#味噌','#北海道'], rating:4.5 },
    { id:'g5', title:'福岡屋台 中洲', siteName:'食べログ', imageUrl:'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600', url:'https://tabelog.com/', description:'日本最大規模の屋台街。博多ラーメン・もつ鍋・焼き鳥など多彩な料理が楽しめる。', area:'福岡・中洲', prefecture:'福岡県', tags:['#屋台','#博多ラーメン','#夜市'], rating:4.4 },
    { id:'g6', title:'仙台 牛タン焼き', siteName:'ぐるなび', imageUrl:'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600', url:'https://gnavi.co.jp/', description:'仙台名物の牛タン定食。肉厚でジューシーな牛タンと麦飯・テールスープの組み合わせが絶品。', area:'宮城・仙台', prefecture:'宮城県', tags:['#牛タン','#仙台','#名物'], rating:4.6 },
    { id:'g7', title:'名古屋 矢場とん 味噌カツ', siteName:'食べログ', imageUrl:'https://images.unsplash.com/photo-1467003909585-2f8a72700288?w=600', url:'https://tabelog.com/', description:'名古屋めしの代表格。甘辛い赤味噌ダレをたっぷりかけた揚げたてのカツが絶品。', area:'愛知・名古屋', prefecture:'愛知県', tags:['#味噌カツ','#名古屋めし','#B級グルメ'], rating:4.4 },
    { id:'g8', title:'横浜 中華街', siteName:'ぐるなび', imageUrl:'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=600', url:'https://gnavi.co.jp/', description:'日本最大の中華街。本場の中華料理と食べ歩きグルメが充実。肉まんが特に人気。', area:'神奈川・横浜', prefecture:'神奈川県', tags:['#中華街','#食べ歩き','#横浜'], rating:4.3 },
    { id:'g9', title:'大阪 新世界串カツ', siteName:'食べログ', imageUrl:'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600', url:'https://tabelog.com/', description:'大阪・新世界の名物串カツ。二度漬け禁止のソースでいただくサクサクの串カツが絶品。', area:'大阪・新世界', prefecture:'大阪府', tags:['#串カツ','#大阪','#新世界'], rating:4.4 },
    { id:'g10', title:'広島 お好み焼き', siteName:'ぐるなび', imageUrl:'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600', url:'https://gnavi.co.jp/', description:'大阪とは違う広島風お好み焼き。キャベツ・そば・卵を重ねた食べ応えある一枚。', area:'広島市', prefecture:'広島県', tags:['#お好み焼き','#広島','#ソウルフード'], rating:4.5 },
    { id:'g11', title:'沖縄 ゴーヤーチャンプルー', siteName:'食べログ', imageUrl:'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600', url:'https://tabelog.com/', description:'沖縄の家庭料理の代表。苦味のあるゴーヤーと豆腐・卵の炒め物はヘルシーで美味。', area:'沖縄・那覇', prefecture:'沖縄県', tags:['#琉球料理','#沖縄','#ゴーヤー'], rating:4.2 },
    { id:'g12', title:'京都 懐石料理', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1547592180-85f173990554?w=600', url:'https://www.ikyu.com/', description:'四季折々の食材を使った繊細な京懐石。目でも舌でも楽しめる日本の食文化の粋。', area:'京都・先斗町', prefecture:'京都府', tags:['#懐石','#京料理','#和食'], rating:4.8 },
    { id:'g13', title:'博多ラーメン', siteName:'ぐるなび', imageUrl:'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=600', url:'https://gnavi.co.jp/', description:'豚骨スープが特徴の博多ラーメン。細麺・替え玉が定番。深夜でも行列ができる人気店多数。', area:'福岡・博多', prefecture:'福岡県', tags:['#豚骨','#博多ラーメン','#替え玉'], rating:4.5 },
  ],

  hotelList: [
    { id:'h1', title:'星のや京都', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1540541338537-1220205ac3f4?w=600', url:'https://www.ikyu.com/00001226/', description:'保津川沿いの自然に囲まれた宿。船でしかアクセスできない秘境感が魅力。', area:'京都・嵐山', prefecture:'京都府', tags:['#高級旅館','#嵐山','#星のや'], rating:4.9 },
    { id:'h2', title:'富士マリオットホテル山中湖', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=600', url:'https://travel.rakuten.co.jp/HOTEL/95/', description:'富士山と山中湖を望む絶景リゾート。全室レイクビューで四季折々の景色が楽しめる。', area:'山梨・山中湖', prefecture:'山梨県', tags:['#富士山ビュー','#湖畔リゾート','#マリオット'], rating:4.6 },
    { id:'h3', title:'パーク ハイアット 東京', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1496417263034-38ec4f0b665a?w=600', url:'https://www.ikyu.com/00000150/', description:'新宿のランドマーク・都庁の近くに位置する5つ星ホテル。映画「ロスト・イン・トランスレーション」の舞台。', area:'東京・新宿', prefecture:'東京都', tags:['#5つ星','#東京','#新宿'], rating:4.8 },
    { id:'h4', title:'白川郷 合掌の里', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600', url:'https://www.jalan.net/yad317095/', description:'世界遺産・白川郷に泊まれる合掌造りの宿。囲炉裏を囲む食事と天然温泉が自慢。', area:'岐阜・白川村', prefecture:'岐阜県', tags:['#合掌造り','#囲炉裏','#世界遺産'], rating:4.7 },
    { id:'h5', title:'ヒルトン名古屋', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600', url:'https://travel.rakuten.co.jp/HOTEL/3607/', description:'名古屋の中心地に位置する5つ星ホテル。名古屋城や熱田神宮へのアクセスも抜群。', area:'愛知・名古屋', prefecture:'愛知県', tags:['#5つ星','#名古屋','#ヒルトン'], rating:4.5 },
    { id:'h6', title:'ANAクラウンプラザ大阪', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1496417263034-38ec4f0b665a?w=600', url:'https://www.ikyu.com/00000167/', description:'梅田・難波の中間に位置する便利な立地。道頓堀や心斎橋へもすぐのシティホテル。', area:'大阪・大阪市', prefecture:'大阪府', tags:['#大阪','#シティホテル','#ANA'], rating:4.4 },
    { id:'h7', title:'星野リゾート 界 加賀', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1553653924-39b70295f8da?w=600', url:'https://www.jalan.net/yad354541/', description:'加賀温泉郷に佇む温泉旅館。九谷焼や加賀友禅など石川の工芸を体験できる宿。', area:'石川・加賀', prefecture:'石川県', tags:['#温泉','#星野リゾート','#加賀'], rating:4.7 },
    { id:'h8', title:'由布院 玉の湯', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=600', url:'https://www.ikyu.com/00000857/', description:'由布院温泉を代表する名旅館。こだわりの客室と由布岳を望む温泉が格別の非日常感。', area:'大分・由布院', prefecture:'大分県', tags:['#由布院','#名旅館','#由布岳'], rating:4.9 },
    { id:'h9', title:'沖縄 万座ビーチリゾート', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600', url:'https://travel.rakuten.co.jp/', description:'エメラルドブルーの海に面した沖縄最高級リゾート。ダイビングやシュノーケルが楽しめる。', area:'沖縄・恩納', prefecture:'沖縄県', tags:['#沖縄','#ビーチリゾート','#ダイビング'], rating:4.7 },
    { id:'h10', title:'函館 湯の川温泉 望楼NOGUCHI函館', siteName:'一休.com', imageUrl:'https://images.unsplash.com/photo-1540541338537-1220205ac3f4?w=600', url:'https://www.ikyu.com/00003710/', description:'津軽海峡を一望する絶景の湯宿。函館の夜景も楽しめる。', area:'北海道・函館', prefecture:'北海道', tags:['#温泉','#函館','#絶景'], rating:4.8 },
    { id:'h11', title:'仙台 ウェスティン仙台', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600', url:'https://travel.rakuten.co.jp/HOTEL/89408/', description:'仙台駅直結の超高層ホテル。仙台城跡や松島など東北観光の拠点として最適。', area:'宮城・仙台', prefecture:'宮城県', tags:['#仙台','#ウェスティン','#駅直結'], rating:4.6 },
    { id:'h12', title:'日光金谷ホテル', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1496417263034-38ec4f0b665a?w=600', url:'https://www.jalan.net/yad305578/', description:'明治6年創業の日本最古のクラシックホテル。世界遺産・日光の歴史と格式を感じる宿。', area:'栃木・日光', prefecture:'栃木県', tags:['#歴史', '#クラシック','#日光'], rating:4.5 },
    { id:'h13', title:'黒川温泉 山みず木', siteName:'じゃらん', imageUrl:'https://images.unsplash.com/photo-1553653924-39b70295f8da?w=600', url:'https://www.jalan.net/yad311898/', description:'人気温泉地・黒川温泉の名旅館。山里の自然に囲まれた露天風呂と阿蘇の食材が自慢。', area:'熊本・黒川温泉', prefecture:'熊本県', tags:['#黒川温泉','#露天風呂','#阿蘇'], rating:4.7 },
    { id:'h14', title:'広島グランドプリンスホテル', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=600', url:'https://travel.rakuten.co.jp/HOTEL/835/', description:'広島湾に突き出た半島に建つ絶景ホテル。瀬戸内海の夕日と牡蠣料理が絶品。', area:'広島市', prefecture:'広島県', tags:['#広島湾','#牡蠣','#絶景'], rating:4.5 },
    { id:'h15', title:'ハウステンボス ホテルヨーロッパ', siteName:'楽天トラベル', imageUrl:'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=600', url:'https://travel.rakuten.co.jp/HOTEL/4083/', description:'ハウステンボス内の最高級ホテル。運河沿いのヨーロッパ建築と豪華な内装が圧倒的。', area:'長崎・ハウステンボス', prefecture:'長崎県', tags:['#ハウステンボス','#ヨーロッパ','#リゾート'], rating:4.6 },
  ],
};

// ─── App State ─────────────────────────────────────────────────
const State = {
  isLoggedIn: false,
  currentTab: 0,
  savedPinIds: new Set(),
  savedTrendIds: new Set(),
  followingIds: new Set(['u2','u4','u6']),
  user: {
    name: 'ゲストユーザー',
    customId: 'guest_user',
    avatarUrl: 'https://i.pravatar.cc/100?img=20',
    bio: '',
    pinCount: 0,
    likeCount: 0,
    instagramUrl: '',
    youtubeUrl: '',
    xUrl: '',
    tiktokUrl: '',
    hideFollowing: false,
  },
  mapFilter: 'all',
  mapSatellite: true,
  trendTab: 'spot',
  spotTypeIndex: 0,
  prefFilter: null,
  prefGenre: 'sight',
  profileTab: 'profile',
  prefTabItems: { sight: [], gourmet: [], hotel: [] },
};

// ─── Utility functions ─────────────────────────────────────────
function showSnackbar(msg) {
  const el = document.getElementById('snackbar');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(el._timer);
  el._timer = setTimeout(() => el.classList.remove('show'), 2500);
}

function showAlert(title, body, actions) {
  document.getElementById('alert-title').textContent = title;
  document.getElementById('alert-body').innerHTML = body;
  const actEl = document.getElementById('alert-actions');
  actEl.innerHTML = '';
  actions.forEach(a => {
    const btn = document.createElement('button');
    btn.className = `alert-btn ${a.className || 'alert-btn-ok'}`;
    btn.textContent = a.label;
    btn.onclick = () => {
      closeAlert();
      if (a.action) a.action();
    };
    actEl.appendChild(btn);
  });
  document.getElementById('alert-overlay').classList.add('show');
}

function closeAlert() {
  document.getElementById('alert-overlay').classList.remove('show');
}

function showBottomSheet(id) {
  document.getElementById(id).classList.add('show');
}
function hideBottomSheet(id) {
  document.getElementById(id).classList.remove('show');
}

function formatNumber(n) {
  if (n >= 10000) return Math.floor(n/1000)/10 + 'w';
  if (n >= 1000) return Math.floor(n/100)/10 + 'k';
  return n.toString();
}

function renderTags(tags) {
  return tags.map(t => `<span class="tag">${t}</span>`).join(' ');
}

function renderStars(rating) {
  const full = Math.floor(rating);
  const half = rating % 1 >= 0.5 ? 1 : 0;
  return '★'.repeat(full) + (half ? '½' : '') + '☆'.repeat(5 - full - half);
}

function shuffleArray(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ─── Main App Controller ────────────────────────────────────────
const App = {
  loginAsGuest() {
    State.isLoggedIn = true;
    // Show splash briefly then go to paywall (demo skips paywall)
    document.getElementById('screen-login').classList.remove('active');
    this.showMain();
  },

  subscribe() {
    showSnackbar('サブスクリプション購入済みです ✓');
    this.showMain();
  },

  showMain() {
    document.getElementById('screen-login').classList.remove('active');
    document.getElementById('screen-paywall').classList.remove('active');
    const main = document.getElementById('screen-main');
    main.style.display = 'flex';
    this.switchTab(0);
    MapTab.init();
    TrendTab.init();
    PrefTab.init();
    ProfileTab.init();
    PostScreen.init();
  },

  switchTab(index) {
    State.currentTab = index;
    const tabs = ['tab-map','tab-trend','tab-movie','tab-movie','tab-profile'];
    const navIds = ['nav-map','nav-trend',null,'nav-movie','nav-profile'];

    // Hide all
    ['tab-map','tab-trend','tab-movie','tab-profile'].forEach(id => {
      const el = document.getElementById(id);
      if (el) el.classList.remove('active');
    });
    ['nav-map','nav-trend','nav-movie','nav-profile'].forEach(id => {
      const el = document.getElementById(id);
      if (el) el.classList.remove('active');
    });

    // Show selected
    const tabId = tabs[index];
    const tabEl = document.getElementById(tabId);
    if (tabEl) tabEl.classList.add('active');

    const navId = navIds[index];
    if (navId) {
      const navEl = document.getElementById(navId);
      if (navEl) navEl.classList.add('active');
    }

    // Refresh map if needed
    if (index === 0) {
      setTimeout(() => {
        if (MapTab.map) MapTab.map.invalidateSize();
      }, 100);
    }
  },

  openPost() {
    document.getElementById('screen-post').classList.add('active');
    PostScreen.render();
  },

  closePost() {
    document.getElementById('screen-post').classList.remove('active');
  },

  openTerms() {
    document.getElementById('screen-terms').classList.add('active');
    document.getElementById('terms-content').innerHTML = `
      <h2 style="font-size:18px;font-weight:700;margin-bottom:16px">利用規約</h2>
      <p style="color:#666;font-size:13px;margin-bottom:16px">最終更新日：2024年1月1日</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">第1条（目的）</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">本利用規約は、Shot Map（以下「本アプリ」）の利用条件を定めることを目的とします。ユーザーの皆様には、本規約に同意の上で本アプリをご利用いただきます。</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">第2条（サービス内容）</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">本アプリは、ユーザーが写真スポットを投稿・共有できるマップサービスです。</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">第3条（禁止事項）</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">ユーザーは以下の行為を行ってはなりません：</p>
      <ul style="font-size:14px;line-height:2;color:#333;padding-left:20px;margin-bottom:12px">
        <li>法律に違反する行為</li>
        <li>他のユーザーへの迷惑行為</li>
        <li>虚偽情報の投稿</li>
        <li>知的財産権を侵害する行為</li>
      </ul>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">第4条（サブスクリプション）</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">本アプリは月額500円のサブスクリプションを提供します。サブスクリプションは自動更新されます。キャンセルは次回更新日の24時間前までに行う必要があります。</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">第5条（免責事項）</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">本アプリの運営者は、本アプリの利用により生じた損害について、一切の責任を負いません。</p>
    `;
  },

  openPrivacy() {
    document.getElementById('screen-privacy').classList.add('active');
    document.getElementById('privacy-content').innerHTML = `
      <h2 style="font-size:18px;font-weight:700;margin-bottom:16px">プライバシーポリシー</h2>
      <p style="color:#666;font-size:13px;margin-bottom:16px">最終更新日：2024年1月1日</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">1. 収集する情報</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">本アプリは以下の情報を収集します：</p>
      <ul style="font-size:14px;line-height:2;color:#333;padding-left:20px;margin-bottom:12px">
        <li>アカウント情報（名前、メールアドレス）</li>
        <li>投稿コンテンツ（写真、テキスト、位置情報）</li>
        <li>利用状況データ</li>
      </ul>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">2. 情報の利用目的</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">収集した情報は、サービスの提供・改善、ユーザーサポートに使用します。</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">3. 情報の共有</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">ユーザーの個人情報は、法令に基づく場合を除き、第三者に提供しません。</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">4. セキュリティ</h3>
      <p style="font-size:14px;line-height:1.8;color:#333;margin-bottom:12px">個人情報の保護のため、適切なセキュリティ対策を実施しています。</p>
      <h3 style="font-size:15px;font-weight:700;margin:16px 0 8px">5. お問い合わせ</h3>
      <p style="font-size:14px;line-height:1.8;color:#333">プライバシーに関するお問い合わせは、アプリ内のサポートフォームよりご連絡ください。</p>
    `;
  },

  closeOverlay(name) {
    document.getElementById(`screen-${name}`).classList.remove('active');
  },

  openUserProfile(user) {
    const screen = document.getElementById('screen-user-profile');
    screen.classList.add('active');
    const isFollowing = State.followingIds.has(user.uid);
    document.getElementById('user-profile-content').innerHTML = `
      <div style="background:linear-gradient(135deg,#B3D9F2,#7BBFE0,#5BA4CF);padding:60px 20px 20px;color:white">
        <div style="display:flex;align-items:center;gap:14px">
          <img src="${user.avatarUrl}" class="avatar" style="width:76px;height:76px;border:3px solid white;box-shadow:0 4px 12px rgba(0,0,0,0.18)">
          <div style="flex:1">
            <div style="font-size:18px;font-weight:700">${user.name}</div>
            <div style="background:rgba(255,255,255,0.22);display:inline-block;padding:2px 8px;border-radius:8px;font-size:11px;margin-top:3px">@${user.customId}</div>
            <div style="font-size:12px;color:rgba(255,255,255,0.9);margin-top:5px">${user.bio}</div>
          </div>
        </div>
        <div style="display:flex;gap:20px;margin-top:14px">
          <div style="text-align:center"><div style="font-size:18px;font-weight:800">${user.pinCount}</div><div style="font-size:11px;opacity:0.8">スポット</div></div>
          <div style="text-align:center"><div style="font-size:18px;font-weight:800">${formatNumber(user.followerCount)}</div><div style="font-size:11px;opacity:0.8">フォロワー</div></div>
          <div style="text-align:center"><div style="font-size:18px;font-weight:800">${user.followingCount}</div><div style="font-size:11px;opacity:0.8">フォロー</div></div>
        </div>
        <div style="margin-top:14px;display:flex;gap:10px">
          <button onclick="App.toggleFollow('${user.uid}')" id="follow-btn-${user.uid}" 
            style="flex:1;padding:10px;border-radius:20px;font-size:14px;font-weight:700;border:${isFollowing?'1px solid white':'none'};background:${isFollowing?'transparent':'white'};color:${isFollowing?'white':'var(--primary)'};cursor:pointer;font-family:inherit">
            ${isFollowing ? 'フォロー中' : 'フォローする'}
          </button>
        </div>
      </div>
      <div style="padding:16px">
        <div style="text-align:center;padding:40px;color:var(--text-hint)">
          <span class="material-icons-round" style="font-size:48px">push_pin</span>
          <div style="margin-top:8px;font-size:14px">投稿されたスポットはここに表示されます</div>
        </div>
      </div>
      <button onclick="document.getElementById('screen-user-profile').classList.remove('active')" 
        style="position:absolute;top:60px;left:16px;background:rgba(0,0,0,0.3);border:none;border-radius:50%;width:36px;height:36px;cursor:pointer;display:flex;align-items:center;justify-content:center;color:white">
        <span class="material-icons-round" style="font-size:20px">arrow_back</span>
      </button>
    `;
    screen.querySelector('#user-profile-content').style.position = 'relative';
  },

  toggleFollow(uid) {
    if (State.followingIds.has(uid)) {
      State.followingIds.delete(uid);
      showSnackbar('フォローを解除しました');
    } else {
      State.followingIds.add(uid);
      showSnackbar('フォローしました ✓');
    }
    // Update button
    const btn = document.getElementById(`follow-btn-${uid}`);
    const isNowFollowing = State.followingIds.has(uid);
    if (btn) {
      btn.textContent = isNowFollowing ? 'フォロー中' : 'フォローする';
      btn.style.background = isNowFollowing ? 'transparent' : 'white';
      btn.style.color = isNowFollowing ? 'white' : 'var(--primary)';
      btn.style.border = isNowFollowing ? '1px solid white' : 'none';
    }
    // Refresh profile follow tab
    if (State.currentTab === 4) ProfileTab.renderFollowTab();
  },
};

// ─── Map Tab ────────────────────────────────────────────────────
const MapTab = {
  map: null,
  markers: [],
  selectedPin: null,
  osmLayer: null,
  satelliteLayer: null,

  init() {
    if (this.map) return;
    const mapEl = document.getElementById('leaflet-map');
    this.map = L.map(mapEl, {
      center: [36.5, 137.0],
      zoom: 6,
      zoomControl: false,
    });

    this.osmLayer = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap',
    });

    this.satelliteLayer = L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      { maxZoom: 19, attribution: '© Esri' }
    );

    if (State.mapSatellite) {
      this.satelliteLayer.addTo(this.map);
    } else {
      this.osmLayer.addTo(this.map);
    }
    this.updateLayerIcon();

    this.map.on('click', () => this.closePinDetail());

    this.renderMarkers();
  },

  setFilter(filter) {
    State.mapFilter = filter;
    ['all','sight','gourmet'].forEach(f => {
      document.getElementById(`filter-${f}`).classList.toggle('active', 
        (f === 'all' && filter === 'all') || 
        (f === 'sight' && filter === 'sightseeing') ||
        (f === 'gourmet' && filter === 'gourmet')
      );
    });
    this.renderMarkers();
    this.closePinDetail();
  },

  toggleLayer() {
    State.mapSatellite = !State.mapSatellite;
    if (State.mapSatellite) {
      this.osmLayer.remove();
      this.satelliteLayer.addTo(this.map);
    } else {
      this.satelliteLayer.remove();
      this.osmLayer.addTo(this.map);
    }
    this.updateLayerIcon();
  },

  updateLayerIcon() {
    const icon = document.getElementById('layer-icon');
    const label = document.getElementById('layer-label');
    if (State.mapSatellite) {
      icon.textContent = 'map_outlined';
      if(label) label.textContent = '地図';
    } else {
      icon.textContent = 'satellite_alt';
      if(label) label.textContent = '航空';
    }
  },

  renderMarkers() {
    // Clear existing markers
    this.markers.forEach(m => m.remove());
    this.markers = [];

    const pins = SampleData.pins.filter(p => {
      if (State.mapFilter === 'sightseeing') return p.pinType === 'sightseeing';
      if (State.mapFilter === 'gourmet') return p.pinType === 'gourmet';
      return true;
    });

    pins.forEach(pin => {
      const isSight = pin.pinType === 'sightseeing';
      const color = isSight ? '#E53935' : '#1565C0';
      const iconHtml = `
        <div style="width:32px;height:32px;background:${color};border-radius:50% 50% 50% 0;transform:rotate(-45deg);display:flex;align-items:center;justify-content:center;box-shadow:0 3px 8px rgba(0,0,0,0.3);cursor:pointer">
          <div style="width:18px;height:18px;background:white;border-radius:50%;transform:rotate(45deg);display:flex;align-items:center;justify-content:center">
            <span style="font-size:10px">${isSight ? '🏔' : '🍴'}</span>
          </div>
        </div>
      `;
      const divIcon = L.divIcon({
        html: iconHtml,
        className: '',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
      });

      const marker = L.marker([pin.lat, pin.lng], { icon: divIcon })
        .addTo(this.map)
        .on('click', (e) => {
          L.DomEvent.stopPropagation(e);
          this.showPinDetail(pin);
          this.map.flyTo([pin.lat, pin.lng], Math.max(this.map.getZoom(), 12), { duration: 0.8 });
        });

      this.markers.push(marker);
    });
  },

  showPinDetail(pin) {
    this.selectedPin = pin;
    const isSaved = State.savedPinIds.has(pin.id);
    const isSight = pin.pinType === 'sightseeing';
    const card = document.getElementById('pin-detail-card');

    card.innerHTML = `
      <div style="display:flex;height:110px">
        <img src="${pin.imageUrl}" style="width:110px;height:110px;object-fit:cover;flex-shrink:0" onerror="this.src='https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200'">
        <div style="flex:1;padding:12px;min-width:0">
          <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">
            <div style="font-size:14px;font-weight:700;color:var(--text-primary);flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${pin.title}</div>
            <button onclick="MapTab.toggleSavePin('${pin.id}')" id="save-pin-${pin.id}" style="background:none;border:none;cursor:pointer;flex-shrink:0">
              <span class="material-icons-round" style="font-size:22px;color:${isSaved?'#FFD700':'var(--text-hint)'}">${isSaved?'bookmark':'bookmark_border'}</span>
            </button>
          </div>
          <div style="display:flex;align-items:center;gap:4px;margin:4px 0">
            <span class="material-icons-round" style="font-size:12px;color:var(--text-hint)">location_on</span>
            <span style="font-size:12px;color:var(--text-hint)">${pin.prefecture}</span>
          </div>
          <div style="display:flex;gap:4px;flex-wrap:wrap;margin:6px 0">
            <span class="pin-badge ${isSight?'sightseeing':'gourmet'}">
              <span class="material-icons-round" style="font-size:11px">${isSight?'landscape':'restaurant'}</span>
              ${isSight?'風景':'グルメ'}
            </span>
          </div>
          <div style="display:flex;align-items:center;gap:4px">
            <img src="${pin.authorAvatar}" class="avatar" style="width:20px;height:20px">
            <span style="font-size:11px;color:var(--text-secondary)">${pin.authorName}</span>
            <span class="material-icons-round" style="font-size:13px;color:#FF6B9D;margin-left:8px">favorite</span>
            <span style="font-size:11px;color:var(--text-secondary)">${pin.likeCount}</span>
          </div>
        </div>
      </div>
      <div style="padding:10px 12px;display:flex;gap:8px;border-top:1px solid var(--border)">
        <div style="flex:1;display:flex;gap:6px;flex-wrap:wrap">${pin.tags.map(t=>`<span class="tag">${t}</span>`).join('')}</div>
        <button onclick="MapTab.openNavigation()" style="background:var(--primary);color:white;border:none;border-radius:12px;padding:8px 14px;font-size:12px;font-weight:700;cursor:pointer;display:flex;align-items:center;gap:4px;white-space:nowrap;font-family:inherit">
          <span class="material-icons-round" style="font-size:14px">navigation</span>
          ナビ
        </button>
      </div>
    `;

    card.classList.add('show');

    // Move location button up
    const fabGroup = document.querySelector('.map-fab-group');
    if (fabGroup) fabGroup.style.bottom = '200px';
  },

  closePinDetail() {
    document.getElementById('pin-detail-card').classList.remove('show');
    this.selectedPin = null;
    const fabGroup = document.querySelector('.map-fab-group');
    if (fabGroup) fabGroup.style.bottom = '24px';
  },

  toggleSavePin(id) {
    if (State.savedPinIds.has(id)) {
      State.savedPinIds.delete(id);
      showSnackbar('保存を解除しました');
    } else {
      State.savedPinIds.add(id);
      showSnackbar('スポットを保存しました ✓');
    }
    // Update icon
    const btn = document.getElementById(`save-pin-${id}`);
    if (btn) {
      const isSaved = State.savedPinIds.has(id);
      btn.querySelector('.material-icons-round').textContent = isSaved ? 'bookmark' : 'bookmark_border';
      btn.querySelector('.material-icons-round').style.color = isSaved ? '#FFD700' : 'var(--text-hint)';
    }
  },

  goToMyLocation() {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        pos => this.map.flyTo([pos.coords.latitude, pos.coords.longitude], 14),
        () => showSnackbar('現在地を取得できませんでした')
      );
    } else {
      showSnackbar('位置情報がサポートされていません');
    }
  },

  openNavigation() {
    if (this.selectedPin) {
      const url = `https://www.google.com/maps/dir/?api=1&destination=${this.selectedPin.lat},${this.selectedPin.lng}&travelmode=driving`;
      window.open(url, '_blank');
    }
  },

  jumpTo(lat, lng) {
    App.switchTab(0);
    setTimeout(() => {
      if (this.map) {
        this.map.flyTo([lat, lng], 14, { duration: 1 });
      }
    }, 300);
  },
};

// ─── Trend Tab ──────────────────────────────────────────────────
const TrendTab = {
  init() {
    this.render();
  },

  switchTab(tab) {
    State.trendTab = tab;
    document.getElementById('trend-tab-spot').classList.toggle('active', tab === 'spot');
    document.getElementById('trend-tab-user').classList.toggle('active', tab === 'user');
    this.render();
  },

  render() {
    const container = document.getElementById('trend-content');
    if (State.trendTab === 'spot') {
      container.innerHTML = this.renderSpotTab();
    } else {
      container.innerHTML = this.renderUserTab();
    }
  },

  renderSpotTab() {
    const hotSpots = SampleData.trends.filter(t => t.isHot).sort((a,b) => b.saveCount - a.saveCount);
    const sightSpots = SampleData.trends.filter(t => t.pinType === 'sightseeing').sort((a,b) => b.saveCount - a.saveCount);
    const gourmetSpots = SampleData.trends.filter(t => t.pinType === 'gourmet').sort((a,b) => b.saveCount - a.saveCount);

    const typeIdx = State.spotTypeIndex;
    const currentSpots = typeIdx === 0 ? sightSpots : gourmetSpots;
    const sectionLabel = typeIdx === 0 ? '風景スポット' : 'グルメスポット';
    const sectionIcon = typeIdx === 0 ? 'landscape' : 'restaurant';
    const sectionColor = typeIdx === 0 ? '#2E7D32' : '#D4915A';
    const sectionCount = currentSpots.length;

    return `
      <!-- HOT Banner -->
      <div style="padding:16px 0 4px">
        <div style="display:flex;align-items:center;gap:6px;padding:0 16px;margin-bottom:10px">
          <div class="hot-badge"><span>🔥</span> 今週のHOT</div>
        </div>
        <div class="hot-scroll">
          ${hotSpots.map(spot => this.renderHotCard(spot)).join('')}
        </div>
      </div>

      <!-- Spot type toggle -->
      <div class="spot-type-toggle">
        <button class="spot-type-btn ${typeIdx===0?'active-sight':''}" onclick="TrendTab.setSpotType(0)">
          <span class="material-icons-round">landscape</span> 風景
        </button>
        <button class="spot-type-btn ${typeIdx===1?'active-gourmet':''}" onclick="TrendTab.setSpotType(1)">
          <span class="material-icons-round">restaurant</span> グルメ
        </button>
      </div>

      <!-- Section label -->
      <div style="display:flex;align-items:center;gap:8px;padding:20px 16px 12px">
        <span class="material-icons-round" style="color:${sectionColor}">${sectionIcon}</span>
        <span style="font-size:17px;font-weight:700">${sectionLabel}</span>
        <span style="background:${sectionColor}1f;color:${sectionColor};font-size:12px;font-weight:600;padding:3px 8px;border-radius:10px">${sectionCount}件</span>
      </div>

      <!-- Trend cards -->
      ${currentSpots.map(spot => this.renderTrendCard(spot, sectionColor)).join('')}
      <div style="height:32px"></div>
    `;
  },

  renderHotCard(spot) {
    const isSaved = State.savedTrendIds.has(spot.id);
    return `
      <div class="hot-card" onclick="MapTab.jumpTo(${spot.lat},${spot.lng})">
        <img src="${spot.imageUrl}" alt="${spot.title}" onerror="this.src='https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200'">
        <div class="gradient-overlay"></div>
        <button onclick="event.stopPropagation();TrendTab.toggleSaveTrend('${spot.id}')" id="save-hot-${spot.id}"
          style="position:absolute;top:8px;right:8px;width:30px;height:30px;border-radius:50%;background:rgba(0,0,0,0.45);border:none;cursor:pointer;display:flex;align-items:center;justify-content:center">
          <span class="material-icons-round" style="font-size:16px;color:${isSaved?'#FFD700':'white'}">${isSaved?'bookmark':'bookmark_border'}</span>
        </button>
        <div class="card-info">
          <div class="card-title">${spot.title}</div>
          <div class="card-pref">${spot.prefecture}</div>
        </div>
      </div>
    `;
  },

  renderTrendCard(spot, accentColor) {
    const isSaved = State.savedTrendIds.has(spot.id);
    const isSight = spot.pinType === 'sightseeing';
    return `
      <div class="card trend-card">
        <div class="trend-card-img-wrap">
          <img src="${spot.imageUrl}" alt="${spot.title}" onerror="this.src='https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200'">
          ${spot.isHot ? '<div style="position:absolute;top:10px;left:10px"><div class="hot-badge"><span>🔥</span> HOT</div></div>' : ''}
          <button onclick="TrendTab.toggleSaveTrend('${spot.id}')" id="save-trend-${spot.id}"
            style="position:absolute;top:10px;right:10px;width:34px;height:34px;border-radius:50%;background:rgba(0,0,0,0.45);border:none;cursor:pointer;display:flex;align-items:center;justify-content:center">
            <span class="material-icons-round" style="font-size:18px;color:${isSaved?'#FFD700':'white'}">${isSaved?'bookmark':'bookmark_border'}</span>
          </button>
        </div>
        <div class="trend-card-body">
          <div style="display:flex;align-items:center;gap:4px">
            <span class="material-icons-round" style="font-size:13px;color:var(--text-hint)">location_on</span>
            <span style="font-size:12px;color:var(--text-hint)">${spot.prefecture}</span>
          </div>
          <div class="trend-card-title">${spot.title}</div>
          <div class="trend-card-desc">${spot.description}</div>
          <div style="display:flex;flex-wrap:wrap;gap:6px;margin:8px 0">${renderTags(spot.tags)}</div>
          <div style="display:flex;align-items:center;justify-content:space-between">
            <div style="display:flex;align-items:center;gap:8px">
              <span class="pin-badge ${isSight?'sightseeing':'gourmet'}">
                <span class="material-icons-round" style="font-size:11px">${isSight?'landscape':'restaurant'}</span>
                ${isSight?'風景':'グルメ'}
              </span>
              <span style="display:flex;align-items:center;gap:3px;font-size:12px;color:var(--text-hint)">
                <span class="material-icons-round" style="font-size:13px;color:#FFAA00">bookmark</span>
                ${spot.saveCount} 保存
              </span>
            </div>
            <button onclick="MapTab.jumpTo(${spot.lat},${spot.lng})" 
              style="background:${accentColor};color:white;border:none;border-radius:20px;padding:8px 14px;font-size:12px;font-weight:700;cursor:pointer;display:flex;align-items:center;gap:4px;box-shadow:0 3px 8px ${accentColor}55;font-family:inherit">
              <span class="material-icons-round" style="font-size:13px">map</span>
              マップで見る
            </button>
          </div>
        </div>
      </div>
    `;
  },

  renderUserTab() {
    return `
      <div style="padding:16px">
        <div style="position:relative;margin-bottom:20px">
          <span class="material-icons-round" style="position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--text-hint);font-size:20px">search</span>
          <input type="text" id="user-search-input" placeholder="ユーザーIDまたは名前で検索..."
            style="width:100%;padding:14px 14px 14px 44px;border-radius:14px;border:1px solid var(--border);background:var(--primary-very-light);font-size:14px;font-family:inherit;color:var(--text-primary);outline:none"
            oninput="TrendTab.searchUsers(this.value)">
        </div>
        <div id="user-search-results">
          <div style="text-align:center;padding:40px;color:var(--text-hint)">
            <span class="material-icons-round" style="font-size:48px">person_search</span>
            <div style="margin-top:8px;font-size:14px">ユーザーIDや名前を入力して検索</div>
          </div>
        </div>
      </div>
    `;
  },

  setSpotType(idx) {
    State.spotTypeIndex = idx;
    this.render();
  },

  toggleSaveTrend(id) {
    if (State.savedTrendIds.has(id)) {
      State.savedTrendIds.delete(id);
      showSnackbar('保存を解除しました');
    } else {
      State.savedTrendIds.add(id);
      showSnackbar('保存しました ✓');
    }
    // Update buttons
    [`save-hot-${id}`, `save-trend-${id}`].forEach(btnId => {
      const btn = document.getElementById(btnId);
      if (btn) {
        const isSaved = State.savedTrendIds.has(id);
        const icon = btn.querySelector('.material-icons-round');
        if (icon) {
          icon.textContent = isSaved ? 'bookmark' : 'bookmark_border';
          icon.style.color = isSaved ? '#FFD700' : 'white';
        }
      }
    });
    // Refresh saved tab if open
    if (State.currentTab === 4 && State.profileTab === 'saved') {
      ProfileTab.renderSavedTab();
    }
  },

  searchUsers(query) {
    const q = query.trim().toLowerCase();
    const resultsEl = document.getElementById('user-search-results');
    if (!resultsEl) return;

    if (!q) {
      resultsEl.innerHTML = `
        <div style="text-align:center;padding:40px;color:var(--text-hint)">
          <span class="material-icons-round" style="font-size:48px">person_search</span>
          <div style="margin-top:8px;font-size:14px">ユーザーIDや名前を入力して検索</div>
        </div>
      `;
      return;
    }

    const results = SampleData.sampleUsers.filter(u =>
      u.customId.toLowerCase().includes(q) || u.name.toLowerCase().includes(q)
    );

    if (!results.length) {
      resultsEl.innerHTML = `
        <div style="text-align:center;padding:40px;color:var(--text-hint)">
          <span class="material-icons-round" style="font-size:48px">search_off</span>
          <div style="margin-top:8px;font-size:14px">「${query}」に一致するユーザーが見つかりません</div>
        </div>
      `;
      return;
    }

    resultsEl.innerHTML = results.map(u => `
      <div class="user-card" onclick="App.openUserProfile(${JSON.stringify(u).replace(/"/g,'&quot;')})">
        <img src="${u.avatarUrl}" class="avatar" style="width:52px;height:52px">
        <div class="user-card-info">
          <div class="user-card-name">${u.name}</div>
          <div class="user-card-id">@${u.customId}</div>
          <div class="user-card-bio">${u.bio}</div>
        </div>
        <div style="text-align:right">
          <div style="font-size:13px;font-weight:700">${formatNumber(u.followerCount)}</div>
          <div style="font-size:11px;color:var(--text-hint)">フォロワー</div>
        </div>
      </div>
    `).join('');
  },
};

// ─── Pref (Prefecture) Tab ──────────────────────────────────────
const PrefTab = {
  regionMap: {
    '北海道': ['北海道'],
    '東北': ['青森県','岩手県','宮城県','秋田県','山形県','福島県'],
    '関東': ['茨城県','栃木県','群馬県','埼玉県','千葉県','東京都','神奈川県'],
    '中部': ['新潟県','富山県','石川県','福井県','山梨県','長野県','岐阜県','静岡県','愛知県'],
    '近畿': ['三重県','滋賀県','京都府','大阪府','兵庫県','奈良県','和歌山県'],
    '中国': ['鳥取県','島根県','岡山県','広島県','山口県'],
    '四国': ['徳島県','香川県','愛媛県','高知県'],
    '九州・沖縄': ['福岡県','佐賀県','長崎県','熊本県','大分県','宮崎県','鹿児島県','沖縄県'],
  },

  init() {
    // Render region chips
    const regionScroll = document.getElementById('region-scroll');
    if (regionScroll) {
      regionScroll.innerHTML = Object.keys(this.regionMap).map(region => `
        <div class="region-chip" id="region-chip-${region}" onclick="PrefTab.onRegionClick('${region}')">
          ${region}
        </div>
      `).join('');
    }

    // Shuffle items
    State.prefTabItems = {
      sight: shuffleArray(SampleData.sightseeingList).slice(0, 30),
      gourmet: shuffleArray(SampleData.gourmetList).slice(0, 30),
      hotel: shuffleArray(SampleData.hotelList).slice(0, 30),
    };

    this.render();
  },

  onRegionClick(region) {
    const prefs = this.regionMap[region];
    if (prefs.length === 1) {
      State.prefFilter = prefs[0];
      this.updateFilterUI();
      this.render();
    } else {
      this.showRegionSheet(region, prefs);
    }
  },

  switchGenre(genre) {
    State.prefGenre = genre;
    ['sight','gourmet','hotel'].forEach(g => {
      document.getElementById(`genre-tab-${g}`)?.classList.toggle('active', g === genre);
    });
    this.render();
  },

  refresh() {
    const icon = document.getElementById('pref-refresh-icon');
    if (icon) icon.style.animation = 'spin 0.6s linear';
    State.prefTabItems = {
      sight: shuffleArray(SampleData.sightseeingList).slice(0, 30),
      gourmet: shuffleArray(SampleData.gourmetList).slice(0, 30),
      hotel: shuffleArray(SampleData.hotelList).slice(0, 30),
    };
    this.render();
    setTimeout(() => { if (icon) icon.style.animation = ''; }, 600);
  },

  getFilteredItems(genre) {
    const allData = { sight: SampleData.sightseeingList, gourmet: SampleData.gourmetList, hotel: SampleData.hotelList }[genre];
    if (State.prefFilter) {
      return allData.filter(item => item.prefecture === State.prefFilter);
    }
    return State.prefTabItems[genre];
  },

  render() {
    const items = this.getFilteredItems(State.prefGenre);
    const genreColors = { sight: '#5BA4CF', gourmet: '#D4915A', hotel: '#9B7EBF' };
    const genreIcons = { sight: 'photo_camera', gourmet: 'restaurant', hotel: 'hotel' };
    const color = genreColors[State.prefGenre];
    const icon = genreIcons[State.prefGenre];

    const container = document.getElementById('pref-content');
    if (!container) return;

    if (items.length === 0) {
      container.innerHTML = `
        <div class="empty-state">
          <span class="material-icons-round" style="color:${color}66">${icon}</span>
          <div class="empty-state-title">${State.prefFilter}の情報はまだありません</div>
          <div class="empty-state-text">別の都道府県を選択してください</div>
        </div>
      `;
      return;
    }

    container.innerHTML = items.map(item => `
      <div class="recommend-card" onclick="window.open('${item.url}','_blank')">
        <img src="${item.imageUrl}" class="recommend-card-img" alt="${item.title}" onerror="this.src='https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200'">
        <div class="recommend-card-body">
          <div class="recommend-card-site" style="color:${color}">
            <span class="material-icons-round" style="font-size:12px;vertical-align:middle">open_in_new</span>
            ${item.siteName}
          </div>
          <div class="recommend-card-title">${item.title}</div>
          <div class="recommend-card-area">
            <span class="material-icons-round" style="font-size:12px">location_on</span>
            ${item.area}
          </div>
          <div class="recommend-card-desc">${item.description}</div>
          <div style="display:flex;align-items:center;justify-content:space-between;margin-top:10px">
            <div style="display:flex;flex-wrap:wrap;gap:4px">${renderTags(item.tags)}</div>
            ${item.rating ? `<div class="rating"><span class="rating-stars">${renderStars(item.rating)}</span><span class="rating-num">${item.rating}</span></div>` : ''}
          </div>
        </div>
      </div>
    `).join('') + '<div style="height:20px"></div>';
  },

  updateFilterUI() {
    const textEl = document.getElementById('pref-selected-text');
    const clearBtn = document.getElementById('pref-clear-btn');
    if (textEl) textEl.textContent = State.prefFilter || 'すべての都道府県';
    if (clearBtn) clearBtn.style.display = State.prefFilter ? 'flex' : 'none';

    // Update region chips
    Object.entries(this.regionMap).forEach(([region, prefs]) => {
      const chip = document.getElementById(`region-chip-${region}`);
      if (chip) chip.classList.toggle('active', prefs.includes(State.prefFilter));
    });
  },

  clearPref() {
    State.prefFilter = null;
    this.updateFilterUI();
    this.render();
  },

  showPrefSheet() {
    const body = document.getElementById('pref-sheet-body');
    body.innerHTML = Object.entries(this.regionMap).map(([region, prefs]) => `
      <div class="pref-section-title">${region}</div>
      <div class="pref-chips-wrap">
        ${prefs.map(p => `
          <div class="pref-chip ${State.prefFilter === p ? 'selected' : ''}" onclick="PrefTab.selectPref('${p}')">
            ${p}
          </div>
        `).join('')}
      </div>
      <hr style="border:none;border-top:1px solid var(--border);margin:8px 0">
    `).join('');
    showBottomSheet('modal-pref-sheet');
  },

  closePrefSheet(e) {
    if (e.target.id === 'modal-pref-sheet') hideBottomSheet('modal-pref-sheet');
  },

  clearPrefAndClose() {
    State.prefFilter = null;
    this.updateFilterUI();
    this.render();
    hideBottomSheet('modal-pref-sheet');
  },

  selectPref(pref) {
    State.prefFilter = pref;
    this.updateFilterUI();
    this.render();
    hideBottomSheet('modal-pref-sheet');
  },

  showRegionSheet(region, prefs) {
    const body = document.getElementById('region-sheet-body');
    body.innerHTML = `
      <div style="font-size:16px;font-weight:700;margin-bottom:12px">${region} の都道府県</div>
      <div class="pref-chips-wrap">
        ${prefs.map(p => `
          <div class="pref-chip ${State.prefFilter === p ? 'selected' : ''}" onclick="PrefTab.selectPrefFromRegion('${p}')">
            ${p}
          </div>
        `).join('')}
      </div>
    `;
    showBottomSheet('modal-region-sheet');
  },

  closeRegionSheet(e) {
    if (e.target.id === 'modal-region-sheet') hideBottomSheet('modal-region-sheet');
  },

  selectPrefFromRegion(pref) {
    State.prefFilter = pref;
    this.updateFilterUI();
    this.render();
    hideBottomSheet('modal-region-sheet');
  },
};

// ─── Profile Tab ────────────────────────────────────────────────
const ProfileTab = {
  init() {
    this.renderHeader();
    this.renderProfileTab();
  },

  renderHeader() {
    const area = document.getElementById('profile-header-area');
    const u = State.user;
    area.innerHTML = `
      <div class="profile-avatar-row">
        <img src="${u.avatarUrl}" class="profile-avatar" alt="Avatar" onerror="this.style.background='var(--primary-light)'">
        <div style="flex:1;min-width:0">
          <div style="display:flex;align-items:center;gap:8px">
            <div class="profile-name">${u.name}</div>
            <button onclick="ProfileTab.openEdit()" style="background:rgba(255,255,255,0.2);border:none;border-radius:50%;width:30px;height:30px;cursor:pointer;display:flex;align-items:center;justify-content:center">
              <span class="material-icons-round" style="font-size:16px;color:white">edit</span>
            </button>
          </div>
          ${u.customId ? `<div class="profile-id">@${u.customId}</div>` : ''}
          <div class="profile-bio">${u.bio || '<em style="opacity:0.55">タップして紹介文を追加しよう</em>'}</div>
        </div>
      </div>
      <div class="stat-row">
        <div class="stat-item"><div class="stat-num">${State.savedPinIds.size + State.savedTrendIds.size}</div><div class="stat-label">保存済み</div></div>
        <div class="stat-item"><div class="stat-num">${u.pinCount}</div><div class="stat-label">投稿</div></div>
        <div class="stat-item"><div class="stat-num">${State.followingIds.size}</div><div class="stat-label">フォロー</div></div>
      </div>
      <div style="margin-top:10px">
        <button onclick="ProfileTab.openEdit()" class="profile-edit-btn">
          <span class="material-icons-round" style="font-size:15px">edit</span>
          プロフィールを編集
        </button>
      </div>
    `;
  },

  switchTab(tab) {
    State.profileTab = tab;
    ['profile','saved','follow'].forEach(t => {
      document.getElementById(`ptab-${t}`).classList.toggle('active', t === tab);
    });
    switch(tab) {
      case 'profile': this.renderProfileTab(); break;
      case 'saved': this.renderSavedTab(); break;
      case 'follow': this.renderFollowTab(); break;
    }
  },

  renderProfileTab() {
    const u = State.user;
    const snsMeta = [
      { key:'instagram', label:'Instagram', icon:'camera_alt', color:'linear-gradient(135deg,#F58529,#DD2A7B,#8134AF)' },
      { key:'youtube', label:'YouTube', icon:'play_circle_fill', color:'linear-gradient(135deg,#FF0000,#CC0000)' },
      { key:'x', label:'X', icon:'close', color:'linear-gradient(135deg,#1A1A1A,#444444)' },
      { key:'tiktok', label:'TikTok', icon:'music_note', color:'linear-gradient(135deg,#010101,#69C9D0)' },
    ];
    const urls = { instagram: u.instagramUrl, youtube: u.youtubeUrl, x: u.xUrl, tiktok: u.tiktokUrl };
    const activeSns = snsMeta.filter(s => urls[s.key]);

    document.getElementById('profile-content').innerHTML = `
      ${activeSns.length > 0 ? `
        <div class="sns-row">
          ${activeSns.map(s => `
            <div class="sns-btn" style="background:${s.color}" onclick="window.open('${urls[s.key]}','_blank')">
              <span class="material-icons-round">${s.icon}</span>${s.label}
            </div>
          `).join('')}
        </div>
      ` : ''}

      <!-- Settings sections -->
      <div style="padding:12px 16px 4px;font-size:13px;font-weight:600;color:var(--text-secondary)">アカウント</div>
      <div class="settings-section">
        <div class="settings-item" onclick="ProfileTab.openEdit()">
          <div class="settings-icon" style="background:#E3F4FC"><span class="material-icons-round" style="color:var(--primary)">person</span></div>
          <span class="settings-label">プロフィールを編集</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
        <div class="settings-item" onclick="showSnackbar('準備中です')">
          <div class="settings-icon" style="background:#E3F4FC"><span class="material-icons-round" style="color:var(--primary)">notifications</span></div>
          <span class="settings-label">通知設定</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
      </div>

      <div style="padding:12px 16px 4px;font-size:13px;font-weight:600;color:var(--text-secondary)">サブスクリプション</div>
      <div class="settings-section">
        <div class="settings-item" onclick="window.open('https://apps.apple.com/account/subscriptions','_blank')">
          <div class="settings-icon" style="background:#E8F5E9"><span class="material-icons-round" style="color:#43A047">star</span></div>
          <span class="settings-label">サブスクリプション管理</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
      </div>

      <div style="padding:12px 16px 4px;font-size:13px;font-weight:600;color:var(--text-secondary)">法的情報</div>
      <div class="settings-section">
        <div class="settings-item" onclick="App.openTerms()">
          <div class="settings-icon" style="background:#F3E5F5"><span class="material-icons-round" style="color:#9C27B0">description</span></div>
          <span class="settings-label">利用規約</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
        <div class="settings-item" onclick="App.openPrivacy()">
          <div class="settings-icon" style="background:#FFF3E0"><span class="material-icons-round" style="color:#FF9800">privacy_tip</span></div>
          <span class="settings-label">プライバシーポリシー</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
      </div>

      <div style="padding:12px 16px 4px;font-size:13px;font-weight:600;color:var(--text-secondary)">サポート</div>
      <div class="settings-section">
        <div class="settings-item" onclick="showSnackbar('お問い合わせフォームを開いています...')">
          <div class="settings-icon" style="background:#E3F4FC"><span class="material-icons-round" style="color:var(--primary)">help</span></div>
          <span class="settings-label">サポート・お問い合わせ</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
      </div>

      <div style="padding:12px 16px 4px;font-size:13px;font-weight:600;color:var(--text-secondary)">アカウント管理</div>
      <div class="settings-section">
        <div class="settings-item" onclick="ProfileTab.confirmLogout()">
          <div class="settings-icon" style="background:#FFF3E0"><span class="material-icons-round" style="color:#FF9800">logout</span></div>
          <span class="settings-label">ログアウト</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
        <div class="settings-item" onclick="ProfileTab.confirmDeleteAccount()">
          <div class="settings-icon" style="background:#FFEBEE"><span class="material-icons-round" style="color:#E53935">delete_forever</span></div>
          <span class="settings-label" style="color:#E53935">アカウントを削除</span>
          <div class="settings-chevron"><span class="material-icons-round">chevron_right</span></div>
        </div>
      </div>

      <div style="text-align:center;padding:20px;color:var(--text-hint);font-size:12px">
        Shot map v1.0.3<br>
        <span style="font-size:11px">© 2024 Shot Map</span>
      </div>
    `;
  },

  renderSavedTab() {
    const savedPins = SampleData.pins.filter(p => State.savedPinIds.has(p.id));
    const savedTrends = SampleData.trends.filter(t => State.savedTrendIds.has(t.id));
    const all = [
      ...savedPins.map(p => ({ ...p, _type:'pin' })),
      ...savedTrends.map(t => ({ ...t, _type:'trend' })),
    ];

    const el = document.getElementById('profile-content');
    if (!all.length) {
      el.innerHTML = `
        <div class="empty-state">
          <span class="material-icons-round">bookmark_border</span>
          <div class="empty-state-title">保存済みスポットがありません</div>
          <div class="empty-state-text">マップやトレンドからスポットを保存すると<br>ここに表示されます</div>
        </div>
      `;
      return;
    }

    el.innerHTML = `
      <div style="padding:16px">
        <div class="section-title" style="margin-bottom:14px">
          <span class="material-icons-round" style="color:var(--primary)">bookmark</span>
          保存済みスポット
          <span style="background:var(--primary-very-light);color:var(--primary);font-size:12px;font-weight:600;padding:3px 8px;border-radius:10px">${all.length}件</span>
        </div>
        <div class="saved-grid">
          ${all.map(item => `
            <div class="saved-card" onclick="${item._type==='pin'?`MapTab.jumpTo(${item.lat},${item.lng})`:`MapTab.jumpTo(${item.lat},${item.lng})`}">
              <img src="${item.imageUrl}" class="saved-card-img" alt="${item.title}" onerror="this.src='https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200'">
              <div class="saved-card-body">
                <div class="saved-card-title">${item.title}</div>
                <div class="saved-card-pref">
                  <span class="material-icons-round" style="font-size:11px;vertical-align:middle">location_on</span>
                  ${item.prefecture}
                </div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    `;
  },

  renderFollowTab() {
    const el = document.getElementById('profile-content');
    const followingUsers = SampleData.sampleUsers.filter(u => State.followingIds.has(u.uid));

    if (!followingUsers.length) {
      el.innerHTML = `
        <div class="empty-state">
          <span class="material-icons-round">people_outline</span>
          <div class="empty-state-title">フォロー中のユーザーがいません</div>
          <div class="empty-state-text">トレンドのユーザー検索からフォローできます</div>
        </div>
      `;
      return;
    }

    el.innerHTML = `
      <div style="padding:0 16px">
        <div style="font-size:14px;color:var(--text-hint);padding:12px 0;border-bottom:1px solid var(--border)">
          フォロー中 ${followingUsers.length}人
        </div>
        ${followingUsers.map(u => `
          <div class="follow-item" onclick="App.openUserProfile(${JSON.stringify(u).replace(/"/g,'&quot;')})">
            <img src="${u.avatarUrl}" class="avatar" style="width:48px;height:48px">
            <div class="follow-item-info">
              <div class="follow-item-name">${u.name}</div>
              <div class="follow-item-id">@${u.customId}</div>
            </div>
            <button onclick="event.stopPropagation();App.toggleFollow('${u.uid}')" id="flist-${u.uid}"
              class="follow-btn following">フォロー中</button>
          </div>
        `).join('')}
      </div>
    `;
  },

  openEdit() {
    // Show edit modal
    const u = State.user;
    showAlert(
      'プロフィールを編集',
      `
        <div style="margin-bottom:12px">
          <label style="font-size:12px;font-weight:600;color:var(--text-secondary);display:block;margin-bottom:4px">表示名</label>
          <input id="edit-name" type="text" value="${u.name}" style="width:100%;padding:10px 12px;border-radius:10px;border:1px solid var(--border);font-size:14px;font-family:inherit;outline:none" maxlength="30">
        </div>
        <div style="margin-bottom:12px">
          <label style="font-size:12px;font-weight:600;color:var(--text-secondary);display:block;margin-bottom:4px">カスタムID (@)</label>
          <input id="edit-custom-id" type="text" value="${u.customId}" style="width:100%;padding:10px 12px;border-radius:10px;border:1px solid var(--border);font-size:14px;font-family:inherit;outline:none" maxlength="20">
        </div>
        <div>
          <label style="font-size:12px;font-weight:600;color:var(--text-secondary);display:block;margin-bottom:4px">自己紹介</label>
          <textarea id="edit-bio" rows="2" style="width:100%;padding:10px 12px;border-radius:10px;border:1px solid var(--border);font-size:14px;font-family:inherit;outline:none;resize:none" maxlength="150">${u.bio}</textarea>
        </div>
      `,
      [
        { label:'キャンセル', className:'alert-btn-cancel' },
        { label:'保存', className:'alert-btn-ok', action() {
          State.user.name = document.getElementById('edit-name').value.trim() || u.name;
          State.user.customId = document.getElementById('edit-custom-id').value.trim() || u.customId;
          State.user.bio = document.getElementById('edit-bio').value.trim();
          ProfileTab.renderHeader();
          ProfileTab.renderProfileTab();
          showSnackbar('プロフィールを更新しました ✓');
        }},
      ]
    );
  },

  confirmLogout() {
    showAlert(
      'ログアウト',
      'ログアウトしてもよろしいですか？',
      [
        { label:'キャンセル', className:'alert-btn-cancel' },
        { label:'ログアウト', className:'alert-btn-ok', action() {
          document.getElementById('screen-main').style.display = 'none';
          document.getElementById('screen-login').classList.add('active');
          showSnackbar('ログアウトしました');
        }},
      ]
    );
  },

  confirmDeleteAccount() {
    showAlert(
      'アカウント削除',
      '本当に削除しますか？<br><br>アカウントを削除すると、以下のデータがすべて失われます：<br>・投稿したすべてのピン<br>・保存済みスポット<br>・フォロー情報<br><br><strong style="color:#E53935">この操作は取り消せません。</strong>',
      [
        { label:'キャンセル', className:'alert-btn-cancel' },
        { label:'削除する', className:'alert-btn-danger', action() {
          showSnackbar('アカウントを削除しました');
          setTimeout(() => {
            document.getElementById('screen-main').style.display = 'none';
            document.getElementById('screen-login').classList.add('active');
          }, 1000);
        }},
      ]
    );
  },
};

// ─── Post Screen ────────────────────────────────────────────────
const PostScreen = {
  photos: [null, null, null, null, null],
  tags: [],
  pinType: null,
  selectedPref: '東京都',
  useCurrentLocation: true,

  prefectures: [
    '北海道','青森県','岩手県','宮城県','秋田県','山形県','福島県',
    '茨城県','栃木県','群馬県','埼玉県','千葉県','東京都','神奈川県',
    '新潟県','富山県','石川県','福井県','山梨県','長野県','岐阜県',
    '静岡県','愛知県','三重県','滋賀県','京都府','大阪府','兵庫県',
    '奈良県','和歌山県','鳥取県','島根県','岡山県','広島県','山口県',
    '徳島県','香川県','愛媛県','高知県','福岡県','佐賀県','長崎県',
    '熊本県','大分県','宮崎県','鹿児島県','沖縄県',
  ],

  init() {
    this.photos = [null, null, null, null, null];
    this.tags = [];
    this.pinType = null;
  },

  render() {
    const el = document.getElementById('post-form-content');
    el.innerHTML = `
      <!-- Pin type -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">push_pin</span>
          ピンの種類 <span class="required">必須</span>
        </div>
        <div class="pin-type-row">
          <button class="pin-type-btn ${this.pinType==='sightseeing'?'selected-sight':''}" onclick="PostScreen.setPinType('sightseeing')">
            <span class="material-icons-round">landscape</span> 風景
          </button>
          <button class="pin-type-btn ${this.pinType==='gourmet'?'selected-gourmet':''}" onclick="PostScreen.setPinType('gourmet')">
            <span class="material-icons-round">restaurant</span> グルメ
          </button>
        </div>
      </div>

      <!-- Photos -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">photo_camera</span>
          写真 <span class="required">必須</span>
          <span style="font-size:11px;color:var(--text-hint);font-weight:400">(最大5枚)</span>
        </div>
        <div class="photo-grid" id="photo-grid">
          ${this.photos.map((p, i) => `
            <div class="photo-slot" onclick="PostScreen.tapPhotoSlot(${i})">
              ${p 
                ? `<img src="${p}" alt="Photo ${i+1}">`
                : `<span class="material-icons-round">${i === 0 ? 'add_photo_alternate' : 'add'}</span>`
              }
            </div>
          `).join('')}
        </div>
      </div>

      <!-- Title -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">title</span>
          スポット名 <span class="required">必須</span>
        </div>
        <input class="form-input" id="post-title" type="text" placeholder="例：竹林の小径" maxlength="50">
      </div>

      <!-- Description -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">description</span>
          説明文
        </div>
        <textarea class="form-input" id="post-desc" rows="3" placeholder="スポットの魅力を教えてください..." style="resize:none" maxlength="500"></textarea>
      </div>

      <!-- Timing -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">schedule</span>
          おすすめの時間帯・時期 <span class="required">必須</span>
        </div>
        <input class="form-input" id="post-timing" type="text" placeholder="例：早朝・桜の季節（3月〜4月）">
      </div>

      <!-- Prefecture -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">location_on</span>
          都道府県 <span class="required">必須</span>
        </div>
        <select class="form-input" id="post-pref" onchange="PostScreen.selectedPref=this.value" style="appearance:none;-webkit-appearance:none;background-image:url('data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22><path fill=%22%23ADC3D1%22 d=%22M7 10l5 5 5-5z%22/></svg>');background-repeat:no-repeat;background-position:right 12px center;background-size:20px">
          ${this.prefectures.map(p => `<option value="${p}" ${p === this.selectedPref ? 'selected' : ''}>${p}</option>`).join('')}
        </select>
      </div>

      <!-- Location mode -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">my_location</span>
          位置情報
        </div>
        <div style="display:flex;gap:8px;margin-bottom:10px">
          <button onclick="PostScreen.setLocationMode(true)" id="loc-mode-gps"
            class="pin-type-btn ${this.useCurrentLocation?'selected-sight':''}" style="flex:1;font-size:13px">
            <span class="material-icons-round" style="font-size:16px">gps_fixed</span>
            現在地を使用
          </button>
          <button onclick="PostScreen.setLocationMode(false)" id="loc-mode-map"
            class="pin-type-btn ${!this.useCurrentLocation?'selected-gourmet':''}" style="flex:1;font-size:13px">
            <span class="material-icons-round" style="font-size:16px">map</span>
            マップから選択
          </button>
        </div>
      </div>

      <!-- Tags -->
      <div class="form-group">
        <div class="form-label">
          <span class="material-icons-round" style="font-size:16px">tag</span>
          タグ
          <span style="font-size:11px;color:var(--text-hint);font-weight:400">(最大5個)</span>
        </div>
        <div style="display:flex;gap:8px">
          <input class="form-input" id="post-tag" type="text" placeholder="#タグを入力" style="flex:1"
            onkeydown="if(event.key==='Enter')PostScreen.addTag()">
          <button onclick="PostScreen.addTag()" class="btn-primary" style="padding:12px 16px;border-radius:12px;font-size:13px;white-space:nowrap">追加</button>
        </div>
        <div id="tags-display" style="display:flex;flex-wrap:wrap;gap:6px;margin-top:10px">
          ${this.tags.map((t,i) => `
            <div style="display:inline-flex;align-items:center;gap:4px;background:var(--tag-blue);border-radius:12px;padding:4px 10px">
              <span style="font-size:12px;font-weight:600;color:var(--primary)">${t}</span>
              <span onclick="PostScreen.removeTag(${i})" style="cursor:pointer;color:var(--text-hint);font-size:14px;line-height:1">×</span>
            </div>
          `).join('')}
        </div>
      </div>

      <div style="height:40px"></div>
    `;
  },

  setPinType(type) {
    this.pinType = type;
    this.render();
  },

  setLocationMode(useGps) {
    this.useCurrentLocation = useGps;
    const gpsBtn = document.getElementById('loc-mode-gps');
    const mapBtn = document.getElementById('loc-mode-map');
    if (gpsBtn) {
      gpsBtn.className = `pin-type-btn ${useGps?'selected-sight':''}`;
      gpsBtn.style.flex = '1';
      gpsBtn.style.fontSize = '13px';
    }
    if (mapBtn) {
      mapBtn.className = `pin-type-btn ${!useGps?'selected-gourmet':''}`;
      mapBtn.style.flex = '1';
      mapBtn.style.fontSize = '13px';
    }
  },

  tapPhotoSlot(index) {
    if (this.photos[index]) {
      showAlert('写真を削除', 'この写真を削除しますか？', [
        { label:'キャンセル', className:'alert-btn-cancel' },
        { label:'削除', className:'alert-btn-danger', action: () => {
          this.photos[index] = null;
          this.render();
        }},
      ]);
    } else {
      // Show demo images
      const demoUrls = [
        'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=200',
        'https://images.unsplash.com/photo-1490806843957-31f4c9a91c65?w=200',
        'https://images.unsplash.com/photo-1478436127897-769e1b3f0f36?w=200',
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=200',
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
      ];
      this.photos[index] = demoUrls[index];
      this.render();
    }
  },

  addTag() {
    const input = document.getElementById('post-tag');
    let tag = input.value.trim();
    if (!tag || this.tags.length >= 5) return;
    if (!tag.startsWith('#')) tag = '#' + tag;
    this.tags.push(tag);
    input.value = '';

    const display = document.getElementById('tags-display');
    if (display) {
      display.innerHTML = this.tags.map((t,i) => `
        <div style="display:inline-flex;align-items:center;gap:4px;background:var(--tag-blue);border-radius:12px;padding:4px 10px">
          <span style="font-size:12px;font-weight:600;color:var(--primary)">${t}</span>
          <span onclick="PostScreen.removeTag(${i})" style="cursor:pointer;color:var(--text-hint);font-size:14px;line-height:1">×</span>
        </div>
      `).join('');
    }
  },

  removeTag(index) {
    this.tags.splice(index, 1);
    const display = document.getElementById('tags-display');
    if (display) {
      display.innerHTML = this.tags.map((t,i) => `
        <div style="display:inline-flex;align-items:center;gap:4px;background:var(--tag-blue);border-radius:12px;padding:4px 10px">
          <span style="font-size:12px;font-weight:600;color:var(--primary)">${t}</span>
          <span onclick="PostScreen.removeTag(${i})" style="cursor:pointer;color:var(--text-hint);font-size:14px;line-height:1">×</span>
        </div>
      `).join('');
    }
  },

  submit() {
    const title = document.getElementById('post-title')?.value.trim();
    const photoCount = this.photos.filter(p => p !== null).length;
    const timing = document.getElementById('post-timing')?.value.trim();

    if (!this.pinType) {
      showSnackbar('ピンの種類を選択してください');
      return;
    }
    if (!title) {
      showSnackbar('スポット名を入力してください');
      return;
    }
    if (!photoCount) {
      showSnackbar('写真を1枚以上追加してください');
      return;
    }
    if (!timing) {
      showSnackbar('おすすめの時間帯・時期を入力してください');
      return;
    }

    const btn = document.getElementById('post-submit-btn');
    if (btn) { btn.disabled = true; btn.textContent = '投稿中...'; }

    setTimeout(() => {
      App.closePost();
      State.user.pinCount += 1;
      ProfileTab.renderHeader();
      showSnackbar('スポットを投稿しました 🎉');
      // Reset
      this.photos = [null, null, null, null, null];
      this.tags = [];
      this.pinType = null;
      if (btn) { btn.disabled = false; btn.textContent = '投稿'; }
    }, 800);
  },
};

// ─── Initialize ─────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  // Close alert on overlay click
  document.getElementById('alert-overlay').addEventListener('click', function(e) {
    if (e.target === this) closeAlert();
  });

  // Auto-login for demo
  // Uncomment below to start from login screen:
  // (currently auto-shows main app for demo convenience)
  App.loginAsGuest();
});
