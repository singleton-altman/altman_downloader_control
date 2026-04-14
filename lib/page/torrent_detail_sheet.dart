import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_torrent_file_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_model.dart';
import 'package:altman_downloader_control/model/qb_torrent_properties_model.dart';
import 'package:altman_downloader_control/model/qb_tracker_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

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
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 顶部拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              // Segment Control
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Obx(() {
                  final selectedValue = _selectedSegment.value;
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildSegmentItem(
                          context,
                          value: 'general',
                          label: '基本信息',
                          icon: Icons.info_outline,
                          isSelected: selectedValue == 'general',
                          onTap: () => _selectedSegment.value = 'general',
                        ),
                        const SizedBox(width: 4),
                        _buildSegmentItem(
                          context,
                          value: 'tracker',
                          label: 'Tracker',
                          icon: Icons.dns,
                          isSelected: selectedValue == 'tracker',
                          onTap: () => _selectedSegment.value = 'tracker',
                        ),
                        const SizedBox(width: 4),
                        _buildSegmentItem(
                          context,
                          value: 'content',
                          label: '文件内容',
                          icon: Icons.folder,
                          isSelected: selectedValue == 'content',
                          onTap: () => _selectedSegment.value = 'content',
                        ),
                      ],
                    ),
                  );
                }),
              ),
              // 内容区域
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadProperties,
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试'),
                            ),
                          ],
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

  Widget _buildSegmentItem(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralContent(ScrollController scrollController) {
    // 优先使用 properties，如果没有则使用列表数据
    final props = _properties;
    final torrent = widget.torrent;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 种子名称
          _buildSection(
            title: '基本信息',
            children: [
              _buildInfoRow(
                '名称',
                props?.name ?? torrent?.name ?? widget.name,
                icon: Icons.label,
                maxLines: 5,
              ),
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
              _buildMagnetRow(),
            ],
          ),
          const SizedBox(height: 16),

          // 进度和大小
          _buildSection(
            title: '进度和大小',
            children: [
              _buildInfoRow(
                '进度',
                props != null
                    ? '${props.progressPercent.toStringAsFixed(2)}%'
                    : torrent != null
                    ? '${(torrent.progress * 100).toStringAsFixed(2)}%'
                    : '0%',
                icon: Icons.percent,
              ),
              _buildInfoRow(
                '总大小',
                props != null
                    ? props.totalSize.toHumanReadableFileSize()
                    : torrent != null
                    ? (torrent.totalSize > 0
                          ? torrent.totalSize.toHumanReadableFileSize()
                          : torrent.size.toHumanReadableFileSize())
                    : '未知',
                icon: Icons.storage,
              ),
              if (props != null) ...[
                _buildInfoRow(
                  '已下载',
                  props.totalDownloaded.toHumanReadableFileSize(),
                  icon: Icons.download,
                ),
                _buildInfoRow(
                  '已上传',
                  props.totalUploaded.toHumanReadableFileSize(),
                  icon: Icons.upload,
                ),
                _buildInfoRow(
                  '浪费流量',
                  props.totalWasted.toHumanReadableFileSize(),
                  icon: Icons.warning,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 速度信息
          _buildSection(
            title: '速度信息',
            children: [
              _buildInfoRow(
                '当前下载速度',
                props != null
                    ? (props.dlSpeed > 0
                          ? '${props.dlSpeed.toHumanReadableFileSize(round: 1)}/s'
                          : '0 B/s')
                    : torrent != null
                    ? (torrent.dlspeed > 0
                          ? '${torrent.dlspeed.toHumanReadableFileSize(round: 1)}/s'
                          : '0 B/s')
                    : '0 B/s',
                icon: Icons.download,
              ),
              if (props != null) ...[
                _buildInfoRow(
                  '平均下载速度',
                  props.dlSpeedAvg > 0
                      ? '${props.dlSpeedAvg.toHumanReadableFileSize(round: 1)}/s'
                      : '0 B/s',
                  icon: Icons.trending_down,
                ),
                _buildInfoRow(
                  '当前上传速度',
                  props.upSpeed > 0
                      ? '${props.upSpeed.toHumanReadableFileSize(round: 1)}/s'
                      : '0 B/s',
                  icon: Icons.upload,
                ),
                _buildInfoRow(
                  '平均上传速度',
                  props.upSpeedAvg > 0
                      ? '${props.upSpeedAvg.toInt().toHumanReadableFileSize(round: 1)}/s'
                      : '0 B/s',
                  icon: Icons.trending_up,
                ),
                _buildInfoRow(
                  '下载限制',
                  props.dlLimit == -1
                      ? '无限制'
                      : '${props.dlLimit.toHumanReadableFileSize(round: 1)}/s',
                  icon: Icons.speed,
                ),
                _buildInfoRow(
                  '上传限制',
                  props.upLimit == -1
                      ? '无限制'
                      : '${props.upLimit.toHumanReadableFileSize(round: 1)}/s',
                  icon: Icons.speed,
                ),
              ] else if (torrent != null) ...[
                _buildInfoRow(
                  '当前上传速度',
                  torrent.upspeed > 0
                      ? '${torrent.upspeed.toHumanReadableFileSize(round: 1)}/s'
                      : '0 B/s',
                  icon: Icons.upload,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 会话统计（仅当有详细数据时显示）
          if (props != null) ...[
            _buildSection(
              title: '会话统计',
              children: [
                _buildInfoRow(
                  '会话下载',
                  props.totalDownloadedSession.toHumanReadableFileSize(),
                  icon: Icons.download_outlined,
                ),
                _buildInfoRow(
                  '会话上传',
                  props.totalUploadedSession.toHumanReadableFileSize(),
                  icon: Icons.upload_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 连接和做种信息
          if (props != null)
            _buildSection(
              title: '连接和做种',
              children: [
                _buildInfoRow(
                  '当前连接数',
                  '${props.nbConnections}/${props.nbConnectionsLimit}',
                  icon: Icons.link,
                ),
                _buildInfoRow(
                  '做种数',
                  '${props.seeds}/${props.seedsTotal}',
                  icon: Icons.cloud_upload,
                ),
                _buildInfoRow(
                  '下载数',
                  '${props.peers}/${props.peersTotal}',
                  icon: Icons.cloud_download,
                ),
                _buildInfoRow(
                  '分享率',
                  props.shareRatio.toStringAsFixed(4),
                  icon: Icons.swap_horiz,
                ),
                _buildInfoRow(
                  '流行度',
                  props.popularity.toStringAsFixed(4),
                  icon: Icons.local_fire_department,
                ),
              ],
            )
          else if (torrent != null)
            _buildSection(
              title: '连接和做种',
              children: [
                _buildInfoRow(
                  '做种数',
                  '${torrent.numComplete}/${torrent.numComplete + torrent.numIncomplete}',
                  icon: Icons.cloud_upload,
                ),
                _buildInfoRow(
                  '下载数',
                  '${torrent.numIncomplete}/${torrent.numComplete + torrent.numIncomplete}',
                  icon: Icons.cloud_download,
                ),
                if (torrent.popularity > 0)
                  _buildInfoRow(
                    '流行度',
                    torrent.popularity.toStringAsFixed(4),
                    icon: Icons.local_fire_department,
                  ),
              ],
            ),
          if (props != null || torrent != null) const SizedBox(height: 16),

          // 分片信息（仅当有详细数据时显示）
          if (props != null) ...[
            _buildSection(
              title: '分片信息',
              children: [
                _buildInfoRow(
                  '分片大小',
                  props.pieceSize.toHumanReadableFileSize(),
                  icon: Icons.grid_view,
                ),
                _buildInfoRow(
                  '已获得分片',
                  '${props.piecesHave}/${props.piecesNum}',
                  icon: Icons.check_circle,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // 时间信息
          _buildSection(
            title: '时间信息',
            children: [
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
          const SizedBox(height: 16),

          // 路径信息
          if (props != null)
            _buildSection(
              title: '路径信息',
              children: [
                _buildInfoRow('保存路径', props.savePath, icon: Icons.folder),
                if (props.downloadPath.isNotEmpty)
                  _buildInfoRow(
                    '下载路径',
                    props.downloadPath,
                    icon: Icons.download,
                  ),
              ],
            )
          else if (torrent != null && torrent.savePath.isNotEmpty)
            _buildSection(
              title: '路径信息',
              children: [
                _buildInfoRow('保存路径', torrent.savePath, icon: Icons.folder),
              ],
            ),
          if (props != null || (torrent != null && torrent.savePath.isNotEmpty))
            const SizedBox(height: 16),

          // 其他信息（仅当有详细数据时显示）
          if (props != null &&
              (props.comment.isNotEmpty || props.createdBy.isNotEmpty)) ...[
            _buildSection(
              title: '其他信息',
              children: [
                if (props.comment.isNotEmpty) _buildCommentRow(props.comment),
                if (props.createdBy.isNotEmpty)
                  _buildInfoRow('创建者', props.createdBy, icon: Icons.person),
              ],
            ),
            const SizedBox(height: 16),
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
        child: OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: magnetUri));
            showToast(message: '已复制 Magnet 链接');
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('复制 Magnet 链接'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      padding: const EdgeInsets.all(16),
      child: _buildTrackersSection(),
    );
  }

  Widget _buildContentContent(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: _buildFilesSection(),
    );
  }

  Widget _buildTrackersSection() {
    return _buildSection(
      title: 'Tracker 列表',
      children: [
        if (_isLoadingTrackers)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_trackers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '暂无 Tracker',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
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
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_files.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '暂无文件',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: maxLines,
              overflow: maxLines > 1
                  ? TextOverflow.ellipsis
                  : TextOverflow.clip,
            ),
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
