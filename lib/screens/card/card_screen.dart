import 'package:flutter/material.dart';

import '../../api/cards_api.dart';
import '../../config/portone_config.dart';
import '../../services/biometric_payment_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';
import 'card_register_payment_screen.dart';

/// 카드등록 - GET /cards, POST /cards (cardToken 필요), DELETE /cards/:id
/// cardToken은 PG(PortOne 등) 연동 시 발급
class CardScreen extends StatefulWidget {
  const CardScreen({super.key});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  List<RegisteredCard> _cards = [];
  bool _loading = true;
  bool _biometricSupported = false;
  bool _useBiometric = false;
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _optionController = TextEditingController();
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _expiryController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await CardsApi.getList();
      final bioSupported = await BiometricPaymentService.isSupported;
      final useBio = await BiometricPaymentService.useBiometricForAppPayment;
      if (mounted) {
        setState(() {
          _cards = list;
          _biometricSupported = bioSupported;
          _useBiometric = useBio;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cards = [];
          _biometricSupported = false;
          _useBiometric = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _onRegister() async {
    final cardName = _cardNameController.text.trim();
    if (cardName.isEmpty) {
      showErrorSnackBar(context, '카드명을 입력해주세요.');
      return;
    }

    if (!isPortoneConfigured) {
      showErrorSnackBar(
        context,
        'PG 설정이 필요합니다.\ndocs/CARD_REGISTRATION.md 참고 → portone_config.dart에 storeId, channelKey 입력',
      );
      return;
    }

    final expiry = _expiryController.text.trim();
    final option = _optionController.text.trim();

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CardRegisterPaymentScreen(
          cardName: cardName,
          expiryDate: expiry,
          option: option,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final billingKey = result['billingKey'] as String?;
    final txId = result['transactionId'] as String?;
    final cardToken = (billingKey != null && billingKey.isNotEmpty)
        ? billingKey
        : txId;
    if (cardToken == null || cardToken.isEmpty) return;

    if (billingKey == null || billingKey.isEmpty) {
      debugPrint(
        '[CardScreen] billingKey 없음 - transactionId 사용. '
        '등록 카드 결제 실패 가능. PortOne 채널 빌링키 발급 옵션 확인 필요.',
      );
    }

    setState(() => _isRegistering = true);
    try {
      await CardsApi.register(
        cardToken: cardToken,
        cardName: cardName,
        expiryDate: expiry.isNotEmpty ? expiry : null,
        option: option.isNotEmpty ? option : null,
      );
      if (mounted) {
        showSuccessSnackBar(context, '카드 등록 완료');
        _cardNameController.clear();
        _expiryController.clear();
        _optionController.clear();
        _load();
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, '카드 등록 실패. 백엔드 연동 확인 필요.');
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Future<void> _onDelete(RegisteredCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('카드 삭제'),
        content: Text('${card.cardName}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _isRegistering = true);
    try {
      await CardsApi.delete(card.id);
      if (mounted) {
        showSuccessSnackBar(context, '카드가 삭제되었습니다.');
        _load();
      }
    } catch (_) {
      if (mounted) showErrorSnackBar(context, '삭제에 실패했습니다.');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('카드등록', style: TextStyle(color: Colors.black87)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카드 추가',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cardNameController,
                    decoration: InputDecoration(
                      hintText: '카드명 (예: 우리카드 끝자리 1234)',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      hintText: '유효기간 (MM/YY)',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _optionController,
                    decoration: InputDecoration(
                      hintText: '옵션 (영수증 발급 시 필요)',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isRegistering ? null : _onRegister,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                      child: const Text('카드 등록'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '등록된 카드',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_cards.isEmpty)
                    Text('등록된 카드가 없습니다.', style: TextStyle(color: Colors.grey.shade600))
                  else
                    ..._cards.map(
                      (c) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(Icons.credit_card, color: AppTheme.accentBlue),
                          title: Text(c.cardName),
                          subtitle: c.last4Digits != null ? Text('끝자리 ${c.last4Digits}') : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => _onDelete(c),
                          ),
                        ),
                      ),
                    ),
                  if (_biometricSupported) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '생체인증 사용',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch.adaptive(
                            value: _useBiometric,
                            onChanged: (v) async {
                              await BiometricPaymentService.setUseBiometricForAppPayment(v);
                              if (mounted) setState(() => _useBiometric = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    '카드거래시 유의사항',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _Bullet('카드정보는 암호화 알고리즘에 의해 100%보호됩니다.'),
                  _Bullet('등록된 카드는 당사서버에 저장하지 않습니다.(단, 카드사서버에는 거래시 기록됨)'),
                  _Bullet('카드거래시, 요금의 10% 마일리지적립.'),
                  _Bullet('카드거래취소시, 3분안에 환불됩니다.'),
                ],
              ),
            ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
