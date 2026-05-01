/// Uygulama genelindeki sabit değerler.
/// IP adresini kendi WiFi IP'nle değiştir!
class AppConfig {
  // Android gerçek telefon: bilgisayarının WiFi IP'si (cmd → ipconfig → IPv4)
  static const String baseUrl = "http://192.168.1.102:8000";

  // Zaman aşımı
  static const Duration timeout = Duration(seconds: 10);
}
