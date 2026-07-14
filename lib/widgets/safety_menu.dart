import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/dating_service.dart';

/// Bottom-sheet menu to block or report a user. Calls [onChanged] after a block
/// so the caller can refresh. Used from Discover and Matches.
Future<void> showSafetyMenu(
  BuildContext context, {
  required String userId,
  required String name,
  required Future<void> Function() onChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppConstants.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppConstants.warningColor),
            title: Text('Report $name',
                style: const TextStyle(color: AppConstants.textPrimary)),
            subtitle: const Text('Tell us what’s wrong',
                style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
            onTap: () async {
              Navigator.pop(ctx);
              await _reportFlow(context, userId, name);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: AppConstants.errorColor),
            title: Text('Block $name',
                style: const TextStyle(color: AppConstants.textPrimary)),
            subtitle: const Text('You won’t see each other again',
                style: TextStyle(color: AppConstants.textSecondary, fontSize: 12)),
            onTap: () async {
              Navigator.pop(ctx);
              final ok = await DatingService.blockUser(userId);
              if (ok) await onChanged();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? '$name blocked' : 'Could not block. Try again.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: ok ? AppConstants.bgElevated : AppConstants.errorColor,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

const _reasons = <String, String>{
  'inappropriate': 'Inappropriate photos or content',
  'harassment': 'Harassment or abuse',
  'fake': 'Fake profile or scam',
  'underage': 'Looks under 18',
  'other': 'Something else',
};

Future<void> _reportFlow(BuildContext context, String userId, String name) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppConstants.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          Text('Report $name',
              style: const TextStyle(
                  color: AppConstants.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._reasons.entries.map((e) => ListTile(
                title: Text(e.value, style: const TextStyle(color: AppConstants.textPrimary)),
                trailing: const Icon(Icons.chevron_right, color: AppConstants.textMuted),
                onTap: () => Navigator.pop(ctx, e.key),
              )),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;

  final ok = await DatingService.reportUser(userId, reason);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Thanks — your report was submitted.'
            : 'Could not submit report. Try again.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppConstants.bgElevated : AppConstants.errorColor,
      ),
    );
  }
}
