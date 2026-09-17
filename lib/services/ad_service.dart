import 'dart:async';
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

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  // --- UMP (AB/İngiltere/İsviçre GDPR izni) ---

  static Future<bool>? _adsAllowed;

  /// İzin akışını uygulama başına bir kez çalıştırır: gerekirse izin formunu
  /// gösterir, reklam istenebiliyorsa Mobile Ads SDK'yı başlatır. Tüm çağıranlar
  /// aynı sonucu bekler. Başarısız olursa bir sonraki çağrı yeniden dener.
  static Future<bool> ensureConsent() =>
      _adsAllowed ??= _gatherConsent().then((allowed) {
        if (!allowed) _adsAllowed = null;
        return allowed;
      });

  static Future<bool> _gatherConsent() async {
    if (!_isMobile) return false;
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        _consentParams(),
        () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) debugPrint('İzin formu: ${error.message}');
          done.complete();
        }),
        (error) {
          debugPrint('İzin bilgisi alınamadı: ${error.message}');
          done.complete();
        },
      );
      await done.future;
      // Güncelleme başarısız olsa bile önceki oturumdaki izin geçerli olabilir
      if (!await ConsentInformation.instance.canRequestAds()) return false;
      await MobileAds.instance.initialize();
      return true;
    } catch (e) {
      debugPrint('İzin akışı hatası: $e');
      return false;
    }
  }

  static ConsentRequestParameters _consentParams() {
    // Emülatörde AB kullanıcısı gibi denemek için (yalnızca debug):
    // flutter run --dart-define=UMP_DEBUG_EEA=true
    if (kDebugMode && const bool.fromEnvironment('UMP_DEBUG_EEA')) {
      return ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
          // Debug coğrafyası yalnızca test cihazlarında geçerli. Kimlik logcat'te
          // "addTestDeviceHashedId" satırında yazar; bu, Medium_Phone emülatörü.
          testIdentifiers: ['B3EEABB8EE11C2BE770B684D95219ECB'],
        ),
      );
    }
    return ConsentRequestParameters();
  }

  /// AB gibi bölgelerde kullanıcı iznini sonradan değiştirebilmeli;
  /// true ise arayüz bir "gizlilik ayarları" girişi göstermeli.
  static Future<bool> isPrivacyOptionsRequired() async {
    if (!_isMobile) return false;
    await ensureConsent();
    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  static void showPrivacyOptionsForm({VoidCallback? onDismissed}) {
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Gizlilik formu: ${error.message}');
      onDismissed?.call();
    });
  }

  // --- Ödüllü reklam ---

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _disposed = false;

  bool get isReady => _rewardedAd != null;

  Future<void> loadRewardedAd({AdStateCallback? onStateChanged}) async {
    if (!_isMobile) return;
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;
    // İzin alınmadan reklam istemek AB/İngiltere'de politika ihlali
    if (!await ensureConsent() || _disposed) {
      _isLoading = false;
      return;
    }
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          if (_disposed) {
            ad.dispose();
            return;
          }
          _rewardedAd = ad;
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
    _disposed = true;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
