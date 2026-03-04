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

    if (outlined) {
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
            foregroundColor: AppConstants.accentCyan,
            side: const BorderSide(color: AppConstants.accentCyan, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    // Gradient or solid button
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ?? (backgroundColor == null ? AppConstants.accentGradient : null),
          color: gradient == null ? backgroundColor : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
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
              : (icon != null ? Icon(icon, size: 20) : const SizedBox.shrink()),
          label: Text(
            isLoading ? 'Please wait...' : label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isLoading ? fgColor.withValues(alpha: 0.5) : fgColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: fgColor,
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
