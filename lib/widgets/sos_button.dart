import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/emergency_service.dart';


/// Premium In-App SOS Emergency Button Widget.
/// Features subtle idle pulsing ambient aura, smooth gradient aesthetics,
/// haptic feedback, and a 2-second press-and-hold progress fill.
class SosButton extends StatefulWidget {
  final VoidCallback? onTriggered;

  const SosButton({super.key, this.onTriggered});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    // 2-second hold progress controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onHoldCompleted();
      }
    });

    // Ambient pulsing aura controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPressDown(PointerDownEvent event) {
    if (EmergencyService.instance.isEmergencyActive) return;
    setState(() => _isHolding = true);
    _progressController.forward(from: 0.0);
    HapticFeedback.selectionClick();
  }

  void _onPressUp(PointerUpEvent event) {
    _cancelHold();
  }

  void _onPressCancel(PointerCancelEvent event) {
    _cancelHold();
  }

  void _cancelHold() {
    if (_isHolding) {
      setState(() => _isHolding = false);
      _progressController.reset();
    }
  }

  void _onHoldCompleted() {
    _cancelHold();
    widget.onTriggered?.call();
    EmergencyService.instance.triggerEmergency(
      triggerType: EmergencyTriggerType.primarySosButton,
    );
  }

  void _onTap() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Press and hold for 2 seconds to trigger SafeRoute SOS',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmergencyActive = EmergencyService.instance.isEmergencyActive;

    return Listener(
      onPointerDown: _onPressDown,
      onPointerUp: _onPressUp,
      onPointerCancel: _onPressCancel,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = _isHolding ? 1.05 : (isEmergencyActive ? 1.0 : _pulseAnimation.value);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: _isHolding ? 146 : 76,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: _isHolding
                      ? const [Color(0xFFD32F2F), Color(0xFFB71C1C)]
                      : const [Color(0xFFFF3B30), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withValues(
                      alpha: _isHolding ? 0.65 : (0.25 * scale),
                    ),
                    blurRadius: _isHolding ? 14 : (8 * scale),
                    spreadRadius: _isHolding ? 2 : (1 * scale),
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: _isHolding ? 0.5 : 0.25),
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Visual Hold Progress Bar Fill
                    if (_isHolding)
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                          );
                        },
                      ),

                    // Button Content & Label
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isHolding ? 'HOLD 2s' : 'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: _isHolding ? 13 : 15,
                              letterSpacing: 1.2,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
