import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/call_options.dart';
import '../../theme/app_theme.dart';

/// 대리호출 옵션 선택 (오토/스틱, 대리/탁송, 퀵보드, 차량종류)
/// CallMapScreen에서 대리호출 버튼 시 push → 선택 후 pop(options) 반환
class CallOptionsScreen extends StatefulWidget {
  const CallOptionsScreen({super.key});

  @override
  State<CallOptionsScreen> createState() => _CallOptionsScreenState();
}

class _CallOptionsScreenState extends State<CallOptionsScreen> {
  String _transmission = 'auto';
  String _serviceType = 'daeri';
  String _quickBoard = 'possible';
  String _vehicleType = 'sedan';

  CallOptions get _options => CallOptions(
        transmission: _transmission,
        serviceType: _serviceType,
        quickBoard: _quickBoard,
        vehicleType: _vehicleType,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('대리호출 옵션', style: TextStyle(color: Colors.black87, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Section(
              title: '변속기',
              children: [
                _OptionChip(
                  label: '오토',
                  selected: _transmission == 'auto',
                  onTap: () => setState(() => _transmission = 'auto'),
                ),
                const Gap(8),
                _OptionChip(
                  label: '스틱',
                  selected: _transmission == 'stick',
                  onTap: () => setState(() => _transmission = 'stick'),
                ),
              ],
            ),
            const Gap(20),
            _Section(
              title: '서비스 유형',
              children: [
                _OptionChip(
                  label: '대리운전',
                  selected: _serviceType == 'daeri',
                  onTap: () => setState(() => _serviceType = 'daeri'),
                ),
                const Gap(8),
                _OptionChip(
                  label: '탁송',
                  selected: _serviceType == 'taksong',
                  onTap: () => setState(() => _serviceType = 'taksong'),
                ),
              ],
            ),
            const Gap(20),
            _Section(
              title: '퀵보드',
              children: [
                _OptionChip(
                  label: '가능',
                  selected: _quickBoard == 'possible',
                  onTap: () => setState(() => _quickBoard = 'possible'),
                ),
                const Gap(8),
                _OptionChip(
                  label: '불가',
                  selected: _quickBoard == 'impossible',
                  onTap: () => setState(() => _quickBoard = 'impossible'),
                ),
              ],
            ),
            const Gap(20),
            _Section(
              title: '차량 종류',
              children: [
                _OptionChip(
                  label: '승용차',
                  selected: _vehicleType == 'sedan',
                  onTap: () => setState(() => _vehicleType = 'sedan'),
                ),
                const Gap(8),
                _OptionChip(
                  label: '9인승',
                  selected: _vehicleType == '9seater',
                  onTap: () => setState(() => _vehicleType = '9seater'),
                ),
                const Gap(8),
                _OptionChip(
                  label: '12인승',
                  selected: _vehicleType == '12seater',
                  onTap: () => setState(() => _vehicleType = '12seater'),
                ),
                const Gap(8),
                _OptionChip(
                  label: '화물 1톤',
                  selected: _vehicleType == 'cargo1t',
                  onTap: () => setState(() => _vehicleType = 'cargo1t'),
                ),
              ],
            ),
            const Gap(32),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _options),
                icon: const PhosphorIcon(PhosphorIconsRegular.check, size: 22),
                label: const Text('확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const Gap(10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentBlue.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.accentBlue : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppTheme.accentBlue : Colors.black87,
          ),
        ),
      ),
    );
  }
}
