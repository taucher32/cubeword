import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

typedef AdStateCallback = void Function(bool isReady);

class AdService {
  static const String _prodAdUnitId = 'ca-app-pub-8457022819902146/2379024978';

  // Google'ın resmi test reklam birimi ID'leri — debug/profile derlemelerde
  // gerçek reklam gösterip politika ihlaline yol açmamak için kullanılır.
  static const String _testAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testAdUnitIdIOS =
      'ca-app-pub-3940256099942544/1712485313';

  static String get _adUnitId {
    if (kReleaseMode) return _prodAdUnitId;
    return Platform.isIOS ? _testAdUnitIdIOS : _testAdUnitIdAndroid;
  }

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  bool get isReady => _rewardedAd != null;

  void loadRewardedAd({AdStateCallback? onStateChanged}) {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          onStateChanged?.call(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad yüklenemedi: ${error.message}');
          _isLoading = false;
          onStateChanged?.call(false);
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onRewarded,
    AdStateCallback? onStateChanged,
  }) {
    final ad = _rewardedAd;
    if (ad == null) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onStateChanged?.call(false);
        loadRewardedAd(onStateChanged: onStateChanged);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Reklam gösterilemedi: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        onStateChanged?.call(false);
        loadRewardedAd(onStateChanged: onStateChanged);
      },
    );

    ad.show(onUserEarnedReward: (_, __) => onRewarded());
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
