/// qBittorrent 本地化字符串
/// 对应 Localizable.strings 中的定义
class QBLocalizable {
  // Common
  static const String unknown = '未知';
  static const String unknownTitle = '未知标题';
  static const String unknownUser = '未知用户';
  static const String unknownName = '未知名称';
  static const String unknownVersion = '未知版本';

  // Torrent States
  static const String stopped = '已停止';
  static const String stoppedDL = '已停止下载';
  static const String stoppedUP = '已停止上传';
  static const String checking = '检查中';
  static const String downloading = '下载中';
  static const String paused = '已暂停';
  static const String seeding = '做种中';
  static const String queuedToSeed = '排队做种';

  // TorrentState2 States
  static const String uploading = '上传中';
  static const String pausedDownload = '暂停下载';
  static const String pausedUpload = '暂停上传';
  static const String forcedDownload = '强制下载';
  static const String forcedUpload = '强制上传';
  static const String metaDownload = '元数据下载';
  static const String forcedMetaDownload = '强制元数据下载';
  static const String stalledDownload = '下载停滞';
  static const String stalledUpload = '上传停滞';
  static const String checkingDownload = '检查下载';
  static const String checkingUpload = '检查上传';
  static const String checkingResumeData = '检查恢复数据';
  static const String queuedDownload = '排队下载';
  static const String queuedUpload = '排队上传';
  static const String moving = '移动中';
  static const String error = '错误';
  static const String missingFiles = '文件缺失';

  // TorrentStateFilter
  static const String all = '全部';
  static const String completed = '已完成';
  static const String resumed = '已恢复';
  static const String active = '活跃';
  static const String inactive = '非活跃';
  static const String stalled = '停滞';

  static String getStateText(String state) {
    switch (state.toLowerCase()) {
      case 'downloading':
        return downloading;
      case 'seeding':
        return seeding;
      case 'stopped':
        return stopped;
      case 'checking':
        return checking;
      case 'paused':
        return paused;
      case 'uploading':
        return uploading;
      case 'paused_download':
        return pausedDownload;
      case 'paused_upload':
        return pausedUpload;
      case 'forced_download':
        return forcedDownload;
      case 'forced_upload':
        return forcedUpload;
      case 'meta_download':
        return metaDownload;
      case 'forced_meta_download':
        return forcedMetaDownload;
      case 'stalled_download':
      case 'stalleddl':
        return stalledDownload;
      case 'stalled_upload':
      case 'stalledup':
        return stalledUpload;
      case 'checking_download':
        return checkingDownload;
      case 'checking_upload':
        return checkingUpload;
      case 'checking_resume_data':
        return checkingResumeData;
      case 'queued_download':
        return queuedDownload;
      case 'queued_upload':
        return queuedUpload;
      case 'moving':
        return moving;
      case 'error':
        return error;
      case 'missing_files':
      case 'missingfiles':
        return missingFiles;
      case 'stopped_up':
        return stopped;
      case 'queued_to_seed':
        return queuedToSeed;
      case 'stoppedup':
        return stoppedUP;
      case 'stoppeddl':
        return stoppedDL;
      case 'pausedup':
        return pausedUpload;
      case 'pauseddl':
        return pausedDownload;
      case 'forcedup':
        return forcedUpload;
    }
    return state;
  }
}
