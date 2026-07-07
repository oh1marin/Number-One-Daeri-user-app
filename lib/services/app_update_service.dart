import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/app_version_api.dart';
import '../config/app_update_config.dart';
import '../theme/app_theme.dart';

enum AppUpdateKind { none, optional, required }

class AppUpdatePrompt {
  const AppUpdatePrompt({
    required this.kind,
    required this.message,
    required this.storeUrl,
    required this.targetBuildNumber,
  });

  final AppUpdateKind kind;
  final String message;
  final String storeUrl;
  final int targetBuildNumber;
}

class AppUpdateService {
  AppUpdateService._();

  static const _dismissedBuildKey = 'app_update_dismissed_build';

  /// 스플래시 이후 첫 화면에서 1회 호출.
  static Future<void> promptIfNeeded(BuildContext context) async {
    final prompt = await checkForUpdate();
    if (prompt == null || prompt.kind == AppUpdateKind.none) return;
    if (!context.mounted) return;
    await _showDialog(context, prompt);
  }

  static Future<AppUpdatePrompt?> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(info.buildNumber) ?? 0;

    final policy = await AppVersionApi.fetchPolicy();
    if (policy == null || policy.targetBuildNumber <= 0) return null;
    if (currentBuild >= policy.targetBuildNumber) return null;

    final storeUrl = policy.storeUrlAndroid.isNotEmpty
        ? policy.storeUrlAndroid
        : AppUpdateConfig.playStoreHttpsUrl;

    if (policy.forceUpdate) {
      return AppUpdatePrompt(
        kind: AppUpdateKind.required,
        message: policy.message,
        storeUrl: storeUrl,
        targetBuildNumber: policy.targetBuildNumber,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getInt(_dismissedBuildKey) ?? 0;
    if (dismissed >= policy.targetBuildNumber) return null;

    return AppUpdatePrompt(
      kind: AppUpdateKind.optional,
      message: policy.message,
      storeUrl: storeUrl,
      targetBuildNumber: policy.targetBuildNumber,
    );
  }

  static Future<void> _showDialog(
    BuildContext context,
    AppUpdatePrompt prompt,
  ) {
    final required = prompt.kind == AppUpdateKind.required;

    return showDialog<void>(
      context: context,
      barrierDismissible: !required,
      builder: (ctx) {
        return PopScope(
          canPop: !required,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: EdgeInsets.fromLTRB(24, 20, required ? 24 : 12, 0),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    required ? '업데이트 필요' : '업데이트 안내',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                if (!required)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _dismissOptional(ctx, prompt),
                    icon: Icon(Icons.close, color: Colors.grey.shade500),
                  ),
              ],
            ),
            content: Text(
              prompt.message,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              if (!required)
                TextButton(
                  onPressed: () => _dismissOptional(ctx, prompt),
                  child: const Text('나중에'),
                ),
              FilledButton(
                onPressed: () => _openStore(prompt.storeUrl),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                ),
                child: const Text('업데이트'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _dismissOptional(
    BuildContext ctx,
    AppUpdatePrompt prompt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedBuildKey, prompt.targetBuildNumber);
    if (ctx.mounted) Navigator.of(ctx).pop();
  }

  static Future<void> _openStore(String storeUrl) async {
    final urls = <String>[
      if (Platform.isAndroid) AppUpdateConfig.playStoreMarketUrl,
      storeUrl,
      AppUpdateConfig.playStoreHttpsUrl,
    ];

    for (final raw in urls) {
      final uri = Uri.tryParse(raw);
      if (uri == null) continue;
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {}
    }
  }
}
