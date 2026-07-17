import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../api/notices_api.dart';
import '../../config/media_url.dart';
import '../../services/content_read_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/content_feed_widgets.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/notification_toggle_card.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<Notice> _items = [];
  Set<String> _readIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        NoticesApi.getList(),
        ContentReadStore.noticeReadIds(),
      ]);
      if (mounted) {
        setState(() {
          _items = results[0] as List<Notice>;
          _readIds = results[1] as Set<String>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
          _error = loadErrorMessage(e, fallback: '공지를 불러올 수 없습니다.');
        });
      }
    }
  }

  Future<void> _openDetail(Notice notice) async {
    await ContentReadStore.markNoticeRead(notice.id);
    if (mounted) {
      setState(() => _readIds = {..._readIds, notice.id});
    }
    if (!mounted) return;
    _showDetail(context, notice);
  }

  void _showDetail(BuildContext context, Notice notice) {
    final heroUrl =
        resolveMediaUrl(notice.coverImageUrl) ??
        resolveMediaUrl(notice.imageUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CustomScrollView(
            controller: controller,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ContentDetailSheetHandle(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (heroUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: AppNetworkImage(
                                  url: heroUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const Gap(16),
                          ],
                          if (notice.badge.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ContentBadgeChip(
                                label: notice.badge,
                                badgeColor: notice.badgeColor,
                              ),
                            ),
                          Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                              letterSpacing: -0.4,
                              height: 1.3,
                            ),
                          ),
                          const Gap(10),
                          Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIconsRegular.calendarBlank,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const Gap(4),
                              Text(
                                notice.date,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (notice.views > 0) ...[
                                const Gap(14),
                                PhosphorIcon(
                                  PhosphorIconsRegular.eye,
                                  size: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                const Gap(4),
                                Text(
                                  '조회 ${notice.views}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Gap(20),
                          const Divider(color: AppTheme.borderGrey, height: 1),
                          const Gap(20),
                          Text(
                            notice.content,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.65,
                              color: Color(0xFF374151),
                            ),
                          ),
                          if (notice.events.isNotEmpty) ...[
                            const Gap(28),
                            const ContentSectionHeader(
                              title: '관련 이벤트',
                              subtitle: '이 공지와 함께 진행 중인 혜택',
                            ),
                            const Gap(12),
                            ...notice.events.map((e) => _EmbeddedEventCard(event: e)),
                          ],
                          const Gap(32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _items.where((n) => n.id.isNotEmpty && !_readIds.contains(n.id)).length;
    final hPad = ResponsiveLayout.pageHorizontal(context);
    final bottomPad = ResponsiveLayout.bottomSafeInset(context, extra: 12);

    return ConnectivityReconnectListener(
      onReconnect: _load,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('공지사항'),
          actions: [
            if (unreadCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '새글 $unreadCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.arrowsClockwise),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: _loading
            ? Skeletonizer(
                enabled: true,
                child: ListView(
                  padding: EdgeInsets.only(bottom: bottomPad),
                  children: [
                    const _NoticeHeroBanner(),
                    const Gap(12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: const NotificationToggleCard(compact: true),
                    ),
                    const Gap(16),
                    ...List.generate(
                      4,
                      (i) => Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
                        child: _NoticeTile(
                          title: '공지 제목입니다',
                          date: '2026.06.05',
                          badge: '공지',
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
            ? LoadErrorView(message: _error!, onRetry: _load)
            : _items.isEmpty
            ? const ContentEmptyState(
                icon: PhosphorIconsRegular.megaphone,
                title: '등록된 공지사항이 없습니다.',
                subtitle: '새 소식이 등록되면 여기에 표시됩니다.',
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: EdgeInsets.only(bottom: bottomPad),
                  itemCount: _items.length + 3,
                  separatorBuilder: (_, i) {
                    if (i == 0) return const Gap(12);
                    if (i == 1) return const Gap(12);
                    return const Gap(10);
                  },
                  itemBuilder: (_, i) {
                    if (i == 0) return const _NoticeHeroBanner();
                    if (i == 1) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: const NotificationToggleCard(compact: true),
                      );
                    }
                    if (i == 2) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: const ContentSectionHeader(
                          title: '전체 공지',
                          subtitle: '운영 안내·이벤트 소식을 확인하세요',
                        ),
                      );
                    }
                    final n = _items[i - 3];
                    final thumb =
                        resolveMediaUrl(n.coverImageUrl) ??
                        resolveMediaUrl(n.imageUrl);
                    final isUnread =
                        n.id.isNotEmpty && !_readIds.contains(n.id);
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: _NoticeTile(
                        title: n.title,
                        date: n.date,
                        badge: n.badge,
                        badgeColor: n.badgeColor,
                        thumbnailUrl: thumb,
                        isUnread: isUnread,
                        onTap: () => _openDetail(n),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _NoticeHeroBanner extends StatelessWidget {
  const _NoticeHeroBanner();

  @override
  Widget build(BuildContext context) {
    return const ContentHeroBanner.image(
      imageAsset: 'assets/images/banner_notice.png',
      imageAspectRatio: 1024 / 414,
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.title,
    required this.date,
    this.badge,
    this.badgeColor,
    this.thumbnailUrl,
    this.isUnread = false,
    this.onTap,
  });

  final String title;
  final String date;
  final String? badge;
  final String? badgeColor;
  final String? thumbnailUrl;
  final bool isUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ContentListCard(
      onTap: onTap,
      isUnread: isUnread,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: AppNetworkImage(url: thumbnailUrl!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const PhosphorIcon(
                PhosphorIconsRegular.megaphone,
                size: 24,
                color: AppTheme.textSecondary,
              ),
            ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (badge != null && badge!.isNotEmpty) ...[
                      ContentBadgeChip(
                        label: badge!,
                        badgeColor: badgeColor,
                        compact: true,
                      ),
                      const Gap(6),
                    ],
                    if (isUnread) const ContentUnreadDot(),
                  ],
                ),
                if (badge != null && badge!.isNotEmpty) const Gap(6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                    height: 1.3,
                  ),
                ),
                const Gap(6),
                Row(
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsRegular.calendarBlank,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const Gap(4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(8),
          const PhosphorIcon(
            PhosphorIconsRegular.caretRight,
            size: 16,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _EmbeddedEventCard extends StatelessWidget {
  const _EmbeddedEventCard({required this.event});

  final NoticeEvent event;

  @override
  Widget build(BuildContext context) {
    final eventImg = resolveMediaUrl(event.imageUrl);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eventImg != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AppNetworkImage(url: eventImg, fit: BoxFit.cover),
              ),
            ),
            const Gap(10),
          ],
          Text(
            event.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.primaryDark,
            ),
          ),
          if (event.date != null) ...[
            const Gap(4),
            Text(
              event.date!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          if (event.desc != null && event.desc!.isNotEmpty) ...[
            const Gap(6),
            Text(
              event.desc!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
