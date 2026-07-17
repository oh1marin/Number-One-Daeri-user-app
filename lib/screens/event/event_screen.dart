import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/ads_api.dart';
import '../../api/events_api.dart';
import '../../config/media_url.dart';
import '../../services/content_read_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/content_feed_widgets.dart';
import '../../widgets/load_error_view.dart';

void _sharePromoText(BuildContext context, String text) {
  final t = text.trim();
  if (t.isEmpty) return;
  final box = context.findRenderObject();
  Rect? origin;
  if (box is RenderBox && box.hasSize) {
    origin = box.localToGlobal(Offset.zero) & box.size;
  }
  Share.share(t, sharePositionOrigin: origin);
}

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  List<AdItem> _ads = [];
  List<EventItem> _events = [];
  Set<String> _readIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (forceRefresh) AdsApi.invalidateCache();
    try {
      final results = await Future.wait([
        AdsApi.getList(forceRefresh: forceRefresh),
        EventsApi.getList(forceRefresh: forceRefresh),
        ContentReadStore.eventReadIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _ads = results[0] as List<AdItem>;
        _events = results[1] as List<EventItem>;
        _readIds = results[2] as Set<String>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ads = [];
        _events = [];
        _loading = false;
        _error = loadErrorMessage(e, fallback: '이벤트를 불러올 수 없습니다.');
      });
    }
  }

  Future<void> _refresh() => _load(forceRefresh: true);

  Future<void> _openUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url.trim());
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _markRead(String id) async {
    if (id.isEmpty) return;
    await ContentReadStore.markEventRead(id);
    if (mounted) setState(() => _readIds = {..._readIds, id});
  }

  void _openAd(AdItem ad) {
    final id = ad.id.isNotEmpty ? 'ad_${ad.id}' : '';
    _markRead(id);
    _openUrl(ad.linkUrl);
  }

  void _openEvent(EventItem event) {
    _markRead(event.id);
    _showEventDetail(event);
  }

  void _showEventDetail(EventItem event) {
    final heroUrl = resolveMediaUrl(event.imageUrl);
    final dateRange = formatEventDateRange(event.startAt, event.endAt) ?? event.date;
    final body = (event.content ?? '').trim();
    final hasUrl = event.url != null && event.url!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: hasUrl && body.isEmpty ? 0.45 : 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              const ContentDetailSheetHandle(),
              if (heroUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: AppNetworkImage(url: heroUrl, fit: BoxFit.cover),
                  ),
                ),
                const Gap(16),
              ],
              Row(
                children: [
                  const ContentBadgeChip(label: '이벤트'),
                  const Gap(8),
                  ContentEventStatusChip(
                    startAt: event.startAt,
                    endAt: event.endAt,
                  ),
                ],
              ),
              const Gap(12),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDark,
                  letterSpacing: -0.4,
                  height: 1.3,
                ),
              ),
              if (dateRange != null) ...[
                const Gap(10),
                Row(
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsRegular.calendarBlank,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const Gap(4),
                    Text(
                      dateRange,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              if (body.isNotEmpty) ...[
                const Gap(20),
                const Divider(color: AppTheme.borderGrey, height: 1),
                const Gap(20),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.65,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
              const Gap(24),
              if (hasUrl)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openUrl(event.url);
                  },
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.arrowSquareOut,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('이벤트 자세히 보기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              else
                Text(
                  '자세한 내용은 고객센터(010-2184-8822)로 문의해 주세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isUnread(String id) => id.isNotEmpty && !_readIds.contains(id);

  int get _unreadCount {
    var count = 0;
    for (final ad in _ads) {
      final id = ad.id.isNotEmpty ? 'ad_${ad.id}' : '';
      if (_isUnread(id)) count++;
    }
    for (final e in _events) {
      if (_isUnread(e.id)) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _ads.isNotEmpty || _events.isNotEmpty;

    return ConnectivityReconnectListener(
      onReconnect: _refresh,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('이벤트'),
          actions: [
            if (_unreadCount > 0 && !_loading)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '새글 $_unreadCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.arrowsClockwise),
              onPressed: _loading ? null : _refresh,
            ),
          ],
        ),
        body: _loading
            ? Skeletonizer(
                enabled: true,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const _EventHeroBanner(),
                    const Gap(20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _EventCard(
                        event: const EventItem(
                          id: 'sk',
                          title: '이벤트 제목입니다',
                          imageUrl: null,
                          startAt: '2026-06-01',
                          endAt: '2026-12-31',
                          url: null,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
            ? LoadErrorView(message: _error!, onRetry: _refresh)
            : !hasContent
            ? const ContentEmptyState(
                icon: PhosphorIconsRegular.confetti,
                title: '진행 중인 이벤트가 없습니다.',
                subtitle: '새 이벤트가 생기면 여기서 확인할 수 있어요.',
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const _EventHeroBanner(),
                    const Gap(20),
                    if (_ads.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ContentSectionHeader(
                          title: '프로모션',
                          subtitle: '지금 참여할 수 있는 혜택',
                        ),
                      ),
                      const Gap(12),
                      ..._ads.map(
                        (ad) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _PromoAdCard(
                            ad: ad,
                            isUnread: _isUnread(
                              ad.id.isNotEmpty ? 'ad_${ad.id}' : '',
                            ),
                            onOpen: () => _openAd(ad),
                          ),
                        ),
                      ),
                      const Gap(8),
                    ],
                    if (_events.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ContentSectionHeader(
                          title: '이벤트 목록',
                          subtitle: '${_events.length}건',
                        ),
                      ),
                      const Gap(12),
                      ..._events.map(
                        (event) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _EventCard(
                            event: event,
                            isUnread: _isUnread(event.id),
                            onTap: () => _openEvent(event),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _EventHeroBanner extends StatelessWidget {
  const _EventHeroBanner();

  @override
  Widget build(BuildContext context) {
    return const ContentHeroBanner.image(
      imageAsset: 'assets/images/banner_event.png',
      imageAspectRatio: 1024 / 548,
    );
  }
}

class _PromoAdCard extends StatelessWidget {
  const _PromoAdCard({
    required this.ad,
    required this.onOpen,
    this.isUnread = false,
  });

  final AdItem ad;
  final VoidCallback onOpen;
  final bool isUnread;

  String get _shareText {
    final s = ad.shareText?.trim();
    if (s != null && s.isNotEmpty) return s;
    final c = ad.content?.trim() ?? '';
    final l = ad.linkUrl?.trim() ?? '';
    if (c.isNotEmpty && l.isNotEmpty) return '$c\n\n$l';
    if (c.isNotEmpty) return c;
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final bodyText = (ad.content ?? '').trim();
    final canOpen = ad.linkUrl != null && ad.linkUrl!.trim().isNotEmpty;
    final sharePayload = _shareText;
    final imgUrl = resolveMediaUrl(ad.imageUrl);

    return ContentListCard(
      onTap: canOpen ? onOpen : null,
      isUnread: isUnread,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imgUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2.1,
                child: AppNetworkImage(url: imgUrl, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: PhosphorIcon(
                  PhosphorIconsRegular.megaphone,
                  size: 40,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          const Gap(14),
          Row(
            children: [
              const ContentBadgeChip(label: '프로모션', compact: true),
              if (isUnread) ...[const Gap(6), const ContentUnreadDot()],
            ],
          ),
          const Gap(8),
          Text(
            bodyText.isEmpty ? '프로모션' : bodyText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
              height: 1.35,
              color: AppTheme.primaryDark,
            ),
          ),
          const Gap(14),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (btnContext) {
                    return OutlinedButton.icon(
                      onPressed: sharePayload.isEmpty
                          ? null
                          : () => _sharePromoText(btnContext, sharePayload),
                      icon: const PhosphorIcon(
                        PhosphorIconsRegular.shareNetwork,
                        size: 18,
                      ),
                      label: const Text('공유'),
                    );
                  },
                ),
              ),
              const Gap(10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canOpen ? onOpen : null,
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.arrowSquareOut,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text('열기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    this.onTap,
    this.isUnread = false,
  });

  final EventItem event;
  final VoidCallback? onTap;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final date = formatEventDateRange(event.startAt, event.endAt);
    final thumb = resolveMediaUrl(event.imageUrl);

    return ContentListCard(
      onTap: onTap,
      isUnread: isUnread,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumb != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: AppNetworkImage(url: thumb, fit: BoxFit.cover),
              ),
            ),
            const Gap(12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ContentEventStatusChip(
                      startAt: event.startAt,
                      endAt: event.endAt,
                    ),
                    if (isUnread) ...[const Gap(6), const ContentUnreadDot()],
                  ],
                ),
                const Gap(6),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                    color: AppTheme.primaryDark,
                    height: 1.35,
                  ),
                ),
                if (date != null) ...[
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
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
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
