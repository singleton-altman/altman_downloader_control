enum TransmissionTorrentSortType {
  name('名称'),
  size('大小'),
  progress('进度'),
  dateAdded('添加时间'),
  speed('速度'),
  seeds('做种数'),
  ratio('分享率');

  final String label;
  const TransmissionTorrentSortType(this.label);

  static List<TransmissionTorrentSortType> get sortTypes => [
        size,
        progress,
        dateAdded,
        speed,
        seeds,
        ratio,
      ];
}
