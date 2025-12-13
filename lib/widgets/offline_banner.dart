import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/network/connectivity_service.dart';

/// Global offline banner widget that shows when the device is offline
/// 
/// Place this in a Stack above the main content with positioned at bottom
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> 
    with SingleTickerProviderStateMixin {
  late StreamSubscription<NetworkStatus> _subscription;
  bool _isOffline = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation for slide in/out
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start above screen (slide down from top)
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Check initial status
    _isOffline = !ConnectivityService.instance.isOnline;
    if (_isOffline) {
      _animationController.forward();
    }
    
    // Listen for connectivity changes
    _subscription = ConnectivityService.instance.onStatusChange.listen((status) {
      final wasOffline = _isOffline;
      _isOffline = status == NetworkStatus.offline;
      
      if (_isOffline && !wasOffline) {
        _animationController.forward();
      } else if (!_isOffline && wasOffline) {
        _animationController.reverse();
      }
      
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't render at all when not offline and animation is complete
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Hide completely when online and animation finished reversing
        if (!_isOffline && _animationController.value == 0) {
          return const SizedBox.shrink();
        }
        
        return SlideTransition(
          position: _slideAnimation,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935), // Red error color
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2), // Shadow below banner
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, // Left aligned to avoid FAB overlap
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'You are offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper widget that adds offline banner to any screen
/// 
/// Use this to wrap the body of Scaffold:
/// ```dart
/// Scaffold(
///   body: OfflineAwareBody(
///     child: YourActualContent(),
///   ),
/// )
/// ```
class OfflineAwareBody extends StatelessWidget {
  final Widget child;
  final bool showAboveBottomNav;
  
  const OfflineAwareBody({
    super.key,
    required this.child,
    this.showAboveBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Position banner at top below app bar
        const Positioned(
          left: 0,
          right: 0,
          top: 0, // At the top
          child: OfflineBanner(),
        ),
      ],
    );
  }
}
