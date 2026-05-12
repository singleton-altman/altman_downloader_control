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

  const _DetailMetricItem({
    required this.label,
    required this.value,
    required this.icon,
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.45),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .shadow
                    .withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.38),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 4, 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurface,
                      minimumSize: const Size(40, 40),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '关闭',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Obx(() {
                  final selectedValue = _selectedSegment.value;
                  final cs = Theme.of(context).colorScheme;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: selectedValue,
                        thumbColor: cs.primaryContainer,
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
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
    if (torrent != null && torrent.stateText.isNotEmpty) {
      return torrent.stateText;
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

  Widget _buildGeneralContent(ScrollController scrollController) {
    // 优先使用 properties，如果没有则使用列表数据
    final props = _properties;
    final torrent = widget.torrent;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralOverviewCard(context),
          const SizedBox(height: 18),
          _buildSection(
            title: '更多信息',
            children: [
              _buildInfoRow(
                '哈希值',
                props?.hash ?? widget.hash,
                icon: Icons.fingerprint,
              ),
              if (props != null) ...[
                if (props.infohashV1.isNotEmpty)
                  _buildInfoRow(
                    'Infohash V1',
                    props.infohashV1,
                    icon: Icons.tag,
                  ),
                if (props.infohashV2.isNotEmpty)
                  _buildInfoRow(
                    'Infohash V2',
                    props.infohashV2,
                    icon: Icons.tag,
                  ),
                _buildInfoRow(
                  '是否私有',
                  props.isPrivate ? '是' : '否',
                  icon: Icons.lock,
                ),
                _buildInfoRow(
                  '有元数据',
                  props.hasMetadata ? '是' : '否',
                  icon: Icons.info,
                ),
              ],
              // Magnet 链接
              if (props != null)
                _buildInfoRow('保存路径', props.savePath, icon: Icons.folder),
              if (props != null && props.downloadPath.isNotEmpty)
                _buildInfoRow('下载路径', props.downloadPath, icon: Icons.download),
              if (props == null &&
                  torrent != null &&
                  torrent.savePath.isNotEmpty)
                _buildInfoRow('保存路径', torrent.savePath, icon: Icons.folder),
              if (props != null && props.createdBy.isNotEmpty)
                _buildInfoRow('创建者', props.createdBy, icon: Icons.person),
              if (props != null && props.comment.isNotEmpty)
                _buildCommentRow(props.comment),
              _buildMagnetRow(),
              _buildInfoGroupLabel(context, '统计'),
              _buildMetricGrid(
                context,
                items: [
                  if (props != null)
                    _DetailMetricItem(
                      label: '已下载',
                      value: props.totalDownloaded.toHumanReadableFileSize(),
                      icon: Icons.download_rounded,
                    ),
                  if (props != null)
                    _DetailMetricItem(
                      label: '已上传',
                      value: props.totalUploaded.toHumanReadableFileSize(),
                      icon: Icons.upload_rounded,
                    ),
                  if (props != null)
                    _DetailMetricItem(
                      label: '浪费流量',
                      value: props.totalWasted.toHumanReadableFileSize(),
                      icon: Icons.warning_amber_rounded,
                    ),
                  if (props != null)
                    _DetailMetricItem(
                      label: '会话下载',
                      value: props.totalDownloadedSession
                          .toHumanReadableFileSize(),
                      icon: Icons.download_for_offline_outlined,
                    ),
                  if (props != null)
                    _DetailMetricItem(
                      label: '会话上传',
                      value: props.totalUploadedSession
                          .toHumanReadableFileSize(),
                      icon: Icons.publish_rounded,
                    ),
                ],
              ),
              _buildMetricGrid(
                context,
                title: '速度',
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
                      value: props.dlLimit == -1
                          ? '无限制'
                          : '${props.dlLimit.toHumanReadableFileSize(round: 1)}/s',
                      icon: Icons.speed_rounded,
                    ),
                  if (props != null)
                    _DetailMetricItem(
                      label: '上传限制',
                      value: props.upLimit == -1
                          ? '无限制'
                          : '${props.upLimit.toHumanReadableFileSize(round: 1)}/s',
                      icon: Icons.speed_rounded,
                    ),
                ],
              ),
              _buildMetricGrid(
                context,
                title: '连接与做种',
                items: [
                  if (props != null)
                    _DetailMetricItem(
                      label: '当前连接',
                      value:
                          '${props.nbConnections}/${props.nbConnectionsLimit}',
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
                  if (props == null &&
                      torrent != null &&
                      torrent.popularity > 0)
                    _DetailMetricItem(
                      label: '流行度',
                      value: torrent.popularity.toStringAsFixed(4),
                      icon: Icons.local_fire_department_outlined,
                    ),
                ],
              ),
              _buildInfoGroupLabel(context, '时间与调度'),
              if (props != null) ...[
                _buildInfoRow(
                  '添加时间',
                  QBTorrentPropertiesModel.formatTimestamp(props.additionDate),
                  icon: Icons.add_circle,
                ),
                if (props.completionDate > 0)
                  _buildInfoRow(
                    '完成时间',
                    QBTorrentPropertiesModel.formatTimestamp(
                      props.completionDate,
                    ),
                    icon: Icons.check_circle,
                  ),
                if (props.creationDate > 0)
                  _buildInfoRow(
                    '创建时间',
                    QBTorrentPropertiesModel.formatTimestamp(
                      props.creationDate,
                    ),
                    icon: Icons.create,
                  ),
                _buildInfoRow(
                  '最后见到',
                  QBTorrentPropertiesModel.formatTimestamp(props.lastSeen),
                  icon: Icons.visibility,
                ),
                _buildInfoRow(
                  '已用时间',
                  QBTorrentPropertiesModel.formatDuration(props.timeElapsed),
                  icon: Icons.timer,
                ),
                _buildInfoRow(
                  '做种时间',
                  QBTorrentPropertiesModel.formatDuration(props.seedingTime),
                  icon: Icons.history,
                ),
                _buildInfoRow(
                  'ETA',
                  props.eta == 8640000
                      ? '未知'
                      : QBTorrentPropertiesModel.formatDuration(props.eta),
                  icon: Icons.schedule,
                ),
                if (props.reannounce > 0)
                  _buildInfoRow(
                    '重新声明间隔',
                    QBTorrentPropertiesModel.formatDuration(props.reannounce),
                    icon: Icons.refresh,
                  ),
              ] else if (torrent != null && torrent.addedOn > 0) ...[
                _buildInfoRow(
                  '添加时间',
                  QBTorrentPropertiesModel.formatTimestamp(torrent.addedOn),
                  icon: Icons.add_circle,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGroupLabel(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  Widget _buildMetricGrid(
    BuildContext context, {
    String? title,
    required List<_DetailMetricItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
              ),
            ),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final columns = constraints.maxWidth >= 560 ? 3 : 2;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: itemWidth,
                        child: _buildDetailMetricCard(context, item),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailMetricCard(BuildContext context, _DetailMetricItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(
          alpha: isDark ? 0.22 : 0.42,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              item.icon,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralOverviewCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(
              alpha: isDark ? 0.52 : 0.72,
            ),
            colorScheme.surfaceContainerHigh.withValues(
              alpha: isDark ? 0.28 : 0.45,
            ),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusText(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '添加于 ${_addedTimeText()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '当前进度',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Text(
                _progressText(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progressValue(),
              minHeight: 9,
              backgroundColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 14),
          _buildOverviewStatsStrip(context),
        ],
      ),
    );
  }

  Widget _buildOverviewStatsStrip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = ['总大小', '下载', '上传', '比率'];
    final values = [
      _sizeText(),
      _downloadSpeedText(),
      _uploadSpeedText(),
      _ratioText(),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.28 : 0.42),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    values[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: magnetUri));
            showToast(message: '已复制 Magnet 链接');
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('复制 Magnet 链接'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentRow(String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.comment,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              '注释',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
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
                          final selectedText = selection.textInside(comment);
                          Clipboard.setData(ClipboardData(text: selectedText));
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
        ],
      ),
    );
  }

  Widget _buildTrackerContent(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      child: _buildTrackersSection(),
    );
  }

  Widget _buildContentContent(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      child: _buildFilesSection(),
    );
  }

  Widget _buildTrackersSection() {
    return _buildSection(
      title: 'Tracker 列表',
      children: [
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.45),
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
        else
          ..._trackers.asMap().entries.map((entry) {
            final index = entry.key;
            final tracker = entry.value;
            return _buildTrackerItem(tracker, index);
          }),
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

  Widget _buildTrackerItem(QBTrackerModel tracker, int index) {
    final statusColor = tracker.statusColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.32), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              if (!tracker.isSpecialTracker)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
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
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTrackerStatusChip(tracker),
              const SizedBox(width: 8),
              if (tracker.tier >= 0)
                Chip(
                  label: Text('优先级: ${tracker.tier}'),
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              if (!tracker.isSpecialTracker &&
                  (tracker.numSeeds >= 0 || tracker.numLeeches >= 0)) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text('种子/下载: ${tracker.formattedPeers}'),
                  labelStyle: Theme.of(context).textTheme.labelSmall,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ],
            ],
          ),
          if (tracker.msg.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tracker.msg,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackerStatusChip(QBTrackerModel tracker) {
    return Chip(
      label: Text(tracker.statusText),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: tracker.statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildFilesSection() {
    return _buildSection(
      title: '文件列表',
      children: [
        if (_isLoadingFiles)
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
                    '加载文件列表…',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_files.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 40,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.45),
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
          )
        else
          ..._files.map((file) => _buildFileItem(file)),
      ],
    );
  }

  Widget _buildFileItem(QBTorrentFileModel file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文件名
          Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  file.fileName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
              ),
              // 优先级标签
              if (file.priority != 1)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: file.priorityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: file.priorityColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    file.priorityText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: file.priorityColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          if (file.filePath.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                file.filePath,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: file.progress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                file.progress >= 1.0
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 详细信息
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildFileInfoChip(
                context,
                icon: Icons.storage,
                label: file.size.toHumanReadableFileSize(),
                color: Colors.blue,
              ),
              _buildFileInfoChip(
                context,
                icon: Icons.percent,
                label: '${file.progressPercent.toStringAsFixed(1)}%',
                color: file.progress >= 1.0 ? Colors.green : Colors.orange,
              ),
              _buildFileInfoChip(
                context,
                icon: Icons.grid_view,
                label: '分片: ${file.pieceRangeText}',
                color: Colors.purple,
              ),
              if (file.isSeed == true)
                _buildFileInfoChip(
                  context,
                  icon: Icons.check_circle,
                  label: '已做种',
                  color: Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(
        alpha: isDark ? 0.4 : 0.72,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.48,
          ),
          width: 0.75,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    int maxLines = 1,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    icon,
                    size: 18,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                  maxLines: maxLines,
                  overflow: maxLines > 1
                      ? TextOverflow.ellipsis
                      : TextOverflow.clip,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.5,
          color: scheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ],
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
