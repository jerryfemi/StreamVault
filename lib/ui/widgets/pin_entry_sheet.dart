import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class PinEntrySheet extends StatefulWidget {
  final String correctPin;
  final VoidCallback onSuccess;

  const PinEntrySheet({
    super.key,
    required this.correctPin,
    required this.onSuccess,
  });

  /// Convenience method to show the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String correctPin,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) =>
          PinEntrySheet(correctPin: correctPin, onSuccess: onSuccess),
    );
  }

  @override
  State<PinEntrySheet> createState() => _PinEntrySheetState();
}

class _PinEntrySheetState extends State<PinEntrySheet>
    with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _error = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_entered.length >= widget.correctPin.length) return;
    HapticFeedback.lightImpact();
    setState(() {
      _error = false;
      _entered += digit;
    });

    if (_entered.length == widget.correctPin.length) {
      Future.delayed(const Duration(milliseconds: 200), _validate);
    }
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _error = false;
      _entered = _entered.substring(0, _entered.length - 1);
    });
  }

  void _validate() {
    if (_entered == widget.correctPin) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0);
      setState(() {
        _error = true;
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinLength = widget.correctPin.length;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle bar ──
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 28),

              // ── Title ──
              const Icon(
                Icons.shield_outlined,
                color: AppColors.accent,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Admin Access',
                style: AppTextStyles.heading2.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter PIN to continue',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 32),

              // ── PIN dots ──
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pinLength, (i) {
                    final filled = i < _entered.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: filled ? 16 : 14,
                      height: filled ? 16 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _error
                            ? AppColors.accent
                            : filled
                            ? AppColors.liveGreen
                            : AppColors.surfaceElevated,
                        border: Border.all(
                          color: _error
                              ? AppColors.accent
                              : filled
                              ? AppColors.liveGreen
                              : AppColors.textTertiary,
                          width: 2,
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color: _error
                                      ? AppColors.accentGlow
                                      : AppColors.liveGreenGlow,
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),

              // ── Error text ──
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _error ? 1.0 : 0.0,
                child: Text(
                  'Incorrect PIN',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Number pad ──
              _buildNumPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumPad() {
    const digits = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: digits.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((d) {
              if (d.isEmpty) {
                return const SizedBox(width: 80, height: 56);
              }
              final isDelete = d == '⌫';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    splashColor: AppColors.accent.withValues(alpha: 0.2),
                    onTap: isDelete ? _onDelete : () => _onDigit(d),
                    child: Container(
                      width: 68,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDelete
                            ? Colors.transparent
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(28),
                        border: isDelete
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: isDelete
                          ? const Icon(
                              Icons.backspace_outlined,
                              color: AppColors.textSecondary,
                              size: 22,
                            )
                          : Text(
                              d,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
