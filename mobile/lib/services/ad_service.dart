import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'subscription_service.dart';
import '../router/app_router.dart';
import '../screens/paywall/paywall_screen.dart';

class AdService {
  static String get _androidGameId => dotenv.env['UNITY_ANDROID_GAME_ID'] ?? '800370432'; 
  static final String _iosGameId = '8545d44';

  static final String _androidInterstitial = 'Interstitial_Android';
  static final String _iosInterstitial = 'Interstitial_iOS';
  
  static final String _androidBanner = 'Banner_Android';
  static final String _iosBanner = 'Banner_iOS';

  static String get _gameId => Platform.isAndroid ? _androidGameId : _iosGameId;
  static String get _interstitialId => Platform.isAndroid ? _androidInterstitial : _iosInterstitial;
  static String get bannerId => Platform.isAndroid ? _androidBanner : _iosBanner;

  static Timer? _adTimer;
  static int _secondsElapsed = 0;
  static bool _isAdShowing = false;
  static const int _targetSeconds = 120; // 2 minutes

  static void init() {
    UnityAds.init(
      gameId: _gameId,
      testMode: false,
      onComplete: () => debugPrint('Unity Ads Initialization Complete'),
      onFailed: (error, message) => debugPrint('Unity Ads Initialization Failed: $error $message'),
    );
  }

  static void startAdTimer() {
    _adTimer?.cancel();
    _secondsElapsed = 0;
    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!SubscriptionService.isPremium && !_isAdShowing) {
        _secondsElapsed++;
        if (_secondsElapsed >= _targetSeconds) {
          _secondsElapsed = 0;
          showInterstitialAd(() {});
        }
      }
    });
  }

  static void _showPostAdPopup() {
    final ctx = AppRouter.navigatorKey.currentContext;
    if (ctx != null && !SubscriptionService.isPremium) {
      showDialog(
        context: ctx,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Go Ad-Free! 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            'Tired of ads? Subscribe to PRO for an entirely ad-free experience with unlimited AI generations!',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              child: const Text('Upgrade Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  static void showInterstitialAd(Function onAdClosed) {
    if (SubscriptionService.isPremium) {
      onAdClosed();
      return;
    }

    _isAdShowing = true;
    bool closedHandled = false;

    void handleClose() {
      if (!closedHandled) {
        closedHandled = true;
        _isAdShowing = false;
        _secondsElapsed = 0; // Reset timer since they just saw an ad
        onAdClosed();
        _showPostAdPopup();
      }
    }

    UnityAds.load(
      placementId: _interstitialId,
      onComplete: (placementId) {
        UnityAds.showVideoAd(
          placementId: placementId,
          onStart: (placementId) => debugPrint('Unity Ad Started: $placementId'),
          onClick: (placementId) => debugPrint('Unity Ad Clicked: $placementId'),
          onSkipped: (placementId) {
            debugPrint('Unity Ad Skipped: $placementId');
            handleClose();
          },
          onComplete: (placementId) {
            debugPrint('Unity Ad Completed: $placementId');
            handleClose();
          },
          onFailed: (placementId, error, message) {
            debugPrint('Unity Ad Failed: $error $message');
            handleClose();
          },
        );
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ad Load Failed: $error $message');
        handleClose();
      },
    );
  }
}
