import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/ads_api.dart';
import '../../api/events_api.dart';
import '../../config/media_url.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';

/// 시스템 공유 시트(카카오톡, 문자 등). iPad는 [sharePositionOrigin] 필요.
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
  late Future<_EventPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_EventPageData> _load() async {
    final results = await Future.wait([AdsApi.getList(), EventsApi.getList()]);

    final ads = results[0] as List<AdItem>;
    final events = results[1] as List<EventItem>;

    debugPrint('[EventScreen] parsed ads count=${ads.length}');
    if (ads.isNotEmpty) {
      debugPrint(
        '[EventScreen] first ad id=${ads.first.id} content="${ads.first.content}" linkUrl=${ads.first.linkUrl}',
      );
    }
    debugPrint('[EventScreen] parsed events count=${events.length}');
    for (final e in events.take(5)) {
      debugPrint(
        '[EventScreen] event id=${e.id} title="${e.title}" startAt=${e.startAt} endAt=${e.endAt}',
      );
    }

    return _EventPageData(ads: ads, events: events);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url.trim());
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('이벤트', style: TextStyle(color: Colors.black87)),
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_EventPageData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _PageLoading();
            }
            final data =
                snapshot.data ?? const _EventPageData(ads: [], events: []);

            final feedItems = <_FeedItem>[
              ...data.ads.map((ad) => _FeedItem.ad(ad)),
              ...data.events.map((e) => _FeedItem.event(e)),
            ];

            if (feedItems.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _EmptyCard(
                    icon: PhosphorIconsRegular.confetti,
                    title: '진행 중인 이벤트가 없습니다.',
                    desc: '새 이벤트가 생기면 여기서 확인할 수 있어요.',
                  ),
                ],
              );
            }

            // NOTE: nested ListView (ListView inside ListView) can lead to only-first-item rendering on some devices.
            // Use a single ListView for feed items.
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: feedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = feedItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: switch (item) {
                    _FeedItemAd(:final ad) => _PromoAdCard(
                      ad: ad,
                      onOpen: () => _openUrl(ad.linkUrl),
                    ),
                    _FeedItemEvent(:final event) => _EventCard(
                      event: event,
                      onTap: () => _openUrl(event.url),
                    ),
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EventPageData {
  const _EventPageData({required this.ads, required this.events});
  final List<AdItem> ads;
  final List<EventItem> events;
}

sealed class _FeedItem {
  const _FeedItem();
  factory _FeedItem.ad(AdItem ad) = _FeedItemAd;
  factory _FeedItem.event(EventItem event) = _FeedItemEvent;
}

class _FeedItemAd extends _FeedItem {
  const _FeedItemAd(this.ad);
  final AdItem ad;
}

class _FeedItemEvent extends _FeedItem {
  const _FeedItemEvent(this.event);
  final EventItem event;
}

class _PageLoading extends StatelessWidget {
  const _PageLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: const [
        Gap(8),
        _SkeletonBox(height: 18, widthFactor: 0.25),
        Gap(12),
        _SkeletonBox(height: 200),
        Gap(20),
        _SkeletonBox(height: 18, widthFactor: 0.35),
        Gap(12),
        _SkeletonBox(height: 92),
        Gap(12),
        _SkeletonBox(height: 92),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, this.widthFactor});
  final double height;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: widthFactor == null ? double.infinity : w * widthFactor!,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// GET /ads 배너 — 이벤트 목록과 같은 리스트에 통합 표시.
class _PromoAdCard extends StatelessWidget {
  const _PromoAdCard({required this.ad, required this.onOpen});
  final AdItem ad;
  final VoidCallback onOpen;

  String get _shareText {
    final s = ad.shareText?.trim();
    if (s != null && s.isNotEmpty) return s;
    final c = ad.content?.trim() ?? '';
    final l = ad.linkUrl?.trim() ?? '';
    if (c.isNotEmpty && l.isNotEmpty) return '$c\n\n$l';
    if (c.isNotEmpty) return c;
    return l;
  }

  String? get _imageResolved => resolveMediaUrl(ad.imageUrl);

  bool get _hasImage => _imageResolved != null;

  @override
  Widget build(BuildContext context) {
    final bodyText = (ad.content ?? '').trim();
    final canOpen = ad.linkUrl != null && ad.linkUrl!.trim().isNotEmpty;
    final sharePayload = _shareText;
    final imgUrl = _imageResolved;

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasImage && imgUrl != null)
            AspectRatio(
              aspectRatio: 2.1,
              child: InkWell(
                onTap: canOpen ? onOpen : null,
                child: ColoredBox(
                  color: Colors.grey.shade100,
                  child: AppNetworkImage(
                    url: imgUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            )
          else
            InkWell(
              onTap: canOpen ? onOpen : null,
              child: Container(
                height: 100,
                color: Colors.amber.shade50,
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIconsRegular.megaphone,
                    size: 44,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bodyText.isEmpty ? '광고' : bodyText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: Colors.black87,
                  ),
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (btnContext) {
                          return OutlinedButton.icon(
                            onPressed: sharePayload.isEmpty
                                ? null
                                : () =>
                                      _sharePromoText(btnContext, sharePayload),
                            icon: PhosphorIcon(
                              PhosphorIconsRegular.shareNetwork,
                              size: 18,
                              color: AppTheme.accentBlue,
                            ),
                            label: const Text('공유하기'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: AppTheme.accentBlue.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canOpen ? onOpen : null,
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.arrowSquareOut,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text('열기'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accentBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});
  final EventItem event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = _formatRange(event.startAt, event.endAt);
    final thumb = resolveMediaUrl(event.imageUrl);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 76,
                height: 76,
                color: Colors.grey.shade100,
                child: thumb != null
                    ? AppNetworkImage(url: thumb, fit: BoxFit.cover)
                    : Center(
                        child: PhosphorIcon(
                          PhosphorIconsRegular.confetti,
                          color: Colors.grey.shade500,
                        ),
                      ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (date != null) ...[
                    const Gap(8),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Gap(8),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          PhosphorIcon(icon, size: 30, color: Colors.grey.shade700),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Gap(6),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _formatRange(String? startIso, String? endIso) {
  String? fmt(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
    return m != null ? '${m[1]}.${m[2]}.${m[3]}' : iso;
  }

  final s = fmt(startIso);
  final e = fmt(endIso);
  if (s == null && e == null) return null;
  if (s != null && e != null) return '$s ~ $e';
  return s ?? e;
}
