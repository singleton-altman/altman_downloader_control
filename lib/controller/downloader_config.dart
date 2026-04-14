enum DownloaderType { qbittorrent, transmission }

class DownloaderConfig {
  final String id;
  final String url;
  final String password;
  final String username;
  final DownloaderType type;
  String? name;
  DownloaderConfig({
    required this.id,
    required this.url,
    required this.username,
    required this.password,
    required this.type,
    String? name,
  }) : name = name ?? '';

  /// 检查配置是否有效
  /// 可以根据不同的下载器类型进行不同的验证
  bool get isValid {
    if (url.isEmpty) return false;
    // 可以根据 type 进行不同的验证逻辑
    // type 100 = qBittorrent, type 200 = Transmission 等
    switch (type) {
      case DownloaderType.qbittorrent: // qBittorrent
        return username.isNotEmpty && password.isNotEmpty;
      case DownloaderType.transmission: // Transmission
        // Transmission 可能不需要用户名密码，或者需要其他验证
        return true;
      default:
        return username.isNotEmpty && password.isNotEmpty;
    }
  }

  factory DownloaderConfig.fromJson(Map<String, dynamic> json) =>
      DownloaderConfig(
        id: json['id'],
        url: json['url'],
        username: json['username'],
        password: json['password'],
        type: json['type'],
        name: json['name'],
      );
}
