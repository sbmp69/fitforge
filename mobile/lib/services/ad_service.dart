import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_service.dart';

class AdService {
  // Production Interstitial Ad Unit ID for Android
  static const String _interstitialAdUnitId = 'ca-app-pub-7402696944651355/8056244097';
  
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  static void loadInterstitialAd() {
    if (kIsWeb) return;
    
    // Do not load ads for premium users
    if (SubscriptionService.isPremium) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              // Preload the next ad
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load an interstitial ad: ${error.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  static void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null && !SubscriptionService.isPremium) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    }
  }
}
