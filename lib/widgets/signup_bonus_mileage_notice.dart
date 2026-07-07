import 'package:flutter/material.dart';

/// 신규 가입 보너스 마일리지 사용 조건 안내
const String kSignupBonusMileageNotice =
    '신규 가입 10,000P는 대리 호출 이용에만 사용할 수 있습니다.';

class SignupBonusMileageNotice extends StatelessWidget {
  const SignupBonusMileageNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kSignupBonusMileageNotice,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
