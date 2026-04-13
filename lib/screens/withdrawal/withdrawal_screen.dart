import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../api/mileage_api.dart';
import '../../api/withdrawal_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';

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
  int _balance = 0;
  int _withdrawable = 0;
  bool _loadingBalance = true;

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
    // 폼은 즉시 표시 — 잔액 카드만 로딩 상태로 시작
    try {
      final bal = await MileageApi.getBalance()
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _balance = bal.balance;
          _withdrawable = bal.withdrawable;
          _loadingBalance = false;
        });
      }
    } catch (_) {
      // 타임아웃·네트워크 오류 → 잔액 0으로 폼 표시
      if (mounted) setState(() => _loadingBalance = false);
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  void _fillAll() {
    final rounded = (_withdrawable ~/ 10000) * 10000;
    _amountCtrl.text = rounded > 0 ? rounded.toString() : '';
  }

  String? _validate() {
    final amountRaw = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amountRaw == null || amountRaw <= 0) return '출금액을 입력하세요.';
    if (amountRaw < 20000) return '최소 출금액은 20,000원입니다.';
    if (amountRaw % 10000 != 0) return '10,000원 단위로 입력하세요.';
    if (amountRaw > _withdrawable) return '출금가능액(${_fmt(_withdrawable)}원)을 초과했습니다.';
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
                _ConfirmRow('수수료', '500원'),
                const Divider(height: 20),
                _ConfirmRow('실수령액', '${_fmt(amount - 500)}원', bold: true),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('출금신청', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 잔액 카드
                  _BalanceCard(
                    balance: _balance,
                    withdrawable: _withdrawable,
                    fmt: _fmt,
                    onFillAll: _fillAll,
                    loading: _loadingBalance,
                  ),
                  const Gap(24),

                  // 출금액
                  _SectionLabel('출금액'),
                  Row(
                    children: [
                      Expanded(
                        child: _InputBox(
                          controller: _amountCtrl,
                          hint: '20,000원 이상, 10,000원 단위',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          suffix: const Text('원'),
                        ),
                      ),
                      const Gap(10),
                      OutlinedButton(
                        onPressed: _fillAll,
                        child: const Text('전액'),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // 은행 선택
                  _SectionLabel('은행'),
                  _BankSelector(
                    selected: _selectedBank,
                    onSelect: (b) => setState(() => _selectedBank = b),
                  ),
                  const Gap(16),

                  // 계좌번호
                  _SectionLabel('계좌번호'),
                  _InputBox(
                    controller: _accountCtrl,
                    hint: '숫자만 입력 (- 없이)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\-]'))],
                  ),
                  const Gap(16),

                  // 예금주
                  _SectionLabel('예금주'),
                  _InputBox(controller: _holderCtrl, hint: '예금주 이름'),
                  const Gap(20),

                  // 주의사항
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 18),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            '출금액은 20,000원 이상 10,000원 단위로 가능하며,\n출금 시 500원 수수료가 부과됩니다.\n영업일 기준 1~2일 내 처리됩니다.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(32),

                  // 출금요청 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 54,
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
                  const Gap(40),
                ],
              ),
            ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.withdrawable,
    required this.fmt,
    required this.onFillAll,
    this.loading = false,
  });

  final int balance;
  final int withdrawable;
  final String Function(int) fmt;
  final VoidCallback onFillAll;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentBlue, AppTheme.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('보유 마일리지', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      const Gap(4),
                      Text('${fmt(balance)}원',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const Gap(10),
                      Text('출금가능액', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                      Text('${fmt(withdrawable)}원',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
          if (!loading)
            Icon(Icons.account_balance_wallet, color: Colors.white.withValues(alpha: 0.6), size: 40),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 14), child: suffix) : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.accentBlue, width: 1.5)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('은행 선택', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
