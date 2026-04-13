import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../api/notices_api.dart';
import '../../config/media_url.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_network_image.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  List<Notice> _items = [];
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
      final list = await NoticesApi.getList();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items = [];
          _loading = false;
          _error = '공지를 불러올 수 없습니다.';
        });
      }
    }
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
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: CustomScrollView(
            controller: controller,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (heroUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  notice.badge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentBlue,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Text(
                                notice.date,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (notice.views > 0) ...[
                                const Gap(12),
                                Text(
                                  '조회 ${notice.views}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Gap(20),
                          Text(
                            notice.content,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (notice.events.isNotEmpty) ...[
                            const Gap(24),
                            Text(
                              '이벤트',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Gap(12),
                            ...notice.events.map((e) {
                              final eventImg = resolveMediaUrl(e.imageUrl);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (eventImg != null) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: AppNetworkImage(
                                            url: eventImg,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const Gap(10),
                                    ],
                                    Text(
                                      e.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (e.date != null)
                                      Text(
                                        e.date!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    if (e.desc != null)
                                      Text(
                                        e.desc!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          const Gap(24),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('공지사항', style: TextStyle(color: Colors.black87)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? Skeletonizer(
              enabled: true,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (_, i) => _NoticeTile(
                  title: '공지 제목입니다',
                  date: '2024.01.01',
                  onTap: null,
                ),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                  const Gap(12),
                  TextButton(onPressed: _load, child: const Text('다시 시도')),
                ],
              ),
            )
          : _items.isEmpty
          ? _EmptyState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (_, i) {
                  final n = _items[i];
                  final thumb =
                      resolveMediaUrl(n.coverImageUrl) ??
                      resolveMediaUrl(n.imageUrl);
                  return _NoticeTile(
                    title: n.title,
                    date: n.date,
                    badge: n.badge,
                    thumbnailUrl: thumb,
                    onTap: () => _showDetail(context, n),
                  );
                },
              ),
            ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.title,
    required this.date,
    this.badge,
    this.thumbnailUrl,
    this.onTap,
  });

  final String title;
  final String date;
  final String? badge;
  final String? thumbnailUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            if (thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: AppNetworkImage(url: thumbnailUrl!, fit: BoxFit.cover),
                ),
              )
            else
              PhosphorIcon(
                PhosphorIconsRegular.megaphone,
                size: 20,
                color: Colors.grey.shade600,
              ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null && badge!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Gap(4),
                  Text(
                    date,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.megaphone,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const Gap(16),
          Text(
            '등록된 공지사항이 없습니다.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
