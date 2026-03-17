import 'package:flutter/material.dart';
// ignore_for_file: unused_field
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/data_models.dart';
import '../models/user_profile_provider.dart';

class TrendScreen extends StatefulWidget {
  final Function(double lat, double lng)? onJumpToMap;

  const TrendScreen({super.key, this.onJumpToMap});

  @override
  State<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends State<TrendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;
  final List<String> _tabs = ['スポット', 'ユーザー検索'];

  // ─── ID 検索 ───
  final TextEditingController _searchCtrl = TextEditingController();
  List<AppUser> _searchResults = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── ID 検索ロジック ───
  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _hasSearched = true;
      if (q.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = SampleData.sampleUsers.where((u) {
          return u.customId.toLowerCase().contains(q) ||
              u.name.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildSliverHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSpotTab(),
                _buildUserSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ヘッダー（タイトルなし・タブのみ） ───
  Widget _buildSliverHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: const SizedBox(height: 4),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.notoSansJp(fontWeight: FontWeight.w400, fontSize: 14),
        tabs: [
          const Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'スポット'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_search, size: 18),
                const SizedBox(width: 4),
                Text('ユーザー検索', style: GoogleFonts.notoSansJp(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // スポット タブ
  // ═══════════════════════════════════════════
  Widget _buildSpotTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHotBanner()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'すべてのトレンドスポット',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${SampleData.trends.length}件',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: EdgeInsets.only(
                top: index == 0 ? 12 : 0,
                bottom: index == SampleData.trends.length - 1 ? 24 : 0,
              ),
              child: _buildTrendCard(SampleData.trends[index]),
            ),
            childCount: SampleData.trends.length,
          ),
        ),
      ],
    );
  }

  Widget _buildHotBanner() {
    final hotSpots = SampleData.trends.where((t) => t.isHot).toList();
    if (hotSpots.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF6B9D)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '今週のHOT',
                        style: GoogleFonts.notoSansJp(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hotSpots.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildHotCard(hotSpots[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotCard(TrendSpot spot) {
    return Consumer<UserProfileProvider>(
      builder: (_, provider, __) {
        final isSaved = provider.isSavedTrend(spot.id);
        return GestureDetector(
          onTap: () => widget.onJumpToMap?.call(spot.lat, spot.lng),
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: spot.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.primaryLight),
                    errorWidget: (_, __, ___) => Container(color: AppColors.primaryVeryLight),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                        stops: [0.4, 1.0],
                      ),
                    ),
                  ),
                  // 保存ボタン（右上）
                  Positioned(
                    top: 8, right: 8,
                    child: GestureDetector(
                      onTap: () {
                        provider.toggleSaveTrend(spot);
                        _showSaveSnack(isSaved ? '保存を解除しました' : '保存しました ✓', isSaved);
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                          color: isSaved ? const Color(0xFFFFD700) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10, left: 10, right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.title,
                          style: GoogleFonts.notoSansJp(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 10, color: Colors.pink),
                            const SizedBox(width: 3),
                            Text(
                              '${spot.likeCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendCard(TrendSpot spot) {
    return Consumer<UserProfileProvider>(
      builder: (_, provider, __) {
        final isSaved = provider.isSavedTrend(spot.id);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 写真
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: spot.imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(height: 180, color: AppColors.primaryLight),
                      errorWidget: (_, __, ___) => Container(
                        height: 180,
                        color: AppColors.primaryVeryLight,
                        child: const Icon(Icons.image, color: AppColors.primary, size: 40),
                      ),
                    ),
                    if (spot.isHot)
                      Positioned(
                        top: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF6B9D)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 3),
                              Text('HOT',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 12, right: 12,
                      child: Row(
                        children: [
                          // 保存ボタン
                          GestureDetector(
                            onTap: () {
                              provider.toggleSaveTrend(spot);
                              _showSaveSnack(isSaved ? '保存を解除しました' : '保存しました ✓', isSaved);
                            },
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                                size: 18,
                                color: isSaved ? const Color(0xFFFFD700) : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // 都道府県バッジ
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, size: 12, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  spot.prefecture,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: spot.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tagBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(tag,
                              style: GoogleFonts.notoSansJp(
                                  fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      spot.title,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spot.description,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 13, color: AppColors.textSecondary, height: 1.6,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 16, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              '${spot.likeCount} いいね',
                              style: GoogleFonts.notoSansJp(
                                  fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // マップで見るボタン
                        GestureDetector(
                          onTap: () => widget.onJumpToMap?.call(spot.lat, spot.lng),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryLight, AppColors.primary],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8, offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.map, size: 14, color: Colors.white),
                                const SizedBox(width: 5),
                                Text('マップで見る',
                                    style: GoogleFonts.notoSansJp(
                                        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // ユーザー検索 タブ
  // ═══════════════════════════════════════════
  Widget _buildUserSearchTab() {
    return Column(
      children: [
        // 検索バー
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  onSubmitted: _onSearch,
                  style: GoogleFonts.notoSansJp(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '@IDまたはニックネームで検索',
                    hintStyle: GoogleFonts.notoSansJp(fontSize: 13, color: AppColors.textHint),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchResults = [];
                                _hasSearched = false;
                              });
                            },
                            icon: const Icon(Icons.clear, size: 18, color: AppColors.textHint),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.primaryVeryLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 検索結果
        Expanded(
          child: _hasSearched
              ? (_searchResults.isEmpty
                  ? _buildEmptySearch()
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) => _buildUserCard(_searchResults[i]),
                    ))
              : _buildSearchHint(),
        ),
      ],
    );
  }

  Widget _buildSearchHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryVeryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'ユーザーを検索',
            style: GoogleFonts.notoSansJp(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@ID またはニックネームで\n気になるユーザーを検索しよう',
            style: GoogleFonts.notoSansJp(
              fontSize: 13, color: AppColors.textSecondary, height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            '例: @yuki_travel  /  Yuki',
            style: GoogleFonts.notoSansJp(
              fontSize: 12, color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(
            'ユーザーが見つかりませんでした',
            style: GoogleFonts.notoSansJp(
              fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IDやニックネームを確認してください',
            style: GoogleFonts.notoSansJp(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Consumer<UserProfileProvider>(
      builder: (_, provider, __) {
        final isFollowing = provider.isFollowing(user.uid);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: 10, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // アバター
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ユーザー情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: GoogleFonts.notoSansJp(
                              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryVeryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: Text(
                            '@${user.customId}',
                            style: GoogleFonts.notoSansJp(
                              fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.bio,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 12, color: AppColors.textSecondary, height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _statChip(Icons.push_pin, '${user.pinCount}', 'スポット'),
                        const SizedBox(width: 8),
                        _statChip(Icons.people, '${user.followerCount}', 'フォロワー'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // フォローボタン
              GestureDetector(
                onTap: () {
                  provider.toggleFollow(user.uid);
                  _showFollowSnack(isFollowing
                      ? '@${user.customId} のフォローを解除しました'
                      : '@${user.customId} をフォローしました');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isFollowing
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary]),
                    color: isFollowing ? AppColors.primaryVeryLight : null,
                    borderRadius: BorderRadius.circular(20),
                    border: isFollowing
                        ? Border.all(color: AppColors.primaryLight)
                        : null,
                    boxShadow: isFollowing
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8, offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Text(
                    isFollowing ? 'フォロー中' : 'フォロー',
                    style: GoogleFonts.notoSansJp(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isFollowing ? AppColors.primary : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: GoogleFonts.notoSansJp(
            fontSize: 11, color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  void _showSaveSnack(String msg, bool wasSaved) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              wasSaved ? Icons.bookmark_remove : Icons.bookmark_added,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 8),
            Text(msg, style: GoogleFonts.notoSansJp(fontSize: 13)),
          ],
        ),
        backgroundColor: wasSaved ? AppColors.textSecondary : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFollowSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.notoSansJp(fontSize: 13)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
