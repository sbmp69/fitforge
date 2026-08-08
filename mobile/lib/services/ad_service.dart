import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_service.dart';
import '../router/app_router.dart';
import '../screens/paywall/paywall_screen.dart';

class AdService {
  // Production Interstitial Ad Unit ID for Android
  static const String _interstitialAdUnitId = 'ca-app-pub-7402696944651355/8056244097';
  
  // Test Banner Ad Unit ID
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdReady = false;
  static Timer? _adLoopTimer;
  
  // Flag to temporarily suppress ads (e.g. when on Paywall or Profile screen)
  static bool suppressAds = true;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    startAdLoop();
  }

  static void startAdLoop() {
    _adLoopTimer?.cancel();
    _adLoopTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (SubscriptionService.isPremium) {
        timer.cancel();
        return;
      }
      
      // Do not show ad if currently suppressed by a screen
      if (suppressAds) return;

      showInterstitialAd();
    });
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

              // Show popup
              final ctx = AppRouter.navigatorKey.currentContext;
              if (ctx != null) {
                showDialog(
                  context: ctx,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text('Go Ad-Free! 🚀', style: TextStyle(color: Colors.white)),
                    content: const Text('Tired of ads? Subscribe to PRO for an entirely ad-free experience with unlimited AI generations!', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later', style: TextStyle(color: Colors.white54))),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                        },
                        child: const Text('Upgrade Now', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
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

  static BannerAd? loadBannerAd({required Function(Ad) onLoaded, required Function(Ad, LoadAdError) onFailed}) {
    if (kIsWeb || SubscriptionService.isPremium) return null;

    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: onFailed,
      ),
    );
    bannerAd.load();
    return bannerAd;
  }
}
