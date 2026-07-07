import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../api/gifticon_api.dart';
import '../../api/mileage_api.dart';
import '../../models/gifticon.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/gifticon/gifticon_widgets.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/signup_bonus_mileage_notice.dart';
import 'gifticon_confirm_screen.dart';
import 'gifticon_orders_screen.dart';

/// 기프티콘 상품 목록 (마일리지 교환몰)
class GifticonShopScreen extends StatefulWidget {
  const GifticonShopScreen({super.key, this.initialBalance});

  final int? initialBalance;

  @override
  State<GifticonShopScreen> createState() => _GifticonShopScreenState();
}

class _GifticonShopScreenState extends State<GifticonShopScreen> {
  List<GifticonProduct> _products = [];
  GifticonCategory? _category;
  int _balance = 0;
  int _gifticonSpendable = 0;
  int _signupBonusRemaining = 0;
  bool _loading = true;
  String? _error;
  String _query = '';
  GifticonSort _sort = GifticonSort.featured;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBalance;
    _balance = initial ?? 0;
    _gifticonSpendable = initial ?? 0;
    GifticonApi.invalidateProductsCache();
    _load(forceRefresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        GifticonApi.getProducts(forceRefresh: forceRefresh),
        if (widget.initialBalance == null) GifticonApi.fetchMileageBalance(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<GifticonProduct>;
        if (results.length > 1) {
          final bal = results[1] as MileageBalance;
          _balance = bal.balance;
          _gifticonSpendable = bal.gifticonSpendable;
          _signupBonusRemaining = bal.signupBonusRemaining;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = loadErrorMessage(e, fallback: '상품을 불러오지 못했습니다.');
      });
    }
  }

  List<GifticonProduct> get _filtered {
    Iterable<GifticonProduct> items = _products;

    if (_category != null) {
      items = items.where((p) => p.category == _category);
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((p) {
        final hay = '${p.name} ${p.subtitle}'.toLowerCase();
        return hay.contains(q);
      });
    }

    final list = items.toList();
    switch (_sort) {
      case GifticonSort.priceAsc:
        list.sort((a, b) => a.mileagePrice.compareTo(b.mileagePrice));
        break;
      case GifticonSort.priceDesc:
        list.sort((a, b) => b.mileagePrice.compareTo(a.mileagePrice));
        break;
      case GifticonSort.featured:
        // Keep API ordering.
        break;
    }
    return list;
  }

  Future<void> _openProduct(GifticonProduct product) async {
    debugPrint(
      '[GifticonShop] open product id=${product.id} price=${product.mileagePrice}',
    );
    final result = await Navigator.push<GifticonPurchaseResult>(
      context,
      MaterialPageRoute(
        builder: (_) => GifticonConfirmScreen(
          product: product,
          currentBalance: _balance,
          gifticonSpendable: _gifticonSpendable,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _balance = result.remainingBalance;
        _gifticonSpendable = (result.remainingBalance - _signupBonusRemaining)
            .clamp(0, result.remainingBalance);
      });
      debugPrint(
        '[GifticonShop] purchase complete id=${product.id} remaining=${result.remainingBalance}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityReconnectListener(
      onReconnect: () => _load(forceRefresh: true),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceGrey,
        appBar: AppBar(
          title: const Text('기프티콘 교환'),
          actions: [
            PopupMenuButton<GifticonSort>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: '정렬',
              initialValue: _sort,
              onSelected: (v) => setState(() => _sort = v),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: GifticonSort.featured,
                  child: Text('추천순'),
                ),
                PopupMenuItem(
                  value: GifticonSort.priceAsc,
                  child: Text('가격 낮은 순'),
                ),
                PopupMenuItem(
                  value: GifticonSort.priceDesc,
                  child: Text('가격 높은 순'),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: '주문내역',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GifticonOrdersScreen()),
                );
                _load(forceRefresh: true);
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? LoadErrorView(
                    message: _error!,
                    onRetry: () => _load(forceRefresh: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(forceRefresh: true),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: GifticonBalanceHeader(
                            balance: _balance,
                            gifticonSpendable: _gifticonSpendable,
                            onOrdersTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GifticonOrdersScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: SignupBonusMileageNotice(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '마일리지로 기프티콘을 바로 교환하세요',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_products.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.borderGrey),
                                    ),
                                    child: Text(
                                      '${_filtered.length}개',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: GifticonCategoryChips(
                            selected: _category,
                            onSelected: (c) => setState(() => _category = c),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                              decoration: InputDecoration(
                                hintText: '상품 검색',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: AppTheme.borderGrey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: AppTheme.borderGrey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                _products.isEmpty
                                    ? '등록된 기프티콘 상품이 없습니다.'
                                  : (_query.trim().isNotEmpty
                                      ? '검색 결과가 없습니다.'
                                      : '해당 카테고리 상품이 없습니다.'),
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            sliver: SliverList.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (context, index) => const Gap(16),
                              itemBuilder: (context, index) {
                                final p = _filtered[index];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(
                                    milliseconds: (220 + (index * 30))
                                        .clamp(0, 450)
                                        .toInt(),
                                  ),
                                  curve: Curves.easeOut,
                                  builder: (context, v, child) {
                                    final dy = (1 - v) * 14;
                                    return Opacity(
                                      opacity: v,
                                      child: Transform.translate(
                                        offset: Offset(0, dy),
                                        child: child,
                                      ),
                                    );
                                  },
                                    child: GifticonProductCard(
                                      product: p,
                                      canAfford: _gifticonSpendable >= p.mileagePrice,
                                      onTap: () => _openProduct(p),
                                    ),
                                );
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue.shade700),
                                  const Gap(10),
                                  Expanded(
                                    child: Text(
                                      '교환 완료 후 등록된 휴대폰으로 기프티콘이 발송됩니다. '
                                      '유효기간은 발송일로부터 30일이며, 미사용 시 환불되지 않습니다.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade900,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

enum GifticonSort {
  featured,
  priceAsc,
  priceDesc,
}
