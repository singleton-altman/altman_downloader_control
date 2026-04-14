import 'dart:convert';

/// qBittorrent 筛选条件模型
class QBFilterModel {
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

  QBFilterModel({
    this.searchKeyword = '',
    this.selectedStatuses = const [],
    this.selectedCategories = const [],
    this.selectedTags = const [],
    this.selectedTrackers = const [],
  });

  /// 复制并更新
  QBFilterModel copyWith({
    String? searchKeyword,
    List<String>? selectedStatuses,
    List<String>? selectedCategories,
    List<String>? selectedTags,
    List<String>? selectedTrackers,
  }) {
    return QBFilterModel(
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

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'searchKeyword': searchKeyword,
      'selectedStatuses': selectedStatuses,
      'selectedCategories': selectedCategories,
      'selectedTags': selectedTags,
      'selectedTrackers': selectedTrackers,
    };
  }

  /// 从 JSON 创建
  factory QBFilterModel.fromJson(Map<String, dynamic> json) {
    return QBFilterModel(
      searchKeyword: json['searchKeyword'] as String? ?? '',
      selectedStatuses: (json['selectedStatuses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      selectedCategories: (json['selectedCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      selectedTags: (json['selectedTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      selectedTrackers: (json['selectedTrackers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

/// qBittorrent 状态筛选选项
class QBFilterStatus {
  final String value;
  final String label;

  const QBFilterStatus({
    required this.value,
    required this.label,
  });

  static const List<QBFilterStatus> allStatuses = [
    QBFilterStatus(value: 'all', label: '全部'),
    QBFilterStatus(value: 'downloading', label: '下载中'),
    QBFilterStatus(value: 'seeding', label: '做种中'),
    QBFilterStatus(value: 'completed', label: '已完成'),
    QBFilterStatus(value: 'resumed', label: '已恢复'),
    QBFilterStatus(value: 'running', label: '运行中'),
    QBFilterStatus(value: 'stopped', label: '已停止'),
    QBFilterStatus(value: 'paused', label: '已暂停'),
    QBFilterStatus(value: 'active', label: '活跃'),
    QBFilterStatus(value: 'inactive', label: '非活跃'),
    QBFilterStatus(value: 'stalled', label: '停滞'),
    QBFilterStatus(value: 'stalled_uploading', label: '上传停滞'),
    QBFilterStatus(value: 'stalled_download', label: '下载停滞'),
    QBFilterStatus(value: 'checking', label: '检查中'),
    QBFilterStatus(value: 'moving', label: '移动中'),
    QBFilterStatus(value: 'errored', label: '错误'),
  ];
}

