import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'consent_service.dart';

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
  VoidCallback? _consentListener;

  bool get isReady => _rewardedAd != null;

  void loadRewardedAd({AdStateCallback? onStateChanged}) {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_isLoading || _rewardedAd != null) return;
    // UMP onayı gelmeden reklam istenmez; onay gelince yükleme otomatik yapılır.
    if (!ConsentService.canRequestAds.value) {
      _waitForConsent(onStateChanged);
      return;
    }
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

  void _waitForConsent(AdStateCallback? onStateChanged) {
    if (_consentListener != null) return;
    void listener() {
      if (!ConsentService.canRequestAds.value) return;
      _removeConsentListener();
      loadRewardedAd(onStateChanged: onStateChanged);
    }

    _consentListener = listener;
    ConsentService.canRequestAds.addListener(listener);
  }

  void _removeConsentListener() {
    final listener = _consentListener;
    if (listener == null) return;
    ConsentService.canRequestAds.removeListener(listener);
    _consentListener = null;
  }

  void showRewardedAd({
    required VoidCallback onRewarded,
    AdStateCallback? onStateChanged,
  }) {
    final ad = _rewardedAd;
    if (ad == null) return;
    // Gösterim başlar başlamaz temizle — aksi halde kullanıcı butona art arda
    // basarsa aynı reklam nesnesi tekrar show() edilip ödül birden fazla verilir.
    _rewardedAd = null;
    onStateChanged?.call(false);

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd(onStateChanged: onStateChanged);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Reklam gösterilemedi: ${error.message}');
        ad.dispose();
        loadRewardedAd(onStateChanged: onStateChanged);
      },
    );

    ad.show(onUserEarnedReward: (_, __) => onRewarded());
  }

  void dispose() {
    _removeConsentListener();
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
