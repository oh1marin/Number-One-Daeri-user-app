import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/gifticon_api.dart';
import '../../api/mileage_api.dart';
import '../../models/gifticon.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/app_screen_widgets.dart';
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
    final hPad = ResponsiveLayout.pageHorizontal(context);
    final gridPad = (hPad - 2).clamp(12.0, 20.0);
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
            ? const AppPageLoading()
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
                            horizontalPadding: hPad,
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 6),
                            child: const SignupBonusMileageNotice(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '마일리지로 기프티콘을 바로 교환하세요',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (_products.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.borderGrey),
                                    ),
                                    child: Text(
                                      '${_filtered.length}개',
                                      style: const TextStyle(
                                        fontSize: 11,
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
                            horizontalPadding: hPad,
                            onSelected: (c) => setState(() => _category = c),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 10),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: '상품 검색',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.borderGrey),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.borderGrey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: AppEmptyState(
                              icon: _products.isEmpty
                                  ? PhosphorIconsRegular.gift
                                  : (_query.trim().isNotEmpty
                                      ? PhosphorIconsRegular.magnifyingGlass
                                      : PhosphorIconsRegular.tag),
                              title: _products.isEmpty
                                  ? '등록된 기프티콘 상품이 없습니다.'
                                  : (_query.trim().isNotEmpty
                                      ? '검색 결과가 없습니다.'
                                      : '해당 카테고리 상품이 없습니다.'),
                              subtitle: _query.trim().isNotEmpty
                                  ? '다른 검색어로 다시 찾아보세요.'
                                  : '잠시 후 다시 확인해 주세요.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(gridPad, 0, gridPad, 8),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.72,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final p = _filtered[index];
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(
                                      milliseconds: (180 + (index * 25))
                                          .clamp(0, 400)
                                          .toInt(),
                                    ),
                                    curve: Curves.easeOut,
                                    builder: (context, v, child) {
                                      final dy = (1 - v) * 10;
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
                                      compact: true,
                                      canAfford:
                                          _gifticonSpendable >= p.mileagePrice,
                                      onTap: () => _openProduct(p),
                                    ),
                                  );
                                },
                                childCount: _filtered.length,
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 4),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 16, color: Colors.blue.shade700),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      '교환 완료 후 등록된 휴대폰으로 기프티콘이 발송됩니다. '
                                      '유효기간은 발송일로부터 30일이며, 미사용 시 환불되지 않습니다.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade900,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: ResponsiveLayout.bottomSafeInset(context, extra: 4),
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
