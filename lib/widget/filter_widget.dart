import 'dart:async';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/string_utils.dart';

/// 通用的下载器筛选组件
/// 支持所有下载器类型（qBittorrent、Transmission 等）
class DownloaderFilterWidget extends StatefulWidget {
  const DownloaderFilterWidget({
    super.key,
    required this.controller,
    this.embeddedInSheet = false,
  });

  final DownloaderControllerProtocol controller;
  final bool embeddedInSheet;

  @override
  State<DownloaderFilterWidget> createState() => _DownloaderFilterWidgetState();
}

/// qBittorrent 筛选组件（向后兼容）
/// 内部使用通用的 DownloaderFilterWidget
class QBFilterWidget extends StatelessWidget {
  const QBFilterWidget({
    super.key,
    required this.controller,
    this.embeddedInSheet = false,
  });

  final QBController controller;
  final bool embeddedInSheet;

  @override
  Widget build(BuildContext context) {
    return DownloaderFilterWidget(
      controller: controller,
      embeddedInSheet: embeddedInSheet,
    );
  }
}

/// 通用筛选组件的状态类
class _DownloaderFilterWidgetState extends State<DownloaderFilterWidget> {
  // 如果是 QBController，使用其筛选功能；否则使用通用筛选
  bool get _isQBController => widget.controller is QBController;
  QBController? get _qbController => widget.controller is QBController
      ? widget.controller as QBController
      : null;

  @override
  Widget build(BuildContext context) {
    // 如果是 QBController，使用原有的筛选组件实现
    if (_isQBController && _qbController != null) {
      return _QBFilterWidgetInternal(
        controller: _qbController!,
        embeddedInSheet: widget.embeddedInSheet,
      );
    }

    // 其他下载器类型，使用通用筛选组件
    return _GenericFilterWidgetInternal(controller: widget.controller);
  }
}

/// 通用筛选组件的内部实现（支持所有下载器类型）
class _GenericFilterWidgetInternal extends StatefulWidget {
  const _GenericFilterWidgetInternal({required this.controller});

  final DownloaderControllerProtocol controller;

  @override
  State<_GenericFilterWidgetInternal> createState() =>
      _GenericFilterWidgetInternalState();
}

class _GenericFilterWidgetInternalState
    extends State<_GenericFilterWidgetInternal> {
  // 筛选选项
  final selectedStatuses = RxSet<String>();
  final selectedCategories = RxSet<String>();
  final selectedTags = RxSet<String>();
  final selectedTrackers = RxSet<String>();

  // 可用选项（从 torrentsUniversal 中提取）
  final availableStatuses = <String>[].obs;
  final availableCategories = <String>[].obs;
  final availableTags = <String>[].obs;
  final availableTrackers = <String>[].obs;

  @override
  void initState() {
    super.initState();
    _loadAvailableOptions();

    // 监听种子列表变化，更新可用选项
    ever(widget.controller.torrentsUniversal.obs, (_) {
      _loadAvailableOptions();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 提取 tracker 的主域名
  String _extractMainDomain(String tracker) {
    try {
      String url = tracker.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        url = url.substring(url.indexOf('://') + 3);
      }
      final pathIndex = url.indexOf('/');
      if (pathIndex != -1) {
        url = url.substring(0, pathIndex);
      }
      final portIndex = url.indexOf(':');
      if (portIndex != -1) {
        url = url.substring(0, portIndex);
      }
      final parts = url.split('.');
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
      } else if (parts.length == 1) {
        return parts[0];
      }
      return url;
    } catch (e) {
      return tracker;
    }
  }

  void _loadAvailableOptions() {
    final statuses = <String>{};
    final categories = <String>{};
    final tags = <String>{};
    final trackerDomains = <String>{};

    for (var torrent in widget.controller.torrentsUniversal) {
      if (torrent.state.isNotEmpty) {
        statuses.add(torrent.state);
      }
      if (torrent.category.isNotEmpty) {
        categories.add(torrent.category);
      }
      tags.addAll(torrent.tags);
      if (torrent.tracker.isNotEmpty) {
        final mainDomain = _extractMainDomain(torrent.tracker);
        trackerDomains.add(mainDomain);
      }
    }

    availableStatuses.value = statuses.toList()..sort();
    availableCategories.value = categories.toList()..sort();
    availableTags.value = tags.toList()..sort();
    availableTrackers.value = trackerDomains.toList()..sort();
  }

  void _toggleSelection(RxSet<String> selectedSet, String value) {
    if (selectedSet.contains(value)) {
      selectedSet.remove(value);
    } else {
      selectedSet.add(value);
    }
    selectedSet.refresh();
  }

  Widget _buildFilterSection({
    required String title,
    required RxList<String> options,
    required RxSet<String> selectedSet,
  }) {
    return Obx(() {
      if (options.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                final selected = selectedSet.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (_) => _toggleSelection(selectedSet, option),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(
              title: '状态',
              options: availableStatuses,
              selectedSet: selectedStatuses,
            ),
            _buildFilterSection(
              title: '分类',
              options: availableCategories,
              selectedSet: selectedCategories,
            ),
            _buildFilterSection(
              title: '标签',
              options: availableTags,
              selectedSet: selectedTags,
            ),
            _buildFilterSection(
              title: 'Tracker',
              options: availableTrackers,
              selectedSet: selectedTrackers,
            ),
          ],
        ),
      ),
    );
  }
}

/// qBittorrent 筛选组件的内部实现（保留原有逻辑）
class _QBFilterWidgetInternal extends StatefulWidget {
  const _QBFilterWidgetInternal({
    required this.controller,
    this.embeddedInSheet = false,
  });

  final QBController controller;
  final bool embeddedInSheet;

  @override
  State<_QBFilterWidgetInternal> createState() =>
      _QBFilterWidgetInternalState();
}

class _QBFilterWidgetInternalState extends State<_QBFilterWidgetInternal> {
  // 筛选选项
  final selectedStatuses = RxSet<String>();
  final selectedCategories = RxSet<String>();
  final selectedTags = RxSet<String>();
  final selectedTrackers = RxSet<String>();

  // 可用选项
  final availableCategories = <String>[].obs;
  final availableTags = <String>[].obs;
  final availableTrackers = <String>[].obs;

  // 防抖定时器（用于关键字搜索）
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // 初始化状态 - 使用 postFrameCallback 延迟初始化，避免在构建期间触发响应式更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialFilter = widget.controller.filter.value;
      selectedStatuses.addAll(initialFilter.selectedStatuses);
      selectedCategories.addAll(initialFilter.selectedCategories);
      selectedTags.addAll(initialFilter.selectedTags);
      selectedTrackers.addAll(initialFilter.selectedTrackers);
      _loadAvailableOptions();
    });

    // 监听筛选变化，更新内部状态（保留选中的选项，即使筛选关闭）
    ever(widget.controller.filter, (QBFilterModel? filter) {
      if (filter == null) return;
      // 同步选中的选项（如果外部清除了，则同步清除）
      if (filter.selectedStatuses.isEmpty) {
        selectedStatuses.clear();
      } else {
        selectedStatuses.clear();
        selectedStatuses.addAll(filter.selectedStatuses);
      }
      if (filter.selectedCategories.isEmpty) {
        selectedCategories.clear();
      } else {
        selectedCategories.clear();
        selectedCategories.addAll(filter.selectedCategories);
      }
      if (filter.selectedTags.isEmpty) {
        selectedTags.clear();
      } else {
        selectedTags.clear();
        selectedTags.addAll(filter.selectedTags);
      }
      if (filter.selectedTrackers.isEmpty) {
        selectedTrackers.clear();
      } else {
        selectedTrackers.clear();
        selectedTrackers.addAll(filter.selectedTrackers);
      }
      _loadAvailableOptions();
    });

    // 初始加载可用选项
    _loadAvailableOptions();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 提取 tracker 的主域名
  /// 例如: https://tracker.example.com:8080/announce -> example.com
  String _extractMainDomain(String tracker) {
    try {
      // 移除协议前缀
      String url = tracker.trim();
      if (url.startsWith('http://') || url.startsWith('https://')) {
        url = url.substring(url.indexOf('://') + 3);
      }

      // 移除路径部分
      final pathIndex = url.indexOf('/');
      if (pathIndex != -1) {
        url = url.substring(0, pathIndex);
      }

      // 移除端口
      final portIndex = url.indexOf(':');
      if (portIndex != -1) {
        url = url.substring(0, portIndex);
      }

      // 提取主域名（最后两个部分）
      final parts = url.split('.');
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
      } else if (parts.length == 1) {
        return parts[0];
      }

      return url;
    } catch (e) {
      // 如果解析失败，返回原始字符串
      return tracker;
    }
  }

  void _loadAvailableOptions() {
    // 从所有种子中提取可用的分类、标签和跟踪器
    final categories = <String>{};
    final tags = <String>{};
    final trackerDomains = <String>{};

    for (var torrent in widget.controller.torrents) {
      if (torrent.category.isNotEmpty) {
        categories.add(torrent.category);
      }
      tags.addAll(torrent.tags);
      if (torrent.tracker.isNotEmpty) {
        final mainDomain = _extractMainDomain(torrent.tracker);
        trackerDomains.add(mainDomain);
      }
    }

    availableCategories.value = categories.toList()..sort();
    availableTags.value = tags.toList()..sort();
    availableTrackers.value = trackerDomains.toList()..sort();
  }

  void _updateFilter({bool immediate = false}) {
    // 取消之前的定时器
    _debounceTimer?.cancel();

    if (immediate) {
      // 立即执行（用于清除按钮等操作）
      _performFilterUpdate();
    } else {
      // 防抖：延迟 300ms 执行，避免频繁筛选
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _performFilterUpdate();
      });
    }
  }

  void _performFilterUpdate() {
    widget.controller.setFilter(
      QBFilterModel(
        searchKeyword: widget.controller.filter.value.searchKeyword,
        selectedStatuses: selectedStatuses.toList(),
        selectedCategories: selectedCategories.toList(),
        selectedTags: selectedTags.toList(),
        selectedTrackers: selectedTrackers.toList(),
      ),
    );
  }

  void _clearFilter() {
    selectedStatuses.clear();
    selectedCategories.clear();
    selectedTags.clear();
    selectedTrackers.clear();
    widget.controller.clearFilter();
  }

  Widget _buildFlatSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<String> options,
    required List<String> labels,
    required RxSet<String> selected,
    required Function(String) onToggle,
    required int Function(String) getCount,
    int Function(String)? getSize,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(width: 6),
            Obx(
              () => selected.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${selected.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Obx(
          () => Column(
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final label = labels.length > index ? labels[index] : option;
              final isSelected = selected.contains(option);
              final count = getCount(option);
              return Container(
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.1),
                    width: isSelected ? 1.25 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onToggle(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 13,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isSelected
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                          ),
                          Text(
                            ' ($count)',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                          const Spacer(),
                          if (getSize != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.15)
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.3)
                                      : Theme.of(context).colorScheme.outline
                                            .withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.storage,
                                    size: 11,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    getSize(option).toHumanReadableFileSize(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          widget.embeddedInSheet ? 0 : 6,
          12,
          12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: widget.embeddedInSheet
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlatSection(
              context: context,
              title: '状态',
              icon: Icons.info_outline,
              options: QBFilterStatus.allStatuses.map((e) => e.value).toList(),
              labels: QBFilterStatus.allStatuses.map((e) => e.label).toList(),
              selected: selectedStatuses,
              onToggle: (value) {
                if (selectedStatuses.contains(value)) {
                  selectedStatuses.remove(value);
                } else {
                  selectedStatuses.add(value);
                }
                _updateFilter(immediate: true);
              },
              getCount: _getStatusCount,
              getSize: _getStatusSize,
            ),
            const SizedBox(height: 10),
            Obx(
              () => _buildFlatSection(
                context: context,
                title: '分类',
                icon: Icons.category,
                options: availableCategories.toList(),
                labels: availableCategories
                    .map((e) => e.isEmpty ? '无分类' : e)
                    .toList(),
                selected: selectedCategories,
                onToggle: (value) {
                  if (selectedCategories.contains(value)) {
                    selectedCategories.remove(value);
                  } else {
                    selectedCategories.add(value);
                  }
                  _updateFilter(immediate: true);
                },
                getCount: _getCategoryCount,
                getSize: _getCategorySize,
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => _buildFlatSection(
                context: context,
                title: '标签',
                icon: Icons.label,
                options: availableTags.toList(),
                labels: availableTags.toList(),
                selected: selectedTags,
                onToggle: (value) {
                  if (selectedTags.contains(value)) {
                    selectedTags.remove(value);
                  } else {
                    selectedTags.add(value);
                  }
                  _updateFilter(immediate: true);
                },
                getCount: _getTagCount,
                getSize: _getTagSize,
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => _buildFlatSection(
                context: context,
                title: 'Tracker',
                icon: Icons.dns,
                options: availableTrackers.toList(),
                labels: availableTrackers.toList(),
                selected: selectedTrackers,
                onToggle: (value) {
                  if (selectedTrackers.contains(value)) {
                    selectedTrackers.remove(value);
                  } else {
                    selectedTrackers.add(value);
                  }
                  _updateFilter(immediate: true);
                },
                getCount: _getTrackerCount,
                getSize: _getTrackerSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 计算指定状态的种子数量
  int _getStatusCount(String status) {
    final torrents = widget.controller.torrents;
    if (status == 'all') {
      return torrents.length;
    }

    return torrents.where((torrent) {
      switch (status.toLowerCase()) {
        case 'downloading':
          return torrent.isDownloading;
        case 'seeding':
          return torrent.isSeeding;
        case 'completed':
          return torrent.isCompleted;
        case 'resumed':
          return torrent.isResumed;
        case 'running':
          return torrent.isDownloading || torrent.isSeeding;
        case 'stopped':
          return torrent.isStopped;
        case 'active':
          return torrent.isActive;
        case 'inactive':
          return torrent.isInactive;
        case 'stalled':
          return torrent.isStalled;
        case 'stalled_uploading':
        case 'stalled uploading':
          return torrent.isStalled && torrent.isSeeding;
        case 'stalled_download':
        case 'stalled download':
          return torrent.isStalled && torrent.isDownloading;
        case 'checking':
          return torrent.isChecking;
        case 'moving':
          return torrent.isMoving;
        case 'errored':
        case 'error':
          return torrent.hasError;
        case 'paused':
          return torrent.isPaused;
        default:
          return false;
      }
    }).length;
  }

  /// 计算指定状态的种子总尺寸
  int _getStatusSize(String status) {
    int totalSize = 0;
    for (var torrent in widget.controller.torrents) {
      bool matchesStatus = false;

      switch (status.toLowerCase()) {
        case 'all':
          matchesStatus = true;
          break;
        case 'downloading':
          matchesStatus = torrent.isDownloading;
          break;
        case 'seeding':
          matchesStatus = torrent.isSeeding;
          break;
        case 'completed':
          matchesStatus = torrent.isCompleted;
          break;
        case 'resumed':
          matchesStatus = torrent.isResumed;
          break;
        case 'running':
          matchesStatus = torrent.isDownloading || torrent.isSeeding;
          break;
        case 'stopped':
          matchesStatus = torrent.isStopped;
          break;
        case 'active':
          matchesStatus = torrent.isActive;
          break;
        case 'inactive':
          matchesStatus = torrent.isInactive;
          break;
        case 'stalled':
          matchesStatus = torrent.isStalled;
          break;
        case 'stalled_uploading':
        case 'stalled uploading':
          matchesStatus = torrent.isStalled && torrent.isSeeding;
          break;
        case 'stalled_download':
        case 'stalled download':
          matchesStatus = torrent.isStalled && torrent.isDownloading;
          break;
        case 'checking':
          matchesStatus = torrent.isChecking;
          break;
        case 'moving':
          matchesStatus = torrent.isMoving;
          break;
        case 'errored':
        case 'error':
          matchesStatus = torrent.hasError;
          break;
        case 'paused':
          matchesStatus = torrent.isPaused;
          break;
        default:
          matchesStatus = false;
      }

      if (matchesStatus) {
        totalSize += torrent.totalSize > 0 ? torrent.totalSize : torrent.size;
      }
    }
    return totalSize;
  }

  /// 计算指定分类的种子数量
  int _getCategoryCount(String category) {
    return widget.controller.torrents
        .where((torrent) => torrent.category == category)
        .length;
  }

  /// 计算指定分类的种子总尺寸
  int _getCategorySize(String category) {
    int totalSize = 0;
    for (var torrent in widget.controller.torrents) {
      if (torrent.category == category) {
        totalSize += torrent.totalSize > 0 ? torrent.totalSize : torrent.size;
      }
    }
    return totalSize;
  }

  /// 计算指定标签的种子数量
  int _getTagCount(String tag) {
    return widget.controller.torrents
        .where((torrent) => torrent.tags.contains(tag))
        .length;
  }

  /// 计算指定标签的种子总尺寸
  int _getTagSize(String tag) {
    int totalSize = 0;
    for (var torrent in widget.controller.torrents) {
      if (torrent.tags.contains(tag)) {
        totalSize += torrent.totalSize > 0 ? torrent.totalSize : torrent.size;
      }
    }
    return totalSize;
  }

  /// 计算指定跟踪器的种子数量
  int _getTrackerCount(String tracker) {
    final trackerLower = tracker.toLowerCase();
    return widget.controller.torrents.where((torrent) {
      if (torrent.tracker.isEmpty) return false;
      final torrentMainDomain = _extractMainDomain(
        torrent.tracker,
      ).toLowerCase();
      return torrentMainDomain == trackerLower;
    }).length;
  }

  /// 计算指定跟踪器的种子总尺寸
  int _getTrackerSize(String tracker) {
    final trackerLower = tracker.toLowerCase();
    int totalSize = 0;
    for (var torrent in widget.controller.torrents) {
      if (torrent.tracker.isEmpty) continue;
      final torrentMainDomain = _extractMainDomain(
        torrent.tracker,
      ).toLowerCase();
      if (torrentMainDomain == trackerLower) {
        totalSize += torrent.totalSize > 0 ? torrent.totalSize : torrent.size;
      }
    }
    return totalSize;
  }
}

Future<void> showQBFilterDraggableSheet(
  BuildContext context,
  QBController qb,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.26,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) {
          final scheme = Theme.of(ctx).colorScheme;
          final bottomInset = MediaQuery.paddingOf(ctx).bottom;
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Material(
              color: scheme.surface,
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '筛选',
                                style: Theme.of(ctx).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              Obx(() {
                                if (!qb.filter.value.hasFilters) {
                                  return const SizedBox.shrink();
                                }
                                return TextButton(
                                  onPressed: qb.clearFilter,
                                  style: TextButton.styleFrom(
                                    foregroundColor: scheme.error,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('清空'),
                                );
                              }),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: '关闭',
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  QBFilterWidget(controller: qb, embeddedInSheet: true),
                  SliverToBoxAdapter(
                    child: SizedBox(height: bottomInset + 8),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
