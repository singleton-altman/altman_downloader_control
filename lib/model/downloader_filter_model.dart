/// 通用的下载器筛选条件模型
/// 支持所有下载器类型（qBittorrent、Transmission 等）
class DownloaderFilterModel {
  /// 搜索关键词
  final String searchKeyword;

  /// 选中的状态列表
  final List<String> selectedStatuses;

  /// 选中的分类列表
  final List<String> selectedCategories;

  /// 选中的标签列表
  final List<String> selectedTags;

  /// 选中的跟踪器列表
  final List<String> selectedTrackers;

  DownloaderFilterModel({
    this.searchKeyword = '',
    this.selectedStatuses = const [],
    this.selectedCategories = const [],
    this.selectedTags = const [],
    this.selectedTrackers = const [],
  });

  /// 复制并更新
  DownloaderFilterModel copyWith({
    String? searchKeyword,
    List<String>? selectedStatuses,
    List<String>? selectedCategories,
    List<String>? selectedTags,
    List<String>? selectedTrackers,
  }) {
    return DownloaderFilterModel(
      searchKeyword: searchKeyword ?? this.searchKeyword,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedTrackers: selectedTrackers ?? this.selectedTrackers,
    );
  }

  /// 是否有任何筛选条件
  bool get hasFilters {
    return searchKeyword.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        selectedCategories.isNotEmpty ||
        selectedTags.isNotEmpty ||
        selectedTrackers.isNotEmpty;
  }

  /// 是否为空（无筛选）
  bool get isEmpty => !hasFilters;
}

/// 通用的状态筛选选项
class DownloaderFilterStatus {
  final String value;
  final String label;

  const DownloaderFilterStatus({
    required this.value,
    required this.label,
  });

  static const List<DownloaderFilterStatus> allStatuses = [
    DownloaderFilterStatus(value: 'all', label: '全部'),
    DownloaderFilterStatus(value: 'downloading', label: '下载中'),
    DownloaderFilterStatus(value: 'seeding', label: '做种中'),
    DownloaderFilterStatus(value: 'completed', label: '已完成'),
    DownloaderFilterStatus(value: 'resumed', label: '已恢复'),
    DownloaderFilterStatus(value: 'running', label: '运行中'),
    DownloaderFilterStatus(value: 'stopped', label: '已停止'),
    DownloaderFilterStatus(value: 'paused', label: '已暂停'),
    DownloaderFilterStatus(value: 'active', label: '活跃'),
    DownloaderFilterStatus(value: 'inactive', label: '非活跃'),
    DownloaderFilterStatus(value: 'stalled', label: '停滞'),
    DownloaderFilterStatus(value: 'stalled_uploading', label: '上传停滞'),
    DownloaderFilterStatus(value: 'stalled_download', label: '下载停滞'),
    DownloaderFilterStatus(value: 'checking', label: '检查中'),
    DownloaderFilterStatus(value: 'moving', label: '移动中'),
    DownloaderFilterStatus(value: 'errored', label: '错误'),
  ];
}

