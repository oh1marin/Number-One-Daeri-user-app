import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../api/mileage_api.dart';
import '../../api/withdrawal_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/load_error_view.dart';

const int kWithdrawalMin = 20000;
const int kWithdrawalMax = 1000000;
const int kWithdrawalStep = 10000;
const int kWithdrawalFee = 500;

const List<String> _kBanks = [
  '국민', '신한', '우리', '하나', '농협', '기업',
  'SC제일', '씨티', '대구', '부산', '광주', '제주',
  '전북', '경남', '새마을', '신협', '우체국',
  '카카오뱅크', '케이뱅크', '토스뱅크',
];

/// 출금신청 화면
class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  // 잔액
  int _withdrawable = 0;
  bool _loadingBalance = true;
  String? _balanceError;

  // 폼
  final _amountCtrl = TextEditingController();
  String? _selectedBank;
  final _accountCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    setState(() {
      _loadingBalance = true;
      _balanceError = null;
    });
    try {
      final bal = await MileageApi.getBalance()
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _withdrawable = bal.withdrawable;
          _loadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingBalance = false;
          _balanceError = loadErrorMessage(e, fallback: '잔액을 불러오지 못했습니다.');
        });
      }
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  /// 출금 가능 금액과 1회 최대 100만원 중 작은 값
  int get _maxRequestableAmount {
    if (_withdrawable <= 0) return 0;
    return _withdrawable > kWithdrawalMax ? kWithdrawalMax : _withdrawable;
  }

  void _fillAll() {
    final max = _maxRequestableAmount;
    final rounded = (max ~/ kWithdrawalStep) * kWithdrawalStep;
    _amountCtrl.text = rounded >= kWithdrawalMin ? rounded.toString() : '';
    setState(() {});
  }

  String? _validateAmount(int amountRaw) {
    if (amountRaw <= 0) return '출금액을 입력하세요.';
    if (amountRaw < kWithdrawalMin) {
      return '최소 출금액은 ${_fmt(kWithdrawalMin)}원입니다.';
    }
    if (amountRaw % kWithdrawalStep != 0) {
      return '${_fmt(kWithdrawalStep)}원 단위로 입력하세요.';
    }
    if (amountRaw > _withdrawable) {
      return '출금 가능 금액(${_fmt(_withdrawable)}원)을 초과할 수 없습니다.';
    }
    if (amountRaw > kWithdrawalMax) {
      return '1회 최대 출금액은 ${_fmt(kWithdrawalMax)}원입니다.';
    }
    return null;
  }

  String? _validate() {
    final amountRaw = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amountRaw == null) return '출금액을 입력하세요.';
    final amountErr = _validateAmount(amountRaw);
    if (amountErr != null) return amountErr;
    if (_selectedBank == null) return '은행을 선택하세요.';
    if (_accountCtrl.text.trim().isEmpty) return '계좌번호를 입력하세요.';
    if (_holderCtrl.text.trim().isEmpty) return '예금주를 입력하세요.';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) { showErrorSnackBar(context, err); return; }
    if (_submitting) return;

    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    final confirmed = await _showConfirmDialog(amount);
    if (!confirmed) return;

    setState(() => _submitting = true);
    try {
      await WithdrawalApi.request(
        amount: amount,
        bankCode: _selectedBank!,
        accountNumber: _accountCtrl.text.trim(),
        accountHolder: _holderCtrl.text.trim(),
      );
      if (!mounted) return;
      showSuccessSnackBar(context, '출금 신청이 완료되었습니다.\n영업일 기준 1~2일 내 처리됩니다.', title: '신청완료');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '출금 신청에 실패했습니다. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _showConfirmDialog(int amount) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('출금 신청 확인'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConfirmRow('출금액', '${_fmt(amount)}원'),
                _ConfirmRow('수수료', '${_fmt(kWithdrawalFee)}원'),
                const Divider(height: 20),
                _ConfirmRow('실수령액', '${_fmt(amount - kWithdrawalFee)}원', bold: true),
                const Gap(8),
                _ConfirmRow('은행', _selectedBank!),
                _ConfirmRow('계좌번호', _accountCtrl.text.trim()),
                _ConfirmRow('예금주', _holderCtrl.text.trim()),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue, foregroundColor: Colors.white),
                child: const Text('신청'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final hPad = ResponsiveLayout.pageHorizontal(context);
    final bottomPad = ResponsiveLayout.bottomSafeInset(context, extra: 8);
    return ConnectivityReconnectListener(
      onReconnect: _loadBalance,
      child: Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('출금신청')),
      body: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_balanceError != null)
              LoadErrorView(
                message: _balanceError!,
                onRetry: _loadBalance,
                compact: true,
              )
            else
              _BalanceCard(
                withdrawable: _withdrawable,
                fmt: _fmt,
                loading: _loadingBalance,
              ),
            const Gap(16),
            const _SectionLabel('출금액'),
            Row(
              children: [
                Expanded(
                  child: _InputBox(
                    controller: _amountCtrl,
                    hint: _loadingBalance
                        ? '잔액 불러오는 중...'
                        : '최소 ${_fmt(kWithdrawalMin)}원',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffix: const Text('원', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Gap(10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _loadingBalance || _maxRequestableAmount < kWithdrawalMin
                        ? null
                        : _fillAll,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('전액'),
                  ),
                ),
              ],
            ),
            if (!_loadingBalance) ...[
              const Gap(6),
              Text(
                '출금 가능 최대 100만원',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const Gap(12),
            const _SectionLabel('은행'),
            _BankSelector(
              selected: _selectedBank,
              onSelect: (b) => setState(() => _selectedBank = b),
            ),
            const Gap(12),
            const _SectionLabel('계좌번호'),
            _InputBox(
              controller: _accountCtrl,
              hint: '숫자만 입력',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-]'))],
            ),
            const Gap(12),
            const _SectionLabel('예금주'),
            _InputBox(controller: _holderCtrl, hint: '예금주 이름'),
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.orange.shade700, size: 18),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      '수수료 ${_fmt(kWithdrawalFee)}원 · 영업일 1~2일 내 처리',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('출금요청', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.withdrawable,
    required this.fmt,
    this.loading = false,
  });

  final int withdrawable;
  final String Function(int) fmt;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentBlue, AppTheme.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: loading
          ? const SizedBox(
              height: 64,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '출금 가능',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        '${fmt(withdrawable)}원',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 32,
                ),
              ],
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppTheme.primaryDark,
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.accentBlue, width: 1.5)),
      ),
    );
  }
}

class _BankSelector extends StatelessWidget {
  const _BankSelector({required this.selected, required this.onSelect});

  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('은행 선택', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.primaryDark),
          items: _kBanks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
          onChanged: (v) { if (v != null) onSelect(v); },
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
