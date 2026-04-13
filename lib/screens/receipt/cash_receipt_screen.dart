import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/receipt_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';

/// 현금영수증 발행 화면
class CashReceiptScreen extends StatefulWidget {
  const CashReceiptScreen({super.key, this.rideId, this.amount});

  final String? rideId;
  final int? amount;

  @override
  State<CashReceiptScreen> createState() => _CashReceiptScreenState();
}

class _CashReceiptScreenState extends State<CashReceiptScreen> {
  final _identifierCtrl = TextEditingController();
  String _type = 'phone'; // 'phone' | 'biz'
  bool _submitting = false;
  bool _loading = false;

  List<CashReceiptResult> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final list = await ReceiptApi.getList()
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _history = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validate() {
    final val = _identifierCtrl.text.trim();
    if (val.isEmpty) return '번호를 입력하세요.';
    if (_type == 'phone') {
      if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(val.replaceAll('-', ''))) {
        return '올바른 휴대폰 번호를 입력하세요. (예: 01012345678)';
      }
    } else {
      if (val.replaceAll('-', '').length != 10) {
        return '올바른 사업자번호를 입력하세요. (10자리)';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) { showErrorSnackBar(context, err); return; }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final result = await ReceiptApi.request(
        rideId: widget.rideId,
        phoneOrBizNo: _identifierCtrl.text.trim().replaceAll('-', ''),
        type: _type,
        amount: widget.amount ?? 0,
      );
      if (!mounted) return;
      showSuccessSnackBar(context, '현금영수증이 발행 요청되었습니다.', title: '발행완료');
      _identifierCtrl.clear();
      await _loadHistory();

      // 다운로드 URL 있으면 바로 열기 제안
      if (result.downloadUrl != null && mounted) {
        _showDownloadDialog(result.downloadUrl!);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showDownloadDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('영수증 다운로드', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('발행된 영수증을 바로 확인하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('나중에')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openUrl(url);
            },
            child: const Text('다운로드'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '다운로드 링크를 열 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('현금영수증'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 배너
            _InfoBanner(amount: widget.amount),
            const Gap(24),

            // 발행 구분 선택
            const _SectionTitle('발행 구분'),
            const Gap(8),
            _TypeSelector(selected: _type, onSelect: (t) => setState(() => _type = t)),
            const Gap(16),

            // 번호 입력
            _SectionTitle(_type == 'phone' ? '휴대폰 번호' : '사업자 번호'),
            const Gap(8),
            TextFormField(
              controller: _identifierCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-]'))],
              decoration: InputDecoration(
                hintText: _type == 'phone' ? '01012345678' : '0000000000',
                prefixIcon: Icon(
                  _type == 'phone' ? Icons.phone_android_rounded : Icons.business_rounded,
                  size: 20,
                ),
              ),
            ),
            const Gap(24),

            // 발행 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('현금영수증 발행'),
              ),
            ),
            const Gap(32),

            // 발행 내역
            const _SectionTitle('발행 내역'),
            const Gap(12),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_history.isEmpty)
              _EmptyHistory()
            else
              ..._history.map((r) => _ReceiptHistoryCard(result: r, onDownload: _openUrl)),
          ],
        ),
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryDark,
        ),
      );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({this.amount});
  final int? amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const PhosphorIcon(PhosphorIconsRegular.receipt, color: Colors.white, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '현금영수증 발행',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
                ),
                const Gap(3),
                Text(
                  amount != null && amount! > 0
                      ? '결제금액: ${_fmt(amount!)}원'
                      : '휴대폰번호 또는 사업자번호로 발행됩니다.',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeChip(label: '휴대폰번호', value: 'phone', selected: selected, onSelect: onSelect),
        const Gap(10),
        _TypeChip(label: '사업자번호', value: 'biz', selected: selected, onSelect: onSelect),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label, required this.value,
    required this.selected, required this.onSelect,
  });
  final String label;
  final String value;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryDark : AppTheme.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          PhosphorIcon(PhosphorIconsRegular.receipt, size: 40, color: Colors.grey.shade300),
          const Gap(12),
          Text('발행 내역이 없습니다.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ReceiptHistoryCard extends StatelessWidget {
  const _ReceiptHistoryCard({required this.result, required this.onDownload});
  final CashReceiptResult result;
  final void Function(String) onDownload;

  @override
  Widget build(BuildContext context) {
    final issued = result.isIssued;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: issued
                  ? const Color(0xFF43A047).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              issued ? Icons.check_circle_outline_rounded : Icons.access_time_rounded,
              color: issued ? const Color(0xFF43A047) : Colors.grey,
              size: 22,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issued ? '발행완료' : '처리중',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: issued ? const Color(0xFF43A047) : Colors.grey,
                  ),
                ),
                if (result.identifier != null)
                  Text(result.identifier!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (result.issuedAt != null)
                  Text(_fmtDate(result.issuedAt!), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          if (result.downloadUrl != null)
            TextButton.icon(
              onPressed: () => onDownload(result.downloadUrl!),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('다운로드', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accentBlue,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtDate(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
    return m != null ? '${m[1]}.${m[2]}.${m[3]}' : iso;
  }
}
