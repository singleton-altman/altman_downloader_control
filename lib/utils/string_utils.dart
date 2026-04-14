import 'package:altman_downloader_control/model/qb_preferences_model.dart';

extension QBPreferencesModelExtension on QBPreferencesModel {
  /// 获取下载速度限制显示文本
  String get downloadLimitText {
    if (dlLimit == 0) return '无限制';
    return '${dlLimit.toHumanReadableFileSize(round: 1)}/s';
  }

  /// 获取上传速度限制显示文本
  String get uploadLimitText {
    if (upLimit == 0) return '无限制';
    return '${upLimit.toHumanReadableFileSize(round: 1)}/s';
  }
}

extension IntExtension on int {
  String toHumanReadableFileSize({int round = 0}) {
    return this.toDouble().toHumanReadableFileSize(round: round);
  }
}

extension DoubleExtension on double {
  String toHumanReadableFileSize({int round = 2, bool useBase1024 = true}) {
    if (this <= 0) {
      return '0B';
    }
    const List<String> affixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

    num divider = useBase1024 ? 1024 : 1000;

    num size = this;
    num runningDivider = divider;
    num runningPreviousDivider = 0;
    int affix = 0;

    while (size >= runningDivider && affix < affixes.length - 1) {
      runningPreviousDivider = runningDivider;
      runningDivider *= divider;
      affix++;
    }

    String result =
        (runningPreviousDivider == 0 ? size : size / runningPreviousDivider)
            .toStringAsFixed(round);

    // 只有当 round > 0 时才检查并移除末尾的零
    if (round > 0 && result.endsWith("0" * round)) {
      result = result.substring(0, result.length - round - 1);
    }

    return "$result ${affixes[affix]}";
  }
}
