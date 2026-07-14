import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// A styled, reusable button with gradient support and loading state.
class HelixButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final LinearGradient? gradient;
  final bool outlined;

  const HelixButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = foregroundColor ?? AppConstants.bgPrimary;
    // Disabled = no handler and not mid-load. Render it visibly greyed so users
    // can see the action isn't available yet (e.g. consent boxes not all ticked).
    final disabled = onPressed == null && !isLoading;

    if (outlined) {
      final outlineColor = disabled ? AppConstants.textMuted : AppConstants.accentCyan;
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? _loadingIndicator(AppConstants.accentCyan)
              : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
          label: Text(
            isLoading ? 'Please wait...' : label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: outlineColor,
            disabledForegroundColor: AppConstants.textMuted,
            side: BorderSide(color: outlineColor, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    // Gradient or solid button
    final contentColor = disabled ? AppConstants.textMuted : fgColor;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // Greyed flat fill when disabled — no gradient, no glow.
          gradient: disabled ? null : (gradient ?? (backgroundColor == null ? AppConstants.accentGradient : null)),
          color: disabled ? AppConstants.bgElevated : (gradient == null ? backgroundColor : null),
          borderRadius: BorderRadius.circular(14),
          border: disabled ? Border.all(color: AppConstants.borderColor) : null,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: (gradient?.colors.first ?? backgroundColor ?? AppConstants.accentCyan)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? _loadingIndicator(fgColor)
              : (icon != null ? Icon(icon, size: 20, color: contentColor) : const SizedBox.shrink()),
          label: Text(
            isLoading ? 'Please wait...' : label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isLoading ? fgColor.withValues(alpha: 0.5) : contentColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: fgColor,
            disabledForegroundColor: AppConstants.textMuted,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingIndicator(Color color) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color,
      ),
    );
  }
}
