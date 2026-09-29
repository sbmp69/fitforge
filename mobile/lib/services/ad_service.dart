import 'dart:io';
import 'dart:async';
import 'subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

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
