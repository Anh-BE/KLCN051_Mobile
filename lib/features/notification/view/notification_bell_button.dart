import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../logic/notification_service.dart';
import 'notification_bottom_sheet.dart';

class NotificationBellButton extends StatefulWidget {
  final Color iconColor;
  final Color? backgroundColor;
  final double size;

  const NotificationBellButton({
    super.key,
    this.iconColor = Colors.white,
    this.backgroundColor,
    this.size = 22,
  });

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton>
    with SingleTickerProviderStateMixin {
  final NotificationService _service = NotificationService();
  late AnimationController _animController;
  late Animation<double> _shakeAnimation;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.18, end: 0.18), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.18, end: -0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));

    _lastCount = _service.unreadCount;
    _service.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (_service.unreadCount > _lastCount) {
      // Có thông báo mới tới -> Rung chuông!
      _animController.forward(from: 0.0);
    }
    _lastCount = _service.unreadCount;
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final unread = _service.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => NotificationBottomSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _shakeAnimation.value * math.pi,
                        alignment: Alignment.topCenter,
                        child: child,
                      );
                    },
                    child: Icon(
                      unread > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                      color: widget.iconColor,
                      size: widget.size,
                    ),
                  ),
                ),
              ),
            ),

            // Badge hiển thị số lượng chưa đọc hoặc chấm đỏ
            if (unread > 0)
              Positioned(
                right: 1,
                top: 1,
                child: IgnorePointer(
                  child: Container(
                    padding: unread > 9
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                        : const EdgeInsets.all(3.5),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: unread > 9 ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: unread > 9 ? BorderRadius.circular(10) : null,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
