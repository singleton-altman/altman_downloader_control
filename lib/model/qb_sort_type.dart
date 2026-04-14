/// qBittorrent 种子排序类型
enum QBTorrentSortType {
  name('名称'),
  size('大小'),
  progress('进度'),
  status('状态'),
  dateAdded('添加时间'),
  speed('速度'),
  seeds('做种数'),
  ratio('分享率');

  final String label;
  const QBTorrentSortType(this.label);

  static List<QBTorrentSortType> get sortTypes => [
        size,
        progress,
        dateAdded,
        speed,
        seeds,
        ratio,
      ];
}

/// qBittorrent RSS 排序类型
enum QBRssSortType {
  date('日期'),
  title('标题'),
  feed('来源');

  final String label;
  const QBRssSortType(this.label);
}
