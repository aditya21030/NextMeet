class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static bool isInitialized = true;

  static Future<void> initialize() async {}
  Future<void> showInterstitialAd({void Function()? onAdDismissed}) async {
    onAdDismissed?.call();
  }
}
