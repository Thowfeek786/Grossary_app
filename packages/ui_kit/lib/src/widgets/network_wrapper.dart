import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core/core.dart';
import 'app_button.dart';

class NetworkWrapper extends StatefulWidget {
  final Widget? child;

  const NetworkWrapper({super.key, this.child});

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _isOffline = false;
  late StreamSubscription<ConnectivityResult> _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final bool newOfflineState = result == ConnectivityResult.none;
    if (_isOffline != newOfflineState) {
      setState(() {
        _isOffline = newOfflineState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) {
      return widget.child ?? const SizedBox.shrink();
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          if (widget.child != null) Positioned.fill(child: widget.child!),
          Positioned.fill(
          child: Material(
            color: AppColors.background,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 80, color: AppColors.textSecondary),
                      const SizedBox(height: 24),
                      const Text(
                        'No Internet Connection',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Please check your network settings and try again. The app requires an active internet connection to function.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Try Again',
                        onTap: _checkInitialConnectivity,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
    );
  }
}
