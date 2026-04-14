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
  const DownloaderFilterWidget({super.key, required this.controller});

  final DownloaderControllerProtocol controller;

  @override
  State<DownloaderFilterWidget> createState() => _DownloaderFilterWidgetState();
}

/// qBittorrent 筛选组件（向后兼容）
/// 内部使用通用的 DownloaderFilterWidget
class QBFilterWidget extends StatelessWidget {
  const QBFilterWidget({super.key, required this.controller});

  final QBController controller;

  @override
  Widget build(BuildContext context) {
    // 使用通用的筛选组件
    return DownloaderFilterWidget(controller: controller);
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
      return _QBFilterWidgetInternal(controller: _qbController!);
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
  const _QBFilterWidgetInternal({required this.controller});

  final QBController controller;

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
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => selected.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selected.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final label = labels.length > index ? labels[index] : option;
              final isSelected = selected.contains(option);
              final count = getCount(option);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onToggle(option),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                width: 2,
                              ),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
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
                                  fontSize: 14,
                                ),
                          ),
                          Text(
                            '($count)',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                          const Spacer(),
                          if (getSize != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.15)
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
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
                                    size: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
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
                                          fontSize: 11,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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

  /// 显示筛选 Sheet
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        controller: widget.controller,
        selectedStatuses: selectedStatuses,
        selectedCategories: selectedCategories,
        selectedTags: selectedTags,
        selectedTrackers: selectedTrackers,
        availableCategories: availableCategories,
        availableTags: availableTags,
        availableTrackers: availableTrackers,
        onStatusToggle: (value) {
          if (selectedStatuses.contains(value)) {
            selectedStatuses.remove(value);
          } else {
            selectedStatuses.add(value);
          }
          _updateFilter();
        },
        onCategoryToggle: (value) {
          if (selectedCategories.contains(value)) {
            selectedCategories.remove(value);
          } else {
            selectedCategories.add(value);
          }
          _updateFilter();
        },
        onTagToggle: (value) {
          if (selectedTags.contains(value)) {
            selectedTags.remove(value);
          } else {
            selectedTags.add(value);
          }
          _updateFilter();
        },
        onTrackerToggle: (value) {
          if (selectedTrackers.contains(value)) {
            selectedTrackers.remove(value);
          } else {
            selectedTrackers.add(value);
          }
          _updateFilter();
        },
        onClear: _clearFilter,
        getStatusCount: _getStatusCount,
        getCategoryCount: _getCategoryCount,
        getTagCount: _getTagCount,
        getTrackerCount: _getTrackerCount,
        getStatusSize: _getStatusSize,
        getCategorySize: _getCategorySize,
        getTagSize: _getTagSize,
        getTrackerSize: _getTrackerSize,
      ),
    );
  }
}

/// 筛选 Sheet 组件
class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.controller,
    required this.selectedStatuses,
    required this.selectedCategories,
    required this.selectedTags,
    required this.selectedTrackers,
    required this.availableCategories,
    required this.availableTags,
    required this.availableTrackers,
    required this.onStatusToggle,
    required this.onCategoryToggle,
    required this.onTagToggle,
    required this.onTrackerToggle,
    required this.onClear,
    required this.getStatusCount,
    required this.getCategoryCount,
    required this.getTagCount,
    required this.getTrackerCount,
    this.getStatusSize,
    this.getCategorySize,
    this.getTagSize,
    this.getTrackerSize,
  });

  final QBController controller;
  final RxSet<String> selectedStatuses;
  final RxSet<String> selectedCategories;
  final RxSet<String> selectedTags;
  final RxSet<String> selectedTrackers;
  final RxList<String> availableCategories;
  final RxList<String> availableTags;
  final RxList<String> availableTrackers;
  final Function(String) onStatusToggle;
  final Function(String) onCategoryToggle;
  final Function(String) onTagToggle;
  final Function(String) onTrackerToggle;
  final VoidCallback onClear;
  final int Function(String) getStatusCount;
  final int Function(String) getCategoryCount;
  final int Function(String) getTagCount;
  final int Function(String) getTrackerCount;
  final int Function(String)? getStatusSize;
  final int Function(String)? getCategorySize;
  final int Function(String)? getTagSize;
  final int Function(String)? getTrackerSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      '筛选条件',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    if (controller.filter.value.hasFilters)
                      TextButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('清除'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '关闭',
                    ),
                  ],
                ),
              ),
              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 状态筛选
                      _buildFilterSection(
                        context,
                        title: '状态',
                        icon: Icons.info_outline,
                        options: QBFilterStatus.allStatuses
                            .map((s) => s.value)
                            .toList(),
                        labels: QBFilterStatus.allStatuses
                            .map((s) => s.label)
                            .toList(),
                        selected: selectedStatuses,
                        onToggle: onStatusToggle,
                        getCount: getStatusCount,
                        getSize: getStatusSize,
                      ),
                      const SizedBox(height: 24),

                      // 分类筛选
                      Obx(
                        () => availableCategories.isEmpty
                            ? const SizedBox.shrink()
                            : _buildFilterSection(
                                context,
                                title: '分类',
                                icon: Icons.category,
                                options: availableCategories,
                                labels: availableCategories,
                                selected: selectedCategories,
                                onToggle: onCategoryToggle,
                                getCount: getCategoryCount,
                                getSize: getCategorySize,
                              ),
                      ),
                      if (availableCategories.isNotEmpty)
                        const SizedBox(height: 24),

                      // 标签筛选
                      Obx(
                        () => availableTags.isEmpty
                            ? const SizedBox.shrink()
                            : _buildFilterSection(
                                context,
                                title: '标签',
                                icon: Icons.label,
                                options: availableTags,
                                labels: availableTags,
                                selected: selectedTags,
                                onToggle: onTagToggle,
                                getCount: getTagCount,
                                getSize: getTagSize,
                              ),
                      ),
                      if (availableTags.isNotEmpty) const SizedBox(height: 24),

                      // 跟踪器筛选
                      Obx(
                        () => availableTrackers.isEmpty
                            ? const SizedBox.shrink()
                            : _buildFilterSection(
                                context,
                                title: '跟踪器',
                                icon: Icons.dns,
                                options: availableTrackers,
                                labels: availableTrackers,
                                selected: selectedTrackers,
                                onToggle: onTrackerToggle,
                                getCount: getTrackerCount,
                                getSize: getTrackerSize,
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> options,
    required List<String> labels,
    required RxSet<String> selected,
    required Function(String) onToggle,
    required int Function(String) getCount,
    int Function(String)? getSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => selected.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selected.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(
          () => Column(
            children: options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final label = labels.length > index ? labels[index] : option;
              final isSelected = selected.contains(option);
              final count = getCount(option);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onToggle(option),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // 选中状态图标
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.3),
                                width: 2,
                              ),
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // 标签文本
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
                                  fontSize: 14,
                                ),
                          ),
                          Text(
                            '($count)',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                          const Spacer(),
                          if (getSize != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.15)
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
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
                                    size: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
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
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
}
