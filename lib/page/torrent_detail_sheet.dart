import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_torrent_file_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_properties_model.dart';
import 'package:altman_downloader_control/model/qb_tracker_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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

  // Segment control 状态
  final _selectedSegment = 'general'.obs;
  final _generalSubSegment = 'overview'.obs;

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _loadTrackers();
    _loadFiles();
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
          child: Column(
            children: [
              _buildSheetDragHandle(context),
              _buildSheetTopBar(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Obx(() {
                  final selectedValue = _selectedSegment.value;
                  final cs = Theme.of(context).colorScheme;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: selectedValue,
                        thumbColor: cs.surface,
                        backgroundColor: Colors.transparent,
                        children: {
                          'general': _buildSegmentLabel(context, '基本'),
                          'tracker': _buildSegmentLabel(context, 'Tracker'),
                          'content': _buildSegmentLabel(context, '文件'),
                        },
                        onValueChanged: (value) {
                          if (value != null) {
                            _selectedSegment.value = value;
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
              // 内容区域
              Expanded(
                child: _isLoading
                    ? Center(
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.2),
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
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        height: 1.35,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.tonalIcon(
                                  onPressed: _loadProperties,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Obx(() {
                        // 根据选中的 segment 显示不同内容
                        switch (_selectedSegment.value) {
                          case 'general':
                            return _buildGeneralContent(scrollController);
                          case 'tracker':
                            return _buildTrackerContent(scrollController);
                          case 'content':
                            return _buildContentContent(scrollController);
                          default:
                            return _buildGeneralContent(scrollController);
                        }
                      }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSegmentLabel(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
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

  Widget _buildSheetTopBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Text(
            '种子详情',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: scheme.surfaceContainerHighest.withValues(
                alpha: 0.85,
              ),
              foregroundColor: scheme.onSurface,
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '关闭',
          ),
        ],
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
          if (onCopy != null)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: '复制',
              onPressed: onCopy,
            ),
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

  Widget _buildGeneralContent(ScrollController scrollController) {
    // 优先使用 properties，如果没有则使用列表数据
    final props = _properties;
    final torrent = widget.torrent;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralOverviewCard(context),
          const SizedBox(height: 14),
          _buildDataBlock(
            title: '任务信息',
            rows: [
              _buildDataRow('名称', props?.name ?? widget.name, maxLines: 4),
              _buildDataRow(
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
                _buildDataRow('Infohash V1', props.infohashV1, monospace: true),
              if (props != null && props.infohashV2.isNotEmpty)
                _buildDataRow('Infohash V2', props.infohashV2, monospace: true),
              if (props != null)
                _buildDataRow(
                  '私有',
                  _yesNo(props.isPrivate),
                  alignValueEnd: true,
                ),
              if (props != null)
                _buildDataRow(
                  '元数据',
                  _yesNo(props.hasMetadata),
                  alignValueEnd: true,
                ),
              if (torrent != null && torrent.category.isNotEmpty)
                _buildDataRow('分类', torrent.category, alignValueEnd: true),
              if (torrent != null && torrent.tags.isNotEmpty)
                _buildDataRow('标签', torrent.tags.join(' / '), maxLines: 4),
              if (props != null)
                _buildDataRow('保存路径', props.savePath, maxLines: 3),
              if (props != null && props.downloadPath.isNotEmpty)
                _buildDataRow('下载路径', props.downloadPath, maxLines: 3),
              if (torrent != null && torrent.contentPath.isNotEmpty)
                _buildDataRow('内容路径', torrent.contentPath, maxLines: 3),
              if (torrent != null && torrent.rootPath.isNotEmpty)
                _buildDataRow('根路径', torrent.rootPath, maxLines: 3),
              if (torrent != null && torrent.tracker.isNotEmpty)
                _buildDataRow('当前 Tracker', torrent.tracker, maxLines: 3),
              if (props == null &&
                  torrent != null &&
                  torrent.savePath.isNotEmpty)
                _buildDataRow('保存路径', torrent.savePath, maxLines: 3),
              if (props != null && props.createdBy.isNotEmpty)
                _buildDataRow('创建者', props.createdBy, maxLines: 2),
              if (props != null && props.comment.isNotEmpty)
                _buildDataRow('注释', props.comment, maxLines: 6),
            ],
          ),
          _buildMetricsBlock(
            title: '传输统计',
            items: [
              if (props != null)
                _DetailMetricItem(
                  label: '已下载',
                  value: props.totalDownloaded.toHumanReadableFileSize(),
                  icon: Icons.download_rounded,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '已下载',
                  value: torrent.downloaded.toHumanReadableFileSize(),
                  icon: Icons.download_rounded,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '已上传',
                  value: props.totalUploaded.toHumanReadableFileSize(),
                  icon: Icons.upload_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '已上传',
                  value: torrent.uploaded.toHumanReadableFileSize(),
                  icon: Icons.upload_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '浪费流量',
                  value: props.totalWasted.toHumanReadableFileSize(),
                  icon: Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '会话下载',
                  value: props.totalDownloadedSession.toHumanReadableFileSize(),
                  icon: Icons.download_for_offline_outlined,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '会话下载',
                  value: torrent.downloadedSession.toHumanReadableFileSize(),
                  icon: Icons.download_for_offline_outlined,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '会话上传',
                  value: props.totalUploadedSession.toHumanReadableFileSize(),
                  icon: Icons.publish_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '会话上传',
                  value: torrent.uploadedSession.toHumanReadableFileSize(),
                  icon: Icons.publish_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
          _buildMetricsBlock(
            title: '速度与限制',
            items: [
              _DetailMetricItem(
                label: '当前下载',
                value: _downloadSpeedText(),
                icon: Icons.south_rounded,
              ),
              _DetailMetricItem(
                label: '当前上传',
                value: _uploadSpeedText(),
                icon: Icons.north_rounded,
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
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '下载限制',
                  value: _limitText(props.dlLimit),
                  icon: Icons.speed_rounded,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '下载限制',
                  value: _limitText(torrent.dlLimit),
                  icon: Icons.speed_rounded,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '上传限制',
                  value: _limitText(props.upLimit),
                  icon: Icons.speed_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '上传限制',
                  value: _limitText(torrent.upLimit),
                  icon: Icons.speed_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
            ],
          ),
          _buildMetricsBlock(
            title: '连接与做种',
            items: [
              if (props != null)
                _DetailMetricItem(
                  label: '当前连接',
                  value: '${props.nbConnections}/${props.nbConnectionsLimit}',
                  icon: Icons.link_rounded,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '做种数',
                  value: '${props.seeds}/${props.seedsTotal}',
                  icon: Icons.cloud_upload_rounded,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '下载数',
                  value: '${props.peers}/${props.peersTotal}',
                  icon: Icons.cloud_download_rounded,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '分享率',
                  value: props.shareRatio.toStringAsFixed(4),
                  icon: Icons.swap_horiz_rounded,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '流行度',
                  value: props.popularity.toStringAsFixed(4),
                  icon: Icons.local_fire_department_outlined,
                ),
              if (props != null)
                _DetailMetricItem(
                  label: '分片',
                  value: '${props.piecesHave}/${props.piecesNum}',
                  icon: Icons.grid_view_rounded,
                ),
              if (props != null)
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
                  color: Theme.of(context).colorScheme.secondary,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '做种数',
                  value:
                      '${torrent.numComplete}/${torrent.numComplete + torrent.numIncomplete}',
                  icon: Icons.cloud_upload_rounded,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '下载数',
                  value:
                      '${torrent.numIncomplete}/${torrent.numComplete + torrent.numIncomplete}',
                  icon: Icons.cloud_download_rounded,
                ),
              if (props == null && torrent != null)
                _DetailMetricItem(
                  label: '分享率',
                  value: torrent.ratio.toStringAsFixed(4),
                  icon: Icons.swap_horiz_rounded,
                ),
              if (props == null && torrent != null && torrent.popularity > 0)
                _DetailMetricItem(
                  label: '流行度',
                  value: torrent.popularity.toStringAsFixed(4),
                  icon: Icons.local_fire_department_outlined,
                ),
            ],
          ),
          if (props != null)
            _buildDataBlock(
              title: '时间',
              rows: [
                _buildDataRow(
                  '添加时间',
                  QBTorrentPropertiesModel.formatTimestamp(props.additionDate),
                  alignValueEnd: true,
                ),
                if (props.completionDate > 0)
                  _buildDataRow(
                    '完成时间',
                    QBTorrentPropertiesModel.formatTimestamp(
                      props.completionDate,
                    ),
                    alignValueEnd: true,
                  ),
                if (props.creationDate > 0)
                  _buildDataRow(
                    '创建时间',
                    QBTorrentPropertiesModel.formatTimestamp(
                      props.creationDate,
                    ),
                    alignValueEnd: true,
                  ),
                _buildDataRow(
                  '最后见到',
                  QBTorrentPropertiesModel.formatTimestamp(props.lastSeen),
                  alignValueEnd: true,
                ),
                _buildDataRow(
                  '已用时间',
                  _timeText(props.timeElapsed),
                  alignValueEnd: true,
                ),
                _buildDataRow(
                  '做种时间',
                  _timeText(props.seedingTime),
                  alignValueEnd: true,
                ),
                _buildDataRow(
                  'ETA',
                  props.eta == 8640000
                      ? '未知'
                      : QBTorrentPropertiesModel.formatDuration(props.eta),
                  alignValueEnd: true,
                ),
                if (props.reannounce > 0)
                  _buildDataRow(
                    '重新声明',
                    QBTorrentPropertiesModel.formatDuration(props.reannounce),
                    alignValueEnd: true,
                  ),
              ],
            )
          else if (torrent != null)
            _buildDataBlock(
              title: '时间',
              rows: [
                if (torrent.addedOn > 0)
                  _buildDataRow(
                    '添加时间',
                    QBTorrentPropertiesModel.formatTimestamp(torrent.addedOn),
                    alignValueEnd: true,
                  ),
                if (torrent.completionOn > 0)
                  _buildDataRow(
                    '完成时间',
                    QBTorrentPropertiesModel.formatTimestamp(
                      torrent.completionOn,
                    ),
                    alignValueEnd: true,
                  ),
                if (torrent.lastActivity > 0)
                  _buildDataRow(
                    '最后活动',
                    QBTorrentPropertiesModel.formatTimestamp(
                      torrent.lastActivity,
                    ),
                    alignValueEnd: true,
                  ),
                if (torrent.seenComplete > 0)
                  _buildDataRow(
                    '最后完整',
                    QBTorrentPropertiesModel.formatTimestamp(
                      torrent.seenComplete,
                    ),
                    alignValueEnd: true,
                  ),
                if (torrent.timeActive > 0)
                  _buildDataRow(
                    '活动时间',
                    _timeText(torrent.timeActive.toInt()),
                    alignValueEnd: true,
                  ),
                if (torrent.seedingTime > 0)
                  _buildDataRow(
                    '做种时间',
                    _timeText(torrent.seedingTime),
                    alignValueEnd: true,
                  ),
              ],
            ),
          _buildMagnetRow(),
        ],
      ),
    );
  }

  Widget _buildGeneralOverviewCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _statusAccentColor(colorScheme);
    final torrent = widget.torrent;
    final title = _properties?.name.isNotEmpty == true
        ? _properties!.name
        : widget.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _insetCardDecoration(
        context,
        radius: 16,
        borderColor: accent.withValues(alpha: 0.28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.26,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildStatusBadge(context, _statusText(), accent),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildInfoPill(
                context,
                icon: Icons.schedule_rounded,
                text: '添加于 ${_addedTimeText()}',
              ),
              if (torrent != null && torrent.category.isNotEmpty)
                _buildInfoPill(
                  context,
                  icon: Icons.folder_outlined,
                  text: torrent.category,
                  color: colorScheme.primary,
                ),
              if (torrent != null && torrent.tags.isNotEmpty)
                for (final tag in torrent.tags.take(3))
                  _buildInfoPill(
                    context,
                    icon: Icons.sell_outlined,
                    text: tag,
                    color: colorScheme.secondary,
                  ),
              if (torrent != null && torrent.tags.length > 3)
                _buildInfoPill(
                  context,
                  icon: Icons.more_horiz_rounded,
                  text: '+${torrent.tags.length - 3}',
                  color: colorScheme.secondary,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('进度', style: _dataLabelStyle(context)),
              const Spacer(),
              Text(
                _progressText(),
                style: _dataValueStyle(
                  context,
                  emphasize: true,
                ).copyWith(color: accent, fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progressValue(),
              minHeight: 10,
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.9,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 16),
          _buildOverviewKpiGrid(context),
        ],
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

  Widget _buildInfoPill(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.14), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: tint),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewKpiGrid(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cells = [
      ('总大小', _sizeText()),
      ('剩余', _amountLeftText()),
      ('ETA', _etaText()),
      ('分享率', _ratioText()),
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKpiCell(context, cells[0].$1, cells[0].$2)),
              Container(
                width: 1,
                height: 52,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              Expanded(child: _buildKpiCell(context, cells[1].$1, cells[1].$2)),
            ],
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          Row(
            children: [
              Expanded(child: _buildKpiCell(context, cells[2].$1, cells[2].$2)),
              Container(
                width: 1,
                height: 52,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
              Expanded(child: _buildKpiCell(context, cells[3].$1, cells[3].$2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCell(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _dataLabelStyle(context)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _dataValueStyle(context, emphasize: true),
          ),
        ],
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
        child: FilledButton.tonalIcon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: magnetUri));
            showToast(message: '已复制 Magnet 链接');
          },
          icon: const Icon(Icons.link_rounded, size: 18),
          label: const Text('复制 Magnet 链接'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerContent(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      child: _buildTrackersSection(),
    );
  }

  Widget _buildContentContent(ScrollController scrollController) {
    final totalSize = _files.fold<int>(0, (sum, file) => sum + file.size);
    final doneSize = _files.fold<int>(
      0,
      (sum, file) => sum + (file.size * file.progress).round(),
    );
    final completeCount = _files.where((file) => file.progress >= 1).length;
    final skippedCount = _files.where((file) => file.priority == 0).length;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBlockTitle('文件列表', subtitle: '${_files.length} 个文件'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (_isLoadingFiles)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
            sliver: SliverToBoxAdapter(child: _buildFilesLoadingState()),
          )
        else if (_files.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
            sliver: SliverToBoxAdapter(child: _buildFilesEmptyState()),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            sliver: SliverToBoxAdapter(
              child: _buildFilesSummaryGrid(
                totalSize: totalSize,
                doneSize: doneSize,
                completeCount: completeCount,
                skippedCount: skippedCount,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
            sliver: SliverList.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) => _buildFileItem(_files[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrackersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBlockTitle('Tracker 列表', subtitle: '${_trackers.length} 个来源'),
        const SizedBox(height: 8),
        if (_isLoadingTrackers)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2.5,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '加载 Tracker…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_trackers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    size: 40,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '暂无 Tracker',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _buildTrackerSummaryCard(context),
          const SizedBox(height: 10),
          ..._trackers.asMap().entries.map((entry) {
            final index = entry.key;
            final tracker = entry.value;
            return _buildTrackerItem(tracker, index);
          }),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _showAddTrackerDialog(),
              icon: const Icon(Icons.add),
              label: const Text('添加'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackerSummaryCard(BuildContext context) {
    final working = _trackers.where((t) => t.status == 2).length;
    final inactive = _trackers
        .where((t) => t.status == 0 || t.status == 1)
        .length;
    final failed = _trackers
        .where((t) => t.status == 3 || t.status == 4)
        .length;
    final special = _trackers.where((t) => t.isSpecialTracker).length;
    return _buildCompactSummaryGrid(
      context,
      items: [
        _DetailMetricItem(
          label: '工作',
          value: '$working',
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF22C55E),
        ),
        _DetailMetricItem(
          label: '未联系/禁用',
          value: '$inactive',
          icon: Icons.pause_circle_outline_rounded,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _DetailMetricItem(
          label: '失败',
          value: '$failed',
          icon: Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        _DetailMetricItem(
          label: '特殊来源',
          value: '$special',
          icon: Icons.hub_outlined,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildCompactSummaryGrid(
    BuildContext context, {
    required List<_DetailMetricItem> items,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 4 : 2;
        const gap = 6.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _buildMetricCard(context, item)),
          ],
        );
      },
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: _insetCardDecoration(
        context,
        borderColor: statusColor.withValues(alpha: 0.35),
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
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: SelectableText(
                  tracker.url,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontStyle: tracker.isSpecialTracker
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: tracker.isSpecialTracker
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: [
                        ContextMenuButtonItem(
                          label: '复制',
                          onPressed: () {
                            final selection =
                                editableTextState.textEditingValue.selection;
                            if (selection.isValid && !selection.isCollapsed) {
                              final selectedText = selection.textInside(
                                tracker.url,
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
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(context, tracker.statusText, statusColor),
              if (!tracker.isSpecialTracker)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditTrackerDialog(tracker);
                        break;
                      case 'remove':
                        _showRemoveTrackerConfirm(tracker);
                        break;
                      case 'copy':
                        _copyTrackerUrl(tracker.url);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('复制'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('移除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
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
      constraints: const BoxConstraints(minHeight: 22, maxWidth: 160),
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

  Widget _buildFilesLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 12),
            Text(
              '加载文件列表…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 40,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 10),
            Text(
              '暂无文件',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSummaryGrid({
    required int totalSize,
    required int doneSize,
    required int completeCount,
    required int skippedCount,
  }) {
    return _buildCompactSummaryGrid(
      context,
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
          color: const Color(0xFF22C55E),
        ),
        _DetailMetricItem(
          label: '完整文件',
          value: '$completeCount',
          icon: Icons.task_alt_rounded,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _DetailMetricItem(
          label: '跳过',
          value: '$skippedCount',
          icon: Icons.block_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildFileItem(QBTorrentFileModel file) {
    final scheme = Theme.of(context).colorScheme;
    final progressColor = file.progress >= 1.0
        ? const Color(0xFF22C55E)
        : scheme.primary;
    final completedSize = (file.size * file.progress).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: _insetCardDecoration(
        context,
        radius: 12,
        borderColor: file.priority == 0
            ? scheme.error.withValues(alpha: 0.22)
            : scheme.outlineVariant.withValues(alpha: 0.32),
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
                  color: const Color(0xFF22C55E),
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

  void _showAddTrackerDialog() {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加 Tracker'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Tracker URL',
            hintText: '请输入 Tracker URL',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑 Tracker'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(labelText: 'Tracker URL'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要移除 Tracker:\n${tracker.url}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
