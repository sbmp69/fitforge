import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdService {
  // Real Unity Game IDs from environment variables
  static String get _androidGameId => dotenv.env['UNITY_ANDROID_GAME_ID'] ?? '800370432'; 
  static final String _iosGameId = '8545d44'; // Keep test for iOS until created

  // TODO: Replace these with your real Interstitial Ad Unit IDs
  static final String _androidInterstitial = 'Interstitial_Android';
  static final String _iosInterstitial = 'Interstitial_iOS';
  
  static final String _androidBanner = 'Banner_Android';
  static final String _iosBanner = 'Banner_iOS';

  static String get _gameId => Platform.isAndroid ? _androidGameId : _iosGameId;
  static String get _interstitialId => Platform.isAndroid ? _androidInterstitial : _iosInterstitial;
  static String get bannerId => Platform.isAndroid ? _androidBanner : _iosBanner;

  static DateTime? _lastAdTime;
  static Timer? _adTimer;

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
    _adTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (!SubscriptionService.isPremium) {
        showInterstitialAd(() {});
      }
    });
  }

  static void showInterstitialAd(Function onAdClosed) {
    // 2 Minute Cooldown for full-screen ads
    final now = DateTime.now();
    if (_lastAdTime != null && now.difference(_lastAdTime!).inMinutes < 2) {
      debugPrint('Ad skipped: 2 minute cooldown active.');
      onAdClosed();
      return;
    }

    bool closedHandled = false;

    void handleClose() {
      if (!closedHandled) {
        closedHandled = true;
        onAdClosed();
      }
    }

    // Attempt to load and show
    UnityAds.showVideoAd(
      placementId: _interstitialId,
      onStart: (placementId) => debugPrint('Unity Ad Started: $placementId'),
      onClick: (placementId) => debugPrint('Unity Ad Clicked: $placementId'),
      onSkipped: (placementId) {
        debugPrint('Unity Ad Skipped: $placementId');
        _lastAdTime = DateTime.now();
        handleClose();
      },
      onComplete: (placementId) {
        debugPrint('Unity Ad Completed: $placementId');
        _lastAdTime = DateTime.now();
        handleClose();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ad Failed: $error $message');
        // Do not update _lastAdTime if it failed, so it can try again
        handleClose();
      },
    );
  }
}
