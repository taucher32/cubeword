import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) ile GDPR/kullanıcı onayını yönetir.
/// Reklam isteği yalnızca UMP `canRequestAds()` true döndürdükten sonra yapılır;
/// MobileAds SDK'sı da o noktada başlatılır.
class ConsentService {
  ConsentService._();

  /// Reklam istenebilir mi? AdService bunu dinleyip onay gelince yükleme yapar.
  static final ValueNotifier<bool> canRequestAds = ValueNotifier<bool>(false);

  /// Kullanıcıya "Gizlilik ayarları" girişi gösterilmeli mi (ör. AB'deki
  /// kullanıcılar onayını sonradan değiştirebilmeli).
  static final ValueNotifier<bool> privacyOptionsRequired =
      ValueNotifier<bool>(false);

  static bool _isGathering = false;
  static bool _mobileAdsInitialized = false;

  static bool get _isSupportedPlatform => Platform.isAndroid || Platform.isIOS;

  /// Onay bilgisini günceller, gerekiyorsa onay formunu gösterir ve izin
  /// varsa MobileAds'i başlatır. Hatalar yutulur — oyun reklamsız devam eder.
  static Future<void> gatherConsent() async {
    if (!_isSupportedPlatform || _isGathering) return;
    _isGathering = true;
    try {
      // Önceki oturumdan kalan onay varsa formu beklemeden reklama izin ver.
      await _refreshCanRequestAds();

      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (formError != null) {
              debugPrint('Onay formu hatası: ${formError.message}');
            }
            if (!completer.isCompleted) completer.complete();
          });
        },
        (formError) {
          debugPrint('Onay bilgisi güncellenemedi: ${formError.message}');
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future;

      await _refreshCanRequestAds();
      privacyOptionsRequired.value =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('Onay akışı başarısız: $e');
    } finally {
      _isGathering = false;
    }
  }

  /// Kullanıcının onay tercihini değiştirebileceği gizlilik formunu açar.
  static Future<void> showPrivacyOptionsForm() async {
    if (!_isSupportedPlatform) return;
    await ConsentForm.showPrivacyOptionsForm((formError) {
      if (formError != null) {
        debugPrint('Gizlilik formu hatası: ${formError.message}');
      }
    });
    await _refreshCanRequestAds();
  }

  static Future<void> _refreshCanRequestAds() async {
    final allowed = await ConsentInformation.instance.canRequestAds();
    if (allowed && !_mobileAdsInitialized) {
      _mobileAdsInitialized = true;
      await MobileAds.instance.initialize();
    }
    canRequestAds.value = allowed;
  }
}
