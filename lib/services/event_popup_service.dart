import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// 앱 실행 시 이벤트 팝업 (일주일간 보지 않기 지원)
class EventPopupService {
  EventPopupService._();

  static const _hideUntilKey = 'event_popup_hide_until_ms';
  static const _bannerAsset = 'assets/images/banner_event_popup.png';
  static const _bannerAspectRatio = 445 / 421;

  /// 홈 진입 후 1회 호출 (업데이트 안내 이후 권장).
  static Future<void> promptIfNeeded(BuildContext context) async {
    if (!await shouldShow()) return;
    if (!context.mounted) return;
    await _showDialog(context);
  }

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final hideUntil = prefs.getInt(_hideUntilKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch >= hideUntil;
  }

  static Future<void> _hideForOneWeek() async {
    final until = DateTime.now().add(const Duration(days: 7));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hideUntilKey, until.millisecondsSinceEpoch);
  }

  static Future<void> _showDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            if (context.mounted) {
                              Navigator.pushNamed(context, '/friend-invite');
                            }
                          },
                          child: AspectRatio(
                            aspectRatio: _bannerAspectRatio,
                            child: Image.asset(
                              _bannerAsset,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(ctx).pop(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () async {
                              await _hideForOneWeek();
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade400),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('일주일간 보지 않기'),
                          ),
                        ),
                        const Gap(10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    if (context.mounted) {
                                      Navigator.pushNamed(context, '/event');
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.accentBlue,
                                    side: const BorderSide(color: AppTheme.accentBlue, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  child: const Text('이벤트 보기'),
                                ),
                              ),
                            ),
                            const Gap(10),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  child: const Text('닫기'),
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
            ),
          ),
        );
      },
    );
  }
}
