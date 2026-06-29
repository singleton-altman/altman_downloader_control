import 'dart:ui';

import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_torrent_file_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_properties_model.dart';
import 'package:altman_downloader_control/model/qb_tracker_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/string_utils.dart';
import '../utils/toast_utils.dart';
import '../utils/torrent_state_localizable.dart';

/// 显示种子详情页面的 Modal Sheet
class QbTorrentDetailSheet extends StatefulWidget {
  final String hash;
  final String name;
  final QBTorrentModel? torrent; // 列表中的种子数据（可选）
  final QBController controller;
  const QbTorrentDetailSheet({
    super.key,
    required this.hash,
    required this.name,
    this.torrent,
    required this.controller,
  });

  @override
  State<QbTorrentDetailSheet> createState() => _QbTorrentDetailSheetState();
}

class _DetailMetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _DetailMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
}

class _QbTorrentDetailSheetState extends State<QbTorrentDetailSheet> {
  late final QBController controller = widget.controller;
  QBTorrentPropertiesModel? _properties;
  List<QBTrackerModel> _trackers = [];
  List<QBTorrentFileModel> _files = [];
  bool _isLoading = true;
  bool _isLoadingTrackers = false;
  bool _isLoadingFiles = false;
  String? _errorMessage;

  int _mainPanel = 0;
  String _detailSegment = 'overview';

  static const _floatingTabBarHeight = 56.0;
  static const _sheetPageHorizontalPadding = 10.0;
  static const _sheetPageShellPadding = EdgeInsets.fromLTRB(8, 12, 8, 12);
  static const _sheetContentHorizontalPadding = 8.0;
  static const _sheetPageRadius = 18.0;

  static const _mainPanelDefs = [
    (icon: CupertinoIcons.square_list, label: '详情'),
    (icon: CupertinoIcons.antenna_radiowaves_left_right, label: 'Tracker'),
    (icon: CupertinoIcons.doc_on_doc, label: '文件'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadTrackers();
    _loadFiles();
  }

  void _selectMainPanel(int index) {
    if (_mainPanel == index) return;
    setState(() => _mainPanel = index);
  }

  void _selectDetailSegment(String segment) {
    if (_detailSegment == segment) return;
    setState(() => _detailSegment = segment);
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final properties = await controller.getTorrentProperties(widget.hash);
      if (mounted) {
        setState(() {
          _properties = properties;
          _isLoading = false;
          if (properties == null) {
            _errorMessage = '获取种子详情失败';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadTrackers() async {
    setState(() {
      _isLoadingTrackers = true;
    });

    try {
      final trackers = await controller.getTorrentTrackers(widget.hash);
      if (mounted) {
        setState(() {
          _trackers = trackers;
          _isLoadingTrackers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTrackers = false;
        });
      }
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final files = await controller.getTorrentFiles(widget.hash);
      if (mounted) {
        setState(() {
          _files = files;
          _isLoadingFiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFiles = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.99,
      builder: (context, scrollController) {
        final bottomSafe = MediaQuery.paddingOf(context).bottom;
        final contentBottomPad = bottomSafe + _floatingTabBarHeight + 24;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  _buildSheetDragHandle(context),
                  Expanded(
                    child: _buildBody(scrollController, contentBottomPad),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: bottomSafe + 12,
                child: _buildFloatingMainTabBar(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController, double bottomPad) {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _sheetPageHorizontalPadding,
              0,
              2,
              8,
            ),
            child: _buildTorrentHeader(context),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '加载详情…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (_errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _sheetPageHorizontalPadding,
              0,
              2,
              8,
            ),
            child: _buildTorrentHeader(context),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 44,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        onPressed: _loadProperties,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_clockwise,
                              size: 18,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(width: 6),
                            Text('重试'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            _sheetPageHorizontalPadding,
            0,
            2,
            4,
          ),
          sliver: SliverToBoxAdapter(child: _buildTorrentHeader(context)),
        ),
        ..._buildPanelSlivers(),
        SliverPadding(padding: EdgeInsets.only(bottom: bottomPad)),
      ],
    );
  }

  List<Widget> _buildPanelSlivers() {
    switch (_mainPanel) {
      case 1:
        return _buildTrackerSlivers();
      case 2:
        return _buildFileSlivers();
      default:
        return _buildDetailSlivers();
    }
  }

  Widget _buildFloatingMainTabBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: isDark ? 0.45 : 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: Container(
            height: _floatingTabBarHeight,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E).withValues(alpha: 0.96)
                  : scheme.surface.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outlineVariant.withValues(
                  alpha: isDark ? 0.55 : 0.45,
                ),
                width: 0.8,
              ),
            ),
            child: Row(
              children: List.generate(_mainPanelDefs.length, (index) {
                final item = _mainPanelDefs[index];
                final selected = _mainPanel == index;
                final fg = selected
                    ? (isDark ? Colors.white : scheme.onPrimary)
                    : scheme.onSurface.withValues(alpha: 0.72);
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: selected ? scheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        borderRadius: BorderRadius.circular(999),
                        onPressed: () => _selectMainPanel(index),
                        child: SizedBox(
                          height: double.infinity,
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.icon, size: 18, color: fg),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 11,
                                      height: 1,
                                      color: fg,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSegmentBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.42 : 0.65,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: CupertinoSlidingSegmentedControl<String>(
          groupValue: _detailSegment,
          thumbColor: scheme.surface,
          backgroundColor: Colors.transparent,
          children: {
            'overview': _segmentLabel(context, '概览'),
            'transfer': _segmentLabel(context, '传输'),
            'meta': _segmentLabel(context, '属性'),
            'time': _segmentLabel(context, '时间'),
          },
          onValueChanged: (value) {
            if (value != null) _selectDetailSegment(value);
          },
        ),
      ),
    );
  }

  Widget _segmentLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  List<Widget> _buildDetailSlivers() {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _sheetPageHorizontalPadding,
          4,
          _sheetPageHorizontalPadding,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: _buildPanelColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDetailSegmentBar(context),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_detailSegment),
                    child: _buildDetailSegmentBody(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildDetailSegmentBody() {
    final props = _properties;
    final torrent = widget.torrent;
    switch (_detailSegment) {
      case 'transfer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMetricSection(
              title: '流量',
              subtitle: '累计与会话',
              items: _transferVolumeMetrics(props, torrent),
            ),
            _buildMetricSection(
              title: '速度',
              subtitle: '实时与限制',
              items: _speedMetrics(props, torrent),
            ),
            _buildMetricSection(
              title: '连接',
              subtitle: '节点与分片',
              items: _connectionMetrics(props, torrent),
            ),
          ],
        );
      case 'meta':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._buildMetaSectionChildren(props, torrent),
            _buildMagnetRow(),
          ],
        );
      case 'time':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildTimeSectionChildren(props, torrent),
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLiveSpeedStrip(context),
            const SizedBox(height: 14),
            _buildSectionHeader('关键指标'),
            const SizedBox(height: 10),
            _buildOverviewMetricWrap(context),
          ],
        );
    }
  }

  List<Widget> _buildTrackerSlivers() {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _sheetPageHorizontalPadding,
          4,
          _sheetPageHorizontalPadding,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: _buildPanelColumn(child: _buildTrackersSection()),
        ),
      ),
    ];
  }

  List<Widget> _buildFileSlivers() {
    final totalSize = _files.fold<int>(0, (sum, file) => sum + file.size);
    final doneSize = _files.fold<int>(
      0,
      (sum, file) => sum + (file.size * file.progress).round(),
    );
    final completeCount = _files.where((file) => file.progress >= 1).length;
    final skippedCount = _files.where((file) => file.priority == 0).length;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          _sheetPageHorizontalPadding,
          4,
          _sheetPageHorizontalPadding,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: _buildPanelColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('文件列表', subtitle: '${_files.length} 个文件'),
                const SizedBox(height: 12),
                if (_isLoadingFiles)
                  _buildPanelPlaceholder(
                    icon: Icons.folder_open_rounded,
                    message: '加载文件列表…',
                    loading: true,
                  )
                else if (_files.isEmpty)
                  _buildPanelPlaceholder(
                    icon: Icons.folder_open_rounded,
                    message: '暂无文件',
                  )
                else ...[
                  _buildFilesSummaryGrid(
                    totalSize: totalSize,
                    doneSize: doneSize,
                    completeCount: completeCount,
                    skippedCount: skippedCount,
                  ),
                  const SizedBox(height: 12),
                  _buildListGroupCard(
                    children: [for (final file in _files) _buildFileItem(file)],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  String _statusText() {
    final torrent = widget.torrent;
    if (torrent != null && torrent.state.isNotEmpty) {
      return QBLocalizable.getStateText(torrent.state);
    }
    return '未知状态';
  }

  double _progressValue() {
    final props = _properties;
    if (props != null) {
      return props.progress.clamp(0.0, 1.0);
    }
    final torrent = widget.torrent;
    if (torrent != null) {
      return torrent.progress.clamp(0.0, 1.0);
    }
    return 0.0;
  }

  String _progressText() {
    final props = _properties;
    if (props != null) {
      return '${props.progressPercent.toStringAsFixed(2)}%';
    }
    final torrent = widget.torrent;
    if (torrent != null) {
      return '${(torrent.progress * 100).toStringAsFixed(2)}%';
    }
    return '0%';
  }

  String _sizeText() {
    final props = _properties;
    if (props != null) {
      return props.totalSize.toHumanReadableFileSize();
    }
    final torrent = widget.torrent;
    if (torrent != null) {
      final totalSize = torrent.totalSize > 0
          ? torrent.totalSize
          : torrent.size;
      return totalSize.toHumanReadableFileSize();
    }
    return '未知';
  }

  String _downloadSpeedText() {
    final props = _properties;
    if (props != null && props.dlSpeed > 0) {
      return '${props.dlSpeed.toHumanReadableFileSize(round: 1)}/s';
    }
    final torrent = widget.torrent;
    if (torrent != null && torrent.dlspeed > 0) {
      return '${torrent.dlspeed.toHumanReadableFileSize(round: 1)}/s';
    }
    return '0 B/s';
  }

  String _uploadSpeedText() {
    final props = _properties;
    if (props != null && props.upSpeed > 0) {
      return '${props.upSpeed.toHumanReadableFileSize(round: 1)}/s';
    }
    final torrent = widget.torrent;
    if (torrent != null && torrent.upspeed > 0) {
      return '${torrent.upspeed.toHumanReadableFileSize(round: 1)}/s';
    }
    return '0 B/s';
  }

  String _ratioText() {
    final props = _properties;
    if (props != null) {
      return props.shareRatio.toStringAsFixed(2);
    }
    final torrent = widget.torrent;
    if (torrent != null) {
      return torrent.ratio.toStringAsFixed(2);
    }
    return '0.00';
  }

  String _amountLeftText() {
    final props = _properties;
    if (props != null) {
      final left = (props.totalSize * (1 - props.progress)).round();
      return left.toHumanReadableFileSize();
    }
    final torrent = widget.torrent;
    if (torrent != null) {
      return torrent.amountLeft.toHumanReadableFileSize();
    }
    return '未知';
  }

  String _etaText() {
    final props = _properties;
    if (props != null) {
      if (props.eta <= 0 || props.eta == 8640000) return '未知';
      return QBTorrentPropertiesModel.formatDuration(props.eta);
    }
    final torrent = widget.torrent;
    if (torrent != null && torrent.eta > 0) {
      return QBTorrentPropertiesModel.formatDuration(torrent.eta);
    }
    return '未知';
  }

  String _limitText(num bytesPerSecond) {
    if (bytesPerSecond < 0) return '无限制';
    if (bytesPerSecond == 0) return '0 B/s';
    return '${bytesPerSecond.toInt().toHumanReadableFileSize(round: 1)}/s';
  }

  String _timeText(int seconds) {
    if (seconds <= 0) return '0秒';
    return QBTorrentPropertiesModel.formatDuration(seconds);
  }

  String _availabilityText(double availability) {
    if (availability < 0) return '未知';
    return availability.toStringAsFixed(3);
  }

  String _yesNo(bool value) => value ? '是' : '否';

  String _addedTimeText() {
    final props = _properties;
    if (props != null && props.additionDate > 0) {
      return QBTorrentPropertiesModel.formatTimestamp(props.additionDate);
    }
    final torrent = widget.torrent;
    if (torrent != null && torrent.addedOn > 0) {
      return QBTorrentPropertiesModel.formatTimestamp(torrent.addedOn);
    }
    return '未知';
  }

  Color _statusAccentColor(ColorScheme scheme) {
    final state = (widget.torrent?.state ?? '').toLowerCase();
    if (state.contains('error') || state.contains('missingfiles')) {
      return scheme.error;
    }
    if (state.contains('stalled')) {
      return scheme.secondary;
    }
    if (state.contains('download') || state == 'downloading') {
      return scheme.primary;
    }
    if (state.contains('seed') ||
        state.contains('upload') ||
        state == 'uploading' ||
        state == 'forcedup' ||
        state == 'queuedup') {
      return scheme.tertiary;
    }
    if (state.contains('pause') || state.contains('stop')) {
      return scheme.onSurfaceVariant;
    }
    return scheme.primary;
  }

  BoxDecoration _sheetPageDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? scheme.surfaceContainerLow.withValues(alpha: 0.72)
          : scheme.surface,
      borderRadius: BorderRadius.circular(_sheetPageRadius),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.32),
        width: 0.6,
      ),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  Widget _buildSheetPageShell({required Widget child}) {
    return DecoratedBox(
      decoration: _sheetPageDecoration(context),
      child: Padding(padding: _sheetPageShellPadding, child: child),
    );
  }

  Widget _buildPanelColumn({required Widget child}) {
    return _buildSheetPageShell(child: child);
  }

  String _headerTitleText(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return fullName;
    final first = trimmed.split('.').first.trim();
    return first.isNotEmpty ? first : trimmed;
  }

  Widget _buildTorrentHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _statusAccentColor(scheme);
    final fullTitle = _properties?.name.isNotEmpty == true
        ? _properties!.name
        : widget.name;
    final title = _headerTitleText(fullTitle);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtle = scheme.onSurfaceVariant.withValues(alpha: 0.88);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            _buildSheetCloseButton(context),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _statusText(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: subtle,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ),
            Text(
              _progressText(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: subtle,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: _progressValue(),
            minHeight: 2,
            backgroundColor: scheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.35 : 0.55,
            ),
            valueColor: AlwaysStoppedAnimation<Color>(
              accent.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPanelPlaceholder({
    required IconData icon,
    required String message,
    bool loading = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            if (loading)
              CircularProgressIndicator(color: scheme.primary, strokeWidth: 2.5)
            else
              Icon(
                icon,
                size: 40,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListGroupCard({required List<Widget> children}) {
    final visible = children.where((child) {
      if (child is SizedBox &&
          child.child == null &&
          child.width == null &&
          child.height == null) {
        return false;
      }
      return true;
    }).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: _insetCardDecoration(context, radius: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 44,
                endIndent: _sheetContentHorizontalPadding,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
            visible[i],
          ],
        ],
      ),
    );
  }

  BoxDecoration _insetCardDecoration(
    BuildContext context, {
    Color? borderColor,
    double radius = 16,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.32 : 0.52,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color:
            borderColor ??
            scheme.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.38),
      ),
    );
  }

  Widget _buildSheetDragHandle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildSheetCloseButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CupertinoButton(
      padding: const EdgeInsets.all(10),
      minimumSize: const Size(44, 44),
      onPressed: () => Navigator.of(context).pop(),
      child: Icon(
        CupertinoIcons.xmark,
        size: 17,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _cupertinoCopyButton(VoidCallback onPressed) {
    final scheme = Theme.of(context).colorScheme;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Icon(
        CupertinoIcons.doc_on_doc,
        size: 17,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  TextStyle? _dataLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.35,
    );
  }

  TextStyle _dataValueStyle(
    BuildContext context, {
    bool monospace = false,
    bool emphasize = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      color: scheme.onSurface,
      fontSize: emphasize ? 15 : 14,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
      height: 1.35,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontFamily: monospace ? 'monospace' : null,
    );
  }

  Widget _buildBlockTitle(String title, {String? subtitle}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return _buildBlockTitle(title, subtitle: subtitle);
  }

  Widget _buildDataTable(List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: _insetCardDecoration(context, radius: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 14,
                endIndent: 14,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value, {
    bool monospace = false,
    bool emphasizeValue = false,
    bool alignValueEnd = false,
    int maxLines = 1,
    VoidCallback? onCopy,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: _dataLabelStyle(context)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              maxLines: maxLines,
              textAlign: alignValueEnd ? TextAlign.end : TextAlign.start,
              style: _dataValueStyle(
                context,
                monospace: monospace,
                emphasize: emphasizeValue,
              ),
            ),
          ),
          if (onCopy != null) _cupertinoCopyButton(onCopy),
        ],
      ),
    );
  }

  Widget _buildDataBlock({required String title, required List<Widget> rows}) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBlockTitle(title),
          const SizedBox(height: 8),
          _buildDataTable(rows),
        ],
      ),
    );
  }

  Widget _buildMetricsBlock({
    required String title,
    required List<_DetailMetricItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBlockTitle(title),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 3 : 2;
              const gap = 6.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: width,
                      child: _buildMetricCard(context, item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, _DetailMetricItem item) {
    final scheme = Theme.of(context).colorScheme;
    final color = item.color ?? scheme.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: _insetCardDecoration(context, radius: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _dataValueStyle(
                    context,
                    emphasize: true,
                  ).copyWith(fontSize: 13.5, height: 1.05),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetaSectionChildren(
    QBTorrentPropertiesModel? props,
    QBTorrentModel? torrent,
  ) {
    return [
      _buildGroupedSection(
        title: '任务',
        rows: [
          _buildGroupedRow('名称', props?.name ?? widget.name),
          _buildGroupedRow(
            '哈希',
            props?.hash ?? widget.hash,
            monospace: true,
            onCopy: () {
              final hash = props?.hash ?? widget.hash;
              Clipboard.setData(ClipboardData(text: hash));
              showToast(message: '已复制哈希值');
            },
          ),
          if (props != null && props.infohashV1.isNotEmpty)
            _buildGroupedRow('Infohash V1', props.infohashV1, monospace: true),
          if (props != null && props.infohashV2.isNotEmpty)
            _buildGroupedRow('Infohash V2', props.infohashV2, monospace: true),
          if (props != null) _buildGroupedRow('私有', _yesNo(props.isPrivate)),
          if (props != null) _buildGroupedRow('元数据', _yesNo(props.hasMetadata)),
          if (torrent != null && torrent.category.isNotEmpty)
            _buildGroupedRow('分类', torrent.category),
          if (torrent != null && torrent.tags.isNotEmpty)
            _buildGroupedRow('标签', torrent.tags.join(' · ')),
          if (props != null && props.createdBy.isNotEmpty)
            _buildGroupedRow('创建者', props.createdBy),
          if (props != null && props.comment.isNotEmpty)
            _buildGroupedRow('注释', props.comment),
        ],
      ),
      _buildGroupedSection(
        title: '路径',
        rows: [
          if (props != null) _buildGroupedRow('保存路径', props.savePath),
          if (props != null && props.downloadPath.isNotEmpty)
            _buildGroupedRow('下载路径', props.downloadPath),
          if (torrent != null && torrent.contentPath.isNotEmpty)
            _buildGroupedRow('内容路径', torrent.contentPath),
          if (torrent != null && torrent.rootPath.isNotEmpty)
            _buildGroupedRow('根路径', torrent.rootPath),
          if (torrent != null && torrent.tracker.isNotEmpty)
            _buildGroupedRow('Tracker', torrent.tracker),
          if (props == null && torrent != null && torrent.savePath.isNotEmpty)
            _buildGroupedRow('保存路径', torrent.savePath),
        ],
      ),
    ];
  }

  List<Widget> _buildTimeSectionChildren(
    QBTorrentPropertiesModel? props,
    QBTorrentModel? torrent,
  ) {
    if (props != null) {
      return [
        _buildTimelineSection([
          (
            '添加时间',
            QBTorrentPropertiesModel.formatTimestamp(props.additionDate),
          ),
          if (props.completionDate > 0)
            (
              '完成时间',
              QBTorrentPropertiesModel.formatTimestamp(props.completionDate),
            ),
          if (props.creationDate > 0)
            (
              '创建时间',
              QBTorrentPropertiesModel.formatTimestamp(props.creationDate),
            ),
          ('最后见到', QBTorrentPropertiesModel.formatTimestamp(props.lastSeen)),
          ('已用时间', _timeText(props.timeElapsed)),
          ('做种时间', _timeText(props.seedingTime)),
          (
            'ETA',
            props.eta == 8640000
                ? '未知'
                : QBTorrentPropertiesModel.formatDuration(props.eta),
          ),
          if (props.reannounce > 0)
            ('重新声明', QBTorrentPropertiesModel.formatDuration(props.reannounce)),
        ]),
      ];
    }
    if (torrent == null) return [];
    return [
      _buildTimelineSection([
        if (torrent.addedOn > 0)
          ('添加时间', QBTorrentPropertiesModel.formatTimestamp(torrent.addedOn)),
        if (torrent.completionOn > 0)
          (
            '完成时间',
            QBTorrentPropertiesModel.formatTimestamp(torrent.completionOn),
          ),
        if (torrent.lastActivity > 0)
          (
            '最后活动',
            QBTorrentPropertiesModel.formatTimestamp(torrent.lastActivity),
          ),
        if (torrent.seenComplete > 0)
          (
            '最后完整',
            QBTorrentPropertiesModel.formatTimestamp(torrent.seenComplete),
          ),
        if (torrent.timeActive > 0)
          ('活动时间', _timeText(torrent.timeActive.toInt())),
        if (torrent.seedingTime > 0) ('做种时间', _timeText(torrent.seedingTime)),
      ]),
    ];
  }

  List<_DetailMetricItem> _transferVolumeMetrics(
    QBTorrentPropertiesModel? props,
    QBTorrentModel? torrent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (props != null) {
      return [
        _DetailMetricItem(
          label: '已下载',
          value: props.totalDownloaded.toHumanReadableFileSize(),
          icon: Icons.download_rounded,
        ),
        _DetailMetricItem(
          label: '已上传',
          value: props.totalUploaded.toHumanReadableFileSize(),
          icon: Icons.upload_rounded,
          color: scheme.secondary,
        ),
        _DetailMetricItem(
          label: '浪费流量',
          value: props.totalWasted.toHumanReadableFileSize(),
          icon: Icons.warning_amber_rounded,
          color: scheme.error,
        ),
        _DetailMetricItem(
          label: '会话下载',
          value: props.totalDownloadedSession.toHumanReadableFileSize(),
          icon: Icons.download_for_offline_outlined,
        ),
        _DetailMetricItem(
          label: '会话上传',
          value: props.totalUploadedSession.toHumanReadableFileSize(),
          icon: Icons.publish_rounded,
          color: scheme.secondary,
        ),
      ];
    }
    if (torrent == null) return [];
    return [
      _DetailMetricItem(
        label: '已下载',
        value: torrent.downloaded.toHumanReadableFileSize(),
        icon: Icons.download_rounded,
      ),
      _DetailMetricItem(
        label: '已上传',
        value: torrent.uploaded.toHumanReadableFileSize(),
        icon: Icons.upload_rounded,
        color: scheme.secondary,
      ),
      _DetailMetricItem(
        label: '会话下载',
        value: torrent.downloadedSession.toHumanReadableFileSize(),
        icon: Icons.download_for_offline_outlined,
      ),
      _DetailMetricItem(
        label: '会话上传',
        value: torrent.uploadedSession.toHumanReadableFileSize(),
        icon: Icons.publish_rounded,
        color: scheme.secondary,
      ),
    ];
  }

  List<_DetailMetricItem> _speedMetrics(
    QBTorrentPropertiesModel? props,
    QBTorrentModel? torrent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return [
      _DetailMetricItem(
        label: '当前下载',
        value: _downloadSpeedText(),
        icon: Icons.south_rounded,
        color: scheme.primary,
      ),
      _DetailMetricItem(
        label: '当前上传',
        value: _uploadSpeedText(),
        icon: Icons.north_rounded,
        color: scheme.secondary,
      ),
      if (props != null)
        _DetailMetricItem(
          label: '平均下载',
          value: props.dlSpeedAvg > 0
              ? '${props.dlSpeedAvg.toHumanReadableFileSize(round: 1)}/s'
              : '0 B/s',
          icon: Icons.trending_down_rounded,
        ),
      if (props != null)
        _DetailMetricItem(
          label: '平均上传',
          value: props.upSpeedAvg > 0
              ? '${props.upSpeedAvg.toInt().toHumanReadableFileSize(round: 1)}/s'
              : '0 B/s',
          icon: Icons.trending_up_rounded,
          color: scheme.secondary,
        ),
      _DetailMetricItem(
        label: '下载限制',
        value: _limitText(props?.dlLimit ?? torrent?.dlLimit ?? -1),
        icon: Icons.speed_rounded,
      ),
      _DetailMetricItem(
        label: '上传限制',
        value: _limitText(props?.upLimit ?? torrent?.upLimit ?? -1),
        icon: Icons.speed_rounded,
        color: scheme.secondary,
      ),
    ];
  }

  List<_DetailMetricItem> _connectionMetrics(
    QBTorrentPropertiesModel? props,
    QBTorrentModel? torrent,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (props != null) {
      return [
        _DetailMetricItem(
          label: '连接',
          value: '${props.nbConnections}/${props.nbConnectionsLimit}',
          icon: Icons.link_rounded,
        ),
        _DetailMetricItem(
          label: '做种',
          value: '${props.seeds}/${props.seedsTotal}',
          icon: Icons.cloud_upload_rounded,
          color: scheme.tertiary,
        ),
        _DetailMetricItem(
          label: '下载',
          value: '${props.peers}/${props.peersTotal}',
          icon: Icons.cloud_download_rounded,
        ),
        _DetailMetricItem(
          label: '分享率',
          value: props.shareRatio.toStringAsFixed(2),
          icon: Icons.swap_horiz_rounded,
          color: scheme.tertiary,
        ),
        _DetailMetricItem(
          label: '流行度',
          value: props.popularity.toStringAsFixed(3),
          icon: Icons.local_fire_department_outlined,
        ),
        _DetailMetricItem(
          label: '分片',
          value: '${props.piecesHave}/${props.piecesNum}',
          icon: Icons.grid_view_rounded,
        ),
        _DetailMetricItem(
          label: '分片大小',
          value: props.pieceSize.toHumanReadableFileSize(),
          icon: Icons.dashboard_customize_outlined,
        ),
        if (torrent != null && torrent.hasAvailabilityField)
          _DetailMetricItem(
            label: '可用性',
            value: _availabilityText(torrent.availability),
            icon: Icons.cloud_done_outlined,
            color: scheme.secondary,
          ),
      ];
    }
    if (torrent == null) return [];
    return [
      _DetailMetricItem(
        label: '做种',
        value:
            '${torrent.numComplete}/${torrent.numComplete + torrent.numIncomplete}',
        icon: Icons.cloud_upload_rounded,
        color: scheme.tertiary,
      ),
      _DetailMetricItem(
        label: '下载',
        value:
            '${torrent.numIncomplete}/${torrent.numComplete + torrent.numIncomplete}',
        icon: Icons.cloud_download_rounded,
      ),
      _DetailMetricItem(
        label: '分享率',
        value: torrent.ratio.toStringAsFixed(2),
        icon: Icons.swap_horiz_rounded,
        color: scheme.tertiary,
      ),
      if (torrent.popularity > 0)
        _DetailMetricItem(
          label: '流行度',
          value: torrent.popularity.toStringAsFixed(3),
          icon: Icons.local_fire_department_outlined,
        ),
      if (torrent.hasAvailabilityField)
        _DetailMetricItem(
          label: '可用性',
          value: _availabilityText(torrent.availability),
          icon: Icons.cloud_done_outlined,
          color: scheme.secondary,
        ),
    ];
  }

  Widget _buildMetaChip({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveSpeedStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _buildMetricTileWrap(
      items: [
        _DetailMetricItem(
          label: '下载',
          value: _downloadSpeedText(),
          icon: Icons.arrow_downward_rounded,
          color: scheme.primary,
        ),
        _DetailMetricItem(
          label: '上传',
          value: _uploadSpeedText(),
          icon: Icons.arrow_upward_rounded,
          color: scheme.secondary,
        ),
      ],
    );
  }

  Widget _buildOverviewMetricWrap(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tiles = [
      _DetailMetricItem(
        label: '总大小',
        value: _sizeText(),
        icon: Icons.storage_outlined,
      ),
      _DetailMetricItem(
        label: '剩余',
        value: _amountLeftText(),
        icon: Icons.hourglass_empty_rounded,
      ),
      _DetailMetricItem(
        label: 'ETA',
        value: _etaText(),
        icon: Icons.schedule_outlined,
        color: scheme.primary,
      ),
      _DetailMetricItem(
        label: '分享率',
        value: _ratioText(),
        icon: Icons.swap_horiz_rounded,
        color: scheme.tertiary,
      ),
    ];
    return _buildMetricTileWrap(items: tiles);
  }

  Widget _buildMetricSection({
    required String title,
    String? subtitle,
    required List<_DetailMetricItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title, subtitle: subtitle),
          const SizedBox(height: 10),
          _buildMetricTileWrap(items: items),
        ],
      ),
    );
  }

  Widget _buildMetricTileWrap({required List<_DetailMetricItem> items}) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _buildDetailMetricTile(
                  context,
                  item: item,
                  scheme: scheme,
                  isDark: isDark,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailMetricTile(
    BuildContext context, {
    required _DetailMetricItem item,
    required ColorScheme scheme,
    required bool isDark,
  }) {
    final color = item.color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(
          alpha: isDark ? 0.28 : 0.82,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.2 : 0.14),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedSection({
    required String title,
    required List<Widget> rows,
  }) {
    final visible = rows.where((row) {
      if (row is SizedBox &&
          row.child == null &&
          row.width == null &&
          row.height == null) {
        return false;
      }
      return true;
    }).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 10),
          _buildListGroupCard(children: visible),
        ],
      ),
    );
  }

  IconData _groupedRowIcon(String label) {
    switch (label) {
      case '名称':
        return CupertinoIcons.doc_text;
      case '哈希':
      case 'Infohash V1':
      case 'Infohash V2':
        return CupertinoIcons.number;
      case '私有':
      case '元数据':
        return CupertinoIcons.lock_shield;
      case '分类':
        return CupertinoIcons.folder;
      case '标签':
        return CupertinoIcons.tag;
      case '创建者':
        return CupertinoIcons.person;
      case '注释':
        return CupertinoIcons.text_quote;
      case '保存路径':
      case '下载路径':
      case '内容路径':
      case '根路径':
        return CupertinoIcons.folder;
      case 'Tracker':
        return CupertinoIcons.antenna_radiowaves_left_right;
      case '添加时间':
        return CupertinoIcons.plus_circle;
      case '完成时间':
        return CupertinoIcons.checkmark_circle;
      case '创建时间':
        return CupertinoIcons.calendar;
      case '最后见到':
      case '最后活动':
        return CupertinoIcons.eye;
      case '最后完整':
        return CupertinoIcons.checkmark_seal;
      case '已用时间':
      case '活动时间':
        return CupertinoIcons.time;
      case '做种时间':
        return CupertinoIcons.arrow_up_circle;
      case 'ETA':
        return CupertinoIcons.hourglass;
      case '重新声明':
        return CupertinoIcons.arrow_clockwise;
      default:
        return CupertinoIcons.info_circle;
    }
  }

  Color _groupedRowIconColor(String label, ColorScheme scheme) {
    switch (label) {
      case '完成时间':
      case '最后完整':
        return scheme.tertiary;
      case 'ETA':
        return scheme.primary;
      case '做种时间':
        return scheme.secondary;
      case '私有':
      case '元数据':
        return scheme.onSurfaceVariant;
      default:
        return scheme.primary;
    }
  }

  Widget _buildGroupedRowIconBox(String label) {
    final scheme = Theme.of(context).colorScheme;
    final color = _groupedRowIconColor(label, scheme);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_groupedRowIcon(label), size: 15, color: color),
    );
  }

  Widget _buildBoolPill(String value) {
    final scheme = Theme.of(context).colorScheme;
    final isYes = value == '是';
    final color = isYes ? scheme.tertiary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildGroupedValue(String value, {bool monospace = false}) {
    if (value == '是' || value == '否') {
      return _buildBoolPill(value);
    }
    return Text(
      value,
      style: _dataValueStyle(
        context,
        monospace: monospace,
      ).copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.45),
    );
  }

  Widget _buildGroupedRowContent({
    required String label,
    required String value,
    bool monospace = false,
    VoidCallback? onCopy,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupedRowIconBox(label),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              _buildGroupedValue(value, monospace: monospace),
            ],
          ),
        ),
        if (onCopy != null) _cupertinoCopyButton(onCopy),
      ],
    );
  }

  Widget _buildTimelineSection(List<(String label, String value)> entries) {
    final visible = entries
        .where((entry) => entry.$2.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('时间线'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: _insetCardDecoration(context, radius: 14),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 44,
                      endIndent: _sheetContentHorizontalPadding,
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  _buildTimelineRow(
                    visible[i].$1,
                    visible[i].$2,
                    isLast: i == visible.length - 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String label, String value, {required bool isLast}) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _groupedRowIconColor(label, scheme);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _sheetContentHorizontalPadding,
        10,
        _sheetContentHorizontalPadding,
        10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: _dataValueStyle(context).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedRow(
    String label,
    String value, {
    bool monospace = false,
    VoidCallback? onCopy,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _sheetContentHorizontalPadding,
        10,
        _sheetContentHorizontalPadding,
        10,
      ),
      child: _buildGroupedRowContent(
        label: label,
        value: value,
        monospace: monospace,
        onCopy: onCopy,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String text, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.7),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  /// 获取或生成 Magnet 链接
  String _getMagnetUri() {
    // 优先使用已有的 magnetUri（从 torrent 模型中）
    final torrent = widget.torrent;
    final existingMagnet = torrent?.magnetUri ?? '';

    if (existingMagnet.isNotEmpty) {
      return existingMagnet;
    }

    // 如果没有，则根据 hash 和 name 拼接
    final props = _properties;
    final hash = props?.hash ?? widget.hash;
    final name = props?.name ?? torrent?.name ?? widget.name;

    if (hash.isEmpty) {
      return '';
    }

    // URL 编码名称
    final encodedName = Uri.encodeComponent(name);

    // 拼接 magnet 链接
    return 'magnet:?xt=urn:btih:$hash&dn=$encodedName';
  }

  Widget _buildMagnetRow() {
    final magnetUri = _getMagnetUri();

    if (magnetUri.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: magnetUri));
            showToast(message: '已复制 Magnet 链接');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.link,
                size: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '复制 Magnet 链接',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tracker 列表', subtitle: '${_trackers.length} 个来源'),
        const SizedBox(height: 14),
        if (_isLoadingTrackers)
          _buildPanelPlaceholder(
            icon: Icons.radar_rounded,
            message: '加载 Tracker…',
            loading: true,
          )
        else if (_trackers.isEmpty)
          _buildPanelPlaceholder(
            icon: Icons.radar_rounded,
            message: '暂无 Tracker',
          )
        else ...[
          _buildTrackerSummaryGrid(context),
          const SizedBox(height: 12),
          _buildListGroupCard(
            children: [
              for (var i = 0; i < _trackers.length; i++)
                _buildTrackerItem(_trackers[i], i),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onPressed: () => _showAddTrackerDialog(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.add,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '添加 Tracker',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackerSummaryGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final working = _trackers.where((t) => t.status == 2).length;
    final inactive = _trackers
        .where((t) => t.status == 0 || t.status == 1)
        .length;
    final failed = _trackers
        .where((t) => t.status == 3 || t.status == 4)
        .length;
    final special = _trackers.where((t) => t.isSpecialTracker).length;
    return _buildMetricTileWrap(
      items: [
        _DetailMetricItem(
          label: '工作',
          value: '$working',
          icon: Icons.check_circle_outline_rounded,
          color: scheme.tertiary,
        ),
        _DetailMetricItem(
          label: '未联系/禁用',
          value: '$inactive',
          icon: Icons.pause_circle_outline_rounded,
          color: scheme.secondary,
        ),
        _DetailMetricItem(
          label: '失败',
          value: '$failed',
          icon: Icons.error_outline_rounded,
          color: scheme.error,
        ),
        _DetailMetricItem(
          label: '特殊来源',
          value: '$special',
          icon: Icons.hub_outlined,
          color: scheme.primary,
        ),
      ],
    );
  }

  Widget _buildTrackerItem(QBTrackerModel tracker, int index) {
    final statusColor = _trackerStatusColor(context, tracker);
    final metaChips = <Widget>[
      if (tracker.tier >= 0)
        _buildTrackerMetaChip(
          context,
          icon: Icons.low_priority_rounded,
          text: '优先级 ${tracker.tier}',
        ),
      if (!tracker.isSpecialTracker &&
          (tracker.numSeeds >= 0 || tracker.numLeeches >= 0))
        _buildTrackerMetaChip(
          context,
          icon: Icons.people_alt_outlined,
          text: '种/下 ${tracker.formattedPeers}',
          color: statusColor,
        ),
      if (!tracker.isSpecialTracker && tracker.numPeers >= 0)
        _buildTrackerMetaChip(
          context,
          icon: Icons.hub_outlined,
          text: 'Peer ${tracker.numPeers}',
        ),
      if (!tracker.isSpecialTracker && tracker.numDownloaded >= 0)
        _buildTrackerMetaChip(
          context,
          icon: Icons.download_done_outlined,
          text: '完成 ${tracker.numDownloaded}',
        ),
    ];
    final message = tracker.msg.trim();
    final showMessage =
        !tracker.isSpecialTracker &&
        message.isNotEmpty &&
        message != tracker.statusText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _sheetContentHorizontalPadding,
        10,
        _sheetContentHorizontalPadding,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  tracker.url,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontStyle: tracker.isSpecialTracker
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: tracker.isSpecialTracker
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tracker.statusText,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              if (!tracker.isSpecialTracker)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _showTrackerActionSheet(tracker),
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (metaChips.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(spacing: 5, runSpacing: 5, children: metaChips),
          ],
          if (showMessage) ...[
            const SizedBox(height: 7),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackerMetaChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _trackerStatusColor(BuildContext context, QBTrackerModel tracker) {
    final scheme = Theme.of(context).colorScheme;
    switch (tracker.status) {
      case 0:
        return scheme.onSurfaceVariant;
      case 1:
        return scheme.secondary;
      case 2:
        return const Color(0xFF22C55E);
      case 3:
        return scheme.tertiary;
      case 4:
        return scheme.error;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  Widget _buildFilesSummaryGrid({
    required int totalSize,
    required int doneSize,
    required int completeCount,
    required int skippedCount,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return _buildMetricTileWrap(
      items: [
        _DetailMetricItem(
          label: '总大小',
          value: totalSize.toHumanReadableFileSize(),
          icon: Icons.storage_rounded,
        ),
        _DetailMetricItem(
          label: '已完成',
          value: doneSize.toHumanReadableFileSize(),
          icon: Icons.check_circle_outline_rounded,
          color: scheme.tertiary,
        ),
        _DetailMetricItem(
          label: '完整文件',
          value: '$completeCount',
          icon: Icons.task_alt_rounded,
          color: scheme.secondary,
        ),
        _DetailMetricItem(
          label: '跳过',
          value: '$skippedCount',
          icon: Icons.block_rounded,
          color: scheme.error,
        ),
      ],
    );
  }

  Widget _buildFileItem(QBTorrentFileModel file) {
    final scheme = Theme.of(context).colorScheme;
    final progressColor = file.progress >= 1.0
        ? scheme.tertiary
        : scheme.primary;
    final completedSize = (file.size * file.progress).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _sheetContentHorizontalPadding,
        10,
        _sheetContentHorizontalPadding,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _fileIcon(file.fileName),
                  size: 16,
                  color: progressColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      file.fileName,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                      contextMenuBuilder: (context, editableTextState) {
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: editableTextState.contextMenuAnchors,
                          buttonItems: [
                            ContextMenuButtonItem(
                              label: '复制',
                              onPressed: () {
                                final selection = editableTextState
                                    .textEditingValue
                                    .selection;
                                if (selection.isValid &&
                                    !selection.isCollapsed) {
                                  final selectedText = selection.textInside(
                                    file.fileName,
                                  );
                                  Clipboard.setData(
                                    ClipboardData(text: selectedText),
                                  );
                                  showToast(message: '已复制到剪贴板');
                                }
                                ContextMenuController.removeAny();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    if (file.filePath.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        file.filePath,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${file.progressPercent.toStringAsFixed(1)}%',
                    style: _dataValueStyle(
                      context,
                      emphasize: true,
                    ).copyWith(color: progressColor, fontSize: 13, height: 1),
                  ),
                  const SizedBox(height: 5),
                  _buildPriorityPill(context, file),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: file.progress.clamp(0.0, 1.0),
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _buildFileMetaChip(
                context,
                icon: Icons.storage_rounded,
                text: file.size.toHumanReadableFileSize(),
              ),
              _buildFileMetaChip(
                context,
                icon: Icons.check_circle_outline_rounded,
                text: completedSize.toHumanReadableFileSize(),
                color: progressColor,
              ),
              _buildFileMetaChip(
                context,
                icon: Icons.numbers_rounded,
                text: '#${file.index}',
              ),
              _buildFileMetaChip(
                context,
                icon: Icons.grid_on_rounded,
                text: file.pieceRangeText,
              ),
              _buildFileMetaChip(
                context,
                icon: Icons.cloud_done_outlined,
                text: _availabilityText(file.availability),
                color: scheme.secondary,
              ),
              if (file.isSeed == true)
                _buildFileMetaChip(
                  context,
                  icon: Icons.upload_rounded,
                  text: '已做种',
                  color: scheme.tertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mkv') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.ts')) {
      return Icons.movie_outlined;
    }
    if (lower.endsWith('.srt') ||
        lower.endsWith('.ass') ||
        lower.endsWith('.ssa')) {
      return Icons.subtitles_outlined;
    }
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    if (lower.endsWith('.nfo') || lower.endsWith('.txt')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Widget _buildPriorityPill(BuildContext context, QBTorrentFileModel file) {
    final color = file.priority == 1
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : file.priorityColor;
    return Container(
      constraints: const BoxConstraints(maxWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.6),
      ),
      child: Text(
        file.priorityText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _buildFileMetaChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(minHeight: 22, maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: tint),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tint,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyTrackerUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    showToast(message: 'Tracker URL 已复制到剪贴板');
  }

  void _showTrackerActionSheet(QBTrackerModel tracker) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditTrackerDialog(tracker);
            },
            child: const Text('编辑'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _copyTrackerUrl(tracker.url);
            },
            child: const Text('复制'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _showRemoveTrackerConfirm(tracker);
            },
            child: const Text('移除'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ),
    );
  }

  void _showAddTrackerDialog() {
    final urlController = TextEditingController();

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('添加 Tracker'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: urlController,
            placeholder: 'Tracker URL',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isEmpty) {
                showToast(message: '请输入 Tracker URL');
                return;
              }
              Navigator.of(context).pop();
              final success = await controller.addTrackers(widget.hash, [url]);
              if (success) {
                showToast(message: '添加成功');
                _loadTrackers();
              } else {
                showToast(message: '添加失败');
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditTrackerDialog(QBTrackerModel tracker) {
    final urlController = TextEditingController(text: tracker.url);

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('编辑 Tracker'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: urlController,
            placeholder: 'Tracker URL',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isEmpty) {
                showToast(message: '请输入 Tracker URL');
                return;
              }
              Navigator.of(context).pop();
              final success = await controller.editTracker(
                widget.hash,
                tracker.url,
                newUrl,
              );
              if (success) {
                showToast(message: '编辑成功');
                _loadTrackers();
              } else {
                showToast(message: '编辑失败');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showRemoveTrackerConfirm(QBTrackerModel tracker) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要移除 Tracker:\n${tracker.url}?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await controller.removeTrackers(widget.hash, [
                tracker.url,
              ]);
              if (success) {
                showToast(message: '移除成功');
                _loadTrackers();
              } else {
                showToast(message: '移除失败');
              }
            },
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }
}

/// 显示种子详情页面的辅助函数
void showTorrentDetailSheet(
  BuildContext context,
  String hash,
  String name, {
  QBTorrentModel? torrent,
  required QBController controller,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => QbTorrentDetailSheet(
      hash: hash,
      name: name,
      torrent: torrent,
      controller: controller,
    ),
  );
}
