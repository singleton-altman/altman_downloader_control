import 'package:talker/talker.dart';

class DownloaderLog {
  final Talker talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: true,
      maxHistoryItems: 100,
    ),
  );

  void e(String message) {
    talker.error(message);
  }

  void w(String message) {
    talker.warning(message);
  }

  void i(String message) {
    talker.info(message);
  }

  void d(String message) {
    talker.debug(message);
  }
}
