import 'dart:math';
import 'dart:ui';

import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_log_page.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_preferences_settings_page.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_rss_list_page.dart';
import 'package:altman_downloader_control/page/torrent_download_screen.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/filter_widget.dart';
import 'package:altman_downloader_control/widget/input_dialog.dart'
    show showMSConfirmDialog;
import 'package:altman_downloader_control/widget/qbittorrent/qb_category_picker.dart';
import 'package:altman_downloader_control/widget/qbittorrent/qb_tag_picker.dart';
import 'package:altman_downloader_control/widget/torrent_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/controller/transmission/transmission_controller.dart';
import 'package:altman_downloader_control/model/qb_sort_type.dart';
import 'package:altman_downloader_control/model/transmission_list_sort_type.dart';
import 'package:altman_downloader_control/utils/string_utils.dart';
import 'package:altman_downloader_control/utils/torrent_state_localizable.dart';

class DownloaderTorrentListPage extends StatefulWidget {
  const DownloaderTorrentListPage({super.key});

  @override
  State<DownloaderTorrentListPage> createState() =>
      _DownloaderTorrentListPageState();
}

class _DownloaderTorrentListPageState extends State<DownloaderTorrentListPage> {
  late final DownloaderControllerProtocol controller;
  final _isBootstrapping = true.obs;
  bool _selectionMode = false;
  final Set<String> _selectedHashes = <String>{};

  @override
  void initState() {
    super.initState();
    controller = Get.find<DownloaderControllerProtocol>();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _refreshData();
    _isBootstrapping.value = false;
  }

  /// 判断是否为 qBittorrent
  bool get isQBittorrent =>
      controller.config?.type == DownloaderType.qbittorrent;

  /// 判断是否为 Transmission
  bool get isTransmission =>
      controller.config?.type == DownloaderType.transmission;

  Future<void> _refreshData() async {
    // 如果是 qBittorrent，使用扩展方法；否则使用协议方法
    if (controller is QBController) {
      await (controller as QBController).refreshTorrentsWithMainData();
    } else {
      await controller.refreshTorrents();
    }
  }

  // 辅助方法：获取通用格式的种子列表
  List<TorrentModel> get torrentsList {
    return controller.torrentsUniversal;
  }

  List<TorrentModel> get filteredTorrentsList {
    if (controller is QBController) {
      final qbController = controller as QBController;
      if (qbController.filter.value.hasFilters) {
        return qbController.filteredTorrents
            .map((t) => t.toTorrentModel())
            .toList();
      }
      return qbController.torrentsUniversal;
    }
    if (controller is TransmissionController) {
      final tr = controller as TransmissionController;
      final kw = tr.listSearchKeyword.value.trim().toLowerCase();
      var list = tr.torrentsUniversal;
      if (kw.isNotEmpty) {
        list = list.where((t) {
          if (t.name.toLowerCase().contains(kw)) return true;
          if (t.category.toLowerCase().contains(kw)) return true;
          for (final tag in t.tags) {
            if (tag.toLowerCase().contains(kw)) return true;
          }
          return false;
        }).toList();
      }
      list = List<TorrentModel>.from(list);
      _sortTransmissionList(list, tr.listSortType.value);
      return list;
    }
    return controller.torrentsUniversal;
  }

  void _sortTransmissionList(
    List<TorrentModel> list,
    TransmissionTorrentSortType type,
  ) {
    switch (type) {
      case TransmissionTorrentSortType.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case TransmissionTorrentSortType.size:
        list.sort((a, b) => b.totalSize.compareTo(a.totalSize));
        break;
      case TransmissionTorrentSortType.progress:
        list.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case TransmissionTorrentSortType.dateAdded:
        list.sort((a, b) => b.addedOn.compareTo(a.addedOn));
        break;
      case TransmissionTorrentSortType.speed:
        list.sort((a, b) {
          final sa = a.dlspeed + a.upspeed;
          final sb = b.dlspeed + b.upspeed;
          return sb.compareTo(sa);
        });
        break;
      case TransmissionTorrentSortType.seeds:
        list.sort((a, b) => b.numSeeds.compareTo(a.numSeeds));
        break;
      case TransmissionTorrentSortType.ratio:
        list.sort((a, b) => b.ratio.compareTo(a.ratio));
        break;
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedHashes.clear();
    });
  }

  void _toggleHash(String hash) {
    setState(() {
      if (_selectedHashes.contains(hash)) {
        _selectedHashes.remove(hash);
      } else {
        _selectedHashes.add(hash);
      }
    });
  }

  void _toggleSelectAllVisible(List<TorrentModel> visible) {
    setState(() {
      final allOn =
          visible.isNotEmpty &&
          visible.every((t) => _selectedHashes.contains(t.hash));
      if (allOn) {
        for (final t in visible) {
          _selectedHashes.remove(t.hash);
        }
      } else {
        for (final t in visible) {
          _selectedHashes.add(t.hash);
        }
      }
    });
  }

  Future<void> _batchPause() async {
    final list = _selectedHashes.toList();
    if (list.isEmpty) return;
    await controller.pauseTorrents(list);
    await _refreshData();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _batchResume() async {
    final list = _selectedHashes.toList();
    if (list.isEmpty) return;
    await controller.resumeTorrents(list);
    await _refreshData();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _batchDelete() async {
    final hashes = _selectedHashes.toList();
    if (hashes.isEmpty) return;
    var deleteFiles = false;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('删除 ${hashes.length} 项'),
          content: CheckboxListTile(
            value: deleteFiles,
            onChanged: (v) => setDlg(() => deleteFiles = v ?? false),
            title: const Text('同时删除本地文件'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除'),
            ),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    for (final h in hashes) {
      await controller.deleteTorrent(h, deleteFiles: deleteFiles);
    }
    await _refreshData();
    if (!mounted) return;
    setState(() {
      _selectedHashes.removeWhere(hashes.contains);
      if (_selectedHashes.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  TorrentModel? _torrentForHash(String hash) {
    for (final t in filteredTorrentsList) {
      if (t.hash == hash) return t;
    }
    for (final t in controller.torrentsUniversal) {
      if (t.hash == hash) return t;
    }
    return null;
  }

  List<String> get _selectedList => _selectedHashes.toList();

  Future<void> _batchForceStart() async {
    final list = _selectedList;
    if (list.isEmpty) return;
    final ok = await controller.forceStartTorrents(list, true);
    showToast(message: ok ? '已强制启动' : '强制启动失败');
    await _refreshData();
    if (mounted) setState(() {});
  }

  Future<void> _batchRecheck() async {
    final list = _selectedList;
    if (list.isEmpty) return;
    final ok = await showMSConfirmDialog(
      context,
      title: '确认重新校验',
      message: '确定要对 ${list.length} 项强制重新校验吗？',
      confirmText: '确认',
      cancelText: '取消',
      icon: Icons.verified_outlined,
    );
    if (ok != true || !mounted) return;
    final success = await controller.recheckTorrents(list);
    showToast(message: success ? '已开始重新校验' : '重新校验失败');
    await _refreshData();
    if (mounted) setState(() {});
  }

  Future<void> _batchSetLocation() async {
    final list = _selectedList;
    if (list.isEmpty) return;
    final first = _torrentForHash(list.first);
    final location = await showMSInputDialog(
      context,
      title: '设置保存地址',
      labelText: '保存路径',
      hintText: '请输入保存路径',
      initialValue: first?.savePath ?? '',
      icon: Icons.folder_outlined,
    );
    if (location == null || location.isEmpty || !mounted) return;
    final success = await controller.setTorrentLocation(list, location);
    showToast(message: success ? '设置成功' : '设置失败');
    await _refreshData();
    if (mounted) setState(() {});
  }

  Future<void> _batchRename() async {
    final list = _selectedList;
    if (list.length != 1) return;
    final t = _torrentForHash(list.first);
    if (t == null) return;
    final newName = await showMSInputDialog(
      context,
      title: '重命名',
      labelText: '名称',
      hintText: '请输入新名称',
      initialValue: t.name,
      icon: Icons.edit,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return '请输入名称';
        return null;
      },
    );
    if (newName == null || newName.trim().isEmpty || !mounted) return;
    final success = await controller.renameTorrent(list.first, newName.trim());
    showToast(message: success ? '重命名成功' : '重命名失败');
    await _refreshData();
    if (mounted) setState(() {});
  }

  Future<void> _batchSetCategory() async {
    final list = _selectedList;
    if (list.isEmpty) return;
    String? category;
    if (controller is QBController) {
      category = await showQBCategoryPicker(
        context,
        controller as QBController,
      );
    } else {
      category = await showMSInputDialog(
        context,
        title: '设置分类',
        labelText: '分类名称',
        hintText: '请输入分类名称（留空可清除分类）',
        icon: Icons.category,
      );
    }
    if (category == null || !mounted) return;
    final success = await controller.setTorrentCategory(list, category);
    showToast(
      message: success ? (category.isEmpty ? '已清除分类' : '设置成功') : '设置失败',
    );
    await _refreshData();
    if (mounted) setState(() {});
  }

  Future<void> _batchSetTags() async {
    final list = _selectedList;
    if (list.isEmpty) return;
    List<String>? selectedTags;
    if (controller is QBController) {
      final qb = controller as QBController;
      final tagSet = <String>{};
      for (final h in list) {
        final t = _torrentForHash(h);
        if (t != null) tagSet.addAll(t.tags);
      }
      selectedTags = await showQBTagPicker(
        context,
        initialSelectedTags: tagSet.toList(),
        controller: qb,
      );
    } else {
      final first = _torrentForHash(list.first);
      final text = await showMSInputDialog(
        context,
        title: '设置标签',
        labelText: '标签',
        hintText: '多个标签使用逗号分隔',
        initialValue: first?.tags.join(',') ?? '',
        icon: Icons.label,
      );
      if (text == null || !mounted) return;
      selectedTags = text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (selectedTags == null || !mounted) return;
    final success = await controller.setTorrentTags(list, selectedTags);
    showToast(message: success ? '设置成功' : '设置失败');
    await _refreshData();
    if (mounted) setState(() {});
  }

  Future<void> _batchSetDownloadLimit() async {
    final list = _selectedList;
    if (list.isEmpty) return;
    final limitText = await showMSInputDialog(
      context,
      title: '限制下载速度',
      labelText: '速度限制（KB/s）',
      hintText: '输入 0 表示无限制',
      icon: Icons.download,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
          return '请输入有效的数字';
        }
        return null;
      },
    );
    if (limitText == null || !mounted) return;
    var limit = -1;
    if (limitText.isNotEmpty) {
      final v = int.tryParse(limitText);
      if (v == null) {
        showToast(message: '请输入有效的数字');
        return;
      }
      limit = v > 0 ? v * 1024 : -1;
    }
    final success = await controller.setTorrentDownloadLimit(list, limit);
    showToast(message: success ? '设置成功' : '设置失败');
    await _refreshData();
    if (mounted) setState(() {});
  }

  Future<void> _batchSetUploadLimit() async {
    final list = _selectedList;
    if (list.isEmpty) return;
    final limitText = await showMSInputDialog(
      context,
      title: '限制上传速度',
      labelText: '速度限制（KB/s）',
      hintText: '输入 0 表示无限制',
      icon: Icons.upload,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
          return '请输入有效的数字';
        }
        return null;
      },
    );
    if (limitText == null || !mounted) return;
    var limit = -1;
    if (limitText.isNotEmpty) {
      final v = int.tryParse(limitText);
      if (v == null) {
        showToast(message: '请输入有效的数字');
        return;
      }
      limit = v > 0 ? v * 1024 : -1;
    }
    final success = await controller.setTorrentUploadLimit(list, limit);
    showToast(message: success ? '设置成功' : '设置失败');
    await _refreshData();
    if (mounted) setState(() {});
  }

  List<_SelectionBarOp> _selectionBarOps() {
    final sel = _selectedList;
    final has = sel.isNotEmpty;
    final one = sel.length == 1;
    return [
      _SelectionBarOp(
        'resume',
        Icons.play_arrow_rounded,
        '开始',
        () => _batchResume(),
        has,
        tooltip: '恢复所选任务的下载',
      ),
      _SelectionBarOp(
        'pause',
        Icons.pause_rounded,
        '停止',
        () => _batchPause(),
        has,
        tooltip: '暂停所选任务',
      ),
      _SelectionBarOp(
        'delete',
        Icons.delete_outline_rounded,
        '删除',
        () => _batchDelete(),
        has,
        tooltip: '删除所选任务',
      ),
      _SelectionBarOp(
        'recheck',
        Icons.verified_outlined,
        '重新校验',
        () => _batchRecheck(),
        has,
        tooltip: '重新校验本地数据与种子是否一致',
      ),
      _SelectionBarOp(
        'force',
        Icons.play_circle_outline_rounded,
        '强制启动',
        () => _batchForceStart(),
        has,
        tooltip: '强制开始，可绕过队列顺序',
      ),
      _SelectionBarOp(
        'location',
        Icons.folder_outlined,
        '保存地址',
        () => _batchSetLocation(),
        has,
        tooltip: '修改保存目录',
      ),
      _SelectionBarOp(
        'rename',
        Icons.edit_outlined,
        '重命名',
        () => _batchRename(),
        has && one,
        tooltip: '重命名任务（需仅选中一项）',
      ),
      _SelectionBarOp(
        'category',
        Icons.category_outlined,
        '分类',
        () => _batchSetCategory(),
        has,
        tooltip: '设置分类',
      ),
      _SelectionBarOp(
        'tags',
        Icons.label_outline_rounded,
        '标签',
        () => _batchSetTags(),
        has,
        tooltip: '设置标签',
      ),
      _SelectionBarOp(
        'dllimit',
        Icons.download_outlined,
        '下载限速',
        () => _batchSetDownloadLimit(),
        has,
        tooltip: '批量设置下载速度上限（KB/s）',
      ),
      _SelectionBarOp(
        'uplimit',
        Icons.upload_outlined,
        '上传限速',
        () => _batchSetUploadLimit(),
        has,
        tooltip: '批量设置上传速度上限（KB/s）',
      ),
    ];
  }

  Color _selectionBarIconColor(ColorScheme scheme, _SelectionBarOp o) {
    if (!o.enabled) {
      return scheme.onSurfaceVariant.withValues(alpha: 0.35);
    }
    switch (o.id) {
      case 'resume':
      case 'force':
      case 'dllimit':
        return scheme.primary;
      case 'pause':
      case 'uplimit':
        return scheme.secondary;
      case 'delete':
        return scheme.error;
      case 'recheck':
        return scheme.tertiary;
      case 'location':
      case 'rename':
      case 'category':
      case 'tags':
        return scheme.onSurfaceVariant;
      default:
        return scheme.onSurface;
    }
  }

  Widget _buildSelectionFloatingBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ops = _selectionBarOps();
    const primaryCount = 4;
    const wideBarW = 640.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final primary = ops.take(primaryCount).toList();
          final secondary = ops.length > primaryCount
              ? ops.sublist(primaryCount)
              : <_SelectionBarOp>[];
          final showAllInline = constraints.maxWidth >= wideBarW;

          return ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52, maxHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            if (showAllInline)
                              for (final o in ops) _selectionBarIcon(context, o)
                            else ...[
                              for (final o in primary)
                                _selectionBarIcon(context, o),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!showAllInline && secondary.isNotEmpty)
                      PopupMenuButton<String>(
                        tooltip: '更多操作',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        onSelected: (id) async {
                          for (final o in secondary) {
                            if (o.id == id && o.enabled) {
                              await o.action();
                              break;
                            }
                          }
                        },
                        itemBuilder: (ctx) {
                          final menuScheme = Theme.of(ctx).colorScheme;
                          return [
                            for (final o in secondary)
                              PopupMenuItem<String>(
                                value: o.id,
                                enabled: o.enabled,
                                child: Tooltip(
                                  message: o.tooltipMessage,
                                  child: Row(
                                    children: [
                                      Icon(
                                        o.icon,
                                        size: 20,
                                        color: _selectionBarIconColor(
                                          menuScheme,
                                          o,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        o.label,
                                        style: Theme.of(
                                          ctx,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ];
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _selectionBarIcon(BuildContext context, _SelectionBarOp o) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = _selectionBarIconColor(scheme, o);
    return SizedBox(
      width: 80,
      height: 48,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: o.tooltipMessage,
        icon: Icon(o.icon, size: 22, color: iconColor),
        onPressed: o.enabled
            ? () async {
                await o.action();
              }
            : null,
      ),
    );
  }

  // 辅助方法：是否支持筛选功能（仅 qBittorrent 支持）
  bool get supportsFilter => isQBittorrent;

  // 辅助方法：是否支持 RSS 功能（仅 qBittorrent 支持）
  bool get supportsRSS => isQBittorrent;

  // 辅助方法：是否支持偏好设置（仅 qBittorrent 支持）
  bool get supportsPreferences => isQBittorrent;

  @override
  Widget build(BuildContext context) {
    if (controller is QBController) {
      final qb = controller as QBController;
      return Obx(() {
        if (!qb.isLocalStateReady.value) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: CustomScrollView(slivers: [_buildSkeletonList(context)]),
          );
        }
        return _buildPageScaffold(context);
      });
    }
    return Obx(() {
      filteredTorrentsList;
      return _buildPageScaffold(context);
    });
  }

  Widget _buildPageScaffold(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _selectionMode
          ? _buildSelectionFloatingBar(context)
          : _buildFloatingToolbar(context),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildErrorMessage(context)),
            _buildTorrentInfo(context),
            _buildTorrentList(context),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    MediaQuery.of(context).padding.bottom +
                    (_selectionMode ? 88 : 76),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTorrentInfo(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final displayTorrents = filteredTorrentsList;
        if (displayTorrents.isEmpty) {
          return const SizedBox.shrink();
        }

        // 计算总尺寸
        int totalSize = 0;
        for (var torrent in displayTorrents) {
          final size = torrent.totalSize > 0 ? torrent.totalSize : torrent.size;
          totalSize += size;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 标题行：标题 + 排序按钮
              Text(
                '种子列表',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  letterSpacing: -0.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Spacer(),
              // 信息行：种子数量和体积
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${displayTorrents.length} 个种子',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.storage_rounded,
                size: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                totalSize.toHumanReadableFileSize(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFloatingToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildFloatingFilterButton(context),
                      const SizedBox(width: 8),
                      Expanded(child: _buildFloatingFakeInputBar(context)),
                      const SizedBox(width: 8),
                      _buildFloatingSortBy(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton.filled(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(999),
            onPressed: () =>
                showTorrentDownloadScreen(context, controller: controller),
            child: const Icon(
              CupertinoIcons.add,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    if (controller is! QBController) {
      return const SizedBox(width: 0);
    }
    final qbController = controller as QBController;
    return Obx(() {
      final hasFilters = qbController.filter.value.hasFilters;
      final activeColor = Theme.of(context).colorScheme.primary;
      final normalColor = Theme.of(context).colorScheme.onSurfaceVariant;
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: () => _openFloatingFilterSheet(context),
        child: Icon(
          CupertinoIcons.slider_horizontal_3,
          size: 20,
          color: hasFilters ? activeColor : normalColor,
        ),
      );
    });
  }

  Widget _buildFloatingFakeInputBar(BuildContext context) {
    if (controller is TransmissionController) {
      final tr = controller as TransmissionController;
      return GestureDetector(
        onTap: () => _openTrKeywordSheet(context),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.search,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() {
                  final keyword = tr.listSearchKeyword.value;
                  return Text(
                    keyword.isEmpty ? '搜索名称、分类、标签…' : keyword,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    }
    if (controller is! QBController) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          '当前下载器不支持筛选',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final qbController = controller as QBController;
    return GestureDetector(
      onTap: () => _openKeywordSheet(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(() {
                final keyword = qbController.filter.value.searchKeyword;
                return Text(
                  keyword.isEmpty ? '筛选标题、分类、标签…' : keyword,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSortBy(BuildContext context) {
    if (controller is QBController) {
      return _buildIOSSortButton(context);
    }
    if (controller is TransmissionController) {
      return _buildTrSortButton(context);
    }
    return const SizedBox.shrink();
  }

  Future<void> _openTrKeywordSheet(BuildContext context) async {
    if (controller is! TransmissionController) return;
    final tr = controller as TransmissionController;
    final inputController = TextEditingController(
      text: tr.listSearchKeyword.value,
    );
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: CupertinoSearchTextField(
              controller: inputController,
              autofocus: true,
              placeholder: '搜索名称、分类、标签…',
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    inputController.dispose();
    if (submitted == null) return;
    tr.listSearchKeyword.value = submitted.trim();
  }

  Future<void> _openKeywordSheet(BuildContext context) async {
    if (controller is! QBController) return;
    final qb = controller as QBController;
    final inputController = TextEditingController(
      text: qb.filter.value.searchKeyword,
    );
    final submitted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: insets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: CupertinoSearchTextField(
              controller: inputController,
              autofocus: true,
              placeholder: '筛选标题、分类、标签…',
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    inputController.dispose();
    if (submitted == null) return;
    qb.setFilter(qb.filter.value.copyWith(searchKeyword: submitted.trim()));
  }

  Future<void> _openFloatingFilterSheet(BuildContext context) async {
    if (controller is! QBController) return;
    final qb = controller as QBController;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.72,
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      Text('筛选', style: Theme.of(ctx).textTheme.titleMedium),
                      const Spacer(),
                      if (qb.filter.value.hasFilters)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: qb.clearFilter,
                          child: Text(
                            '清空',
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              QBFilterWidget(controller: qb),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Obx(() {
      final errorMessage = controller.errorMessage.value;

      // 使用 AnimatedSize 实现平滑的显示/隐藏动画，避免布局闪烁
      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: errorMessage.isEmpty
            ? const SizedBox.shrink()
            : Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    });
  }

  int _selectionGridCrossAxisCount(double width) {
    const hPad = 16.0;
    const slot = 150.0;
    const gap = 8.0;
    if (width < 600) return 2;
    final usable = width - hPad;
    return max(2, (usable / (slot + gap)).floor());
  }

  Widget _buildSelectionGridTile(BuildContext context, TorrentModel torrent) {
    final selected = _selectedHashes.contains(torrent.hash);
    final scheme = Theme.of(context).colorScheme;
    final name = torrent.name.trim().isEmpty ? '未命名任务' : torrent.name;
    final pct = (torrent.progress * 100).clamp(0.0, 100.0);
    final tagLine = torrent.tags.isEmpty
        ? ''
        : torrent.tags.length > 4
        ? '${torrent.tags.take(4).join(' · ')}…'
        : torrent.tags.join(' · ');
    final tSmall = Theme.of(context).textTheme.labelSmall;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _toggleHash(torrent.hash),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.22),
              width: selected ? 1.8 : 0.7,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(4, 6, 6, 6),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: selected,
                        onChanged: (_) => _toggleHash(torrent.hash),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          height: 1.2,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (torrent.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 11,
                        color: scheme.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          torrent.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tSmall?.copyWith(
                            color: scheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (tagLine.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sell_outlined,
                        size: 11,
                        color: scheme.secondary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          tagLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9.5,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '进度',
                      style: tSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: tSmall?.copyWith(
                        color: scheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 11,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        torrent.uploaded.toHumanReadableFileSize(round: 1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: torrent.progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.65,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt_rounded,
                      size: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        QBLocalizable.getStateText(torrent.state),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tSmall?.copyWith(
                          color: scheme.onSurface,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '比 ${torrent.ratio.toStringAsFixed(2)}',
                      style: tSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTorrentList(BuildContext context) {
    return Obx(() {
      final displayTorrents = filteredTorrentsList;
      final isWideLayout = MediaQuery.sizeOf(context).width > 600;
      if (_isBootstrapping.value && displayTorrents.isEmpty) {
        return _buildSkeletonList(context, isWideLayout: isWideLayout);
      }

      if (displayTorrents.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_download_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无种子',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (_selectionMode) {
        final w = MediaQuery.sizeOf(context).width;
        final n = _selectionGridCrossAxisCount(w);
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: n,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: displayTorrents.length,
            itemBuilder: (context, index) {
              return _buildSelectionGridTile(context, displayTorrents[index]);
            },
          ),
        );
      }

      if (!isWideLayout) {
        return SliverList.builder(
          itemCount: displayTorrents.length,
          itemBuilder: (context, index) {
            final torrent = displayTorrents[index];
            return TorrentListItem(
              torrent: torrent,
              controller: controller,
              selectionMode: _selectionMode,
              selected: _selectedHashes.contains(torrent.hash),
              onToggleSelected: () => _toggleHash(torrent.hash),
              onLongPressEnterSelect: () => setState(() {
                _selectionMode = true;
                _selectedHashes.add(torrent.hash);
              }),
            );
          },
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 1.8,
          ),
          itemCount: displayTorrents.length,
          itemBuilder: (context, index) {
            final torrent = displayTorrents[index];
            return TorrentListItem(
              torrent: torrent,
              controller: controller,
              selectionMode: _selectionMode,
              selected: _selectedHashes.contains(torrent.hash),
              onToggleSelected: () => _toggleHash(torrent.hash),
              onLongPressEnterSelect: () => setState(() {
                _selectionMode = true;
                _selectedHashes.add(torrent.hash);
              }),
            );
          },
        ),
      );
    });
  }

  Widget _buildSkeletonList(BuildContext context, {bool isWideLayout = false}) {
    final base = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.38);
    if (!isWideLayout) {
      return SliverList.builder(
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity, color: base),
                const SizedBox(height: 8),
                Container(height: 14, width: 180, color: base),
                const SizedBox(height: 12),
                Container(height: 8, width: double.infinity, color: base),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(height: 12, width: 68, color: base),
                    const SizedBox(width: 8),
                    Container(height: 12, width: 80, color: base),
                    const Spacer(),
                    Container(height: 12, width: 52, color: base),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.15,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: double.infinity, color: base),
                const SizedBox(height: 8),
                Container(height: 14, width: 180, color: base),
                const SizedBox(height: 12),
                Container(height: 8, width: double.infinity, color: base),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(height: 12, width: 68, color: base),
                    const SizedBox(width: 8),
                    Container(height: 12, width: 80, color: base),
                    const Spacer(),
                    Container(height: 12, width: 52, color: base),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrSortButton(BuildContext context) {
    if (controller is! TransmissionController) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      final tr = controller as TransmissionController;
      final current = tr.listSortType.value;
      final theme = Theme.of(context);
      IconData iconFor(TransmissionTorrentSortType type) {
        switch (type) {
          case TransmissionTorrentSortType.name:
            return Icons.sort_by_alpha_rounded;
          case TransmissionTorrentSortType.size:
            return Icons.storage_rounded;
          case TransmissionTorrentSortType.progress:
            return Icons.percent_rounded;
          case TransmissionTorrentSortType.dateAdded:
            return Icons.calendar_today_rounded;
          case TransmissionTorrentSortType.speed:
            return Icons.speed_rounded;
          case TransmissionTorrentSortType.seeds:
            return Icons.people_rounded;
          case TransmissionTorrentSortType.ratio:
            return Icons.compare_arrows_rounded;
        }
      }

      return PopupMenuButton<TransmissionTorrentSortType>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (v) => tr.listSortType.value = v,
        itemBuilder: (ctx) =>
            TransmissionTorrentSortType.sortTypes.map((sortType) {
              final isSelected = sortType == current;
              final iconColor = isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant;
              return PopupMenuItem<TransmissionTorrentSortType>(
                value: sortType,
                child: Row(
                  children: [
                    Icon(iconFor(sortType), size: 18, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sortType.label,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildIOSSortButton(BuildContext context) {
    if (controller is! QBController) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final qbController = controller as QBController;
      final currentSortType = qbController.torrentSortType.value;

      final theme = Theme.of(context);

      return PopupMenuButton<QBTorrentSortType>(
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (QBTorrentSortType sortType) {
          (controller as QBController).sortTorrents(sortType);
        },
        itemBuilder: (BuildContext context) =>
            QBTorrentSortType.sortTypes.map((sortType) {
              // 为每个排序类型分配图标
              IconData getSortIcon(QBTorrentSortType type) {
                switch (type) {
                  case QBTorrentSortType.size:
                    return Icons.storage_rounded;
                  case QBTorrentSortType.progress:
                    return Icons.percent_rounded;
                  case QBTorrentSortType.dateAdded:
                    return Icons.calendar_today_rounded;
                  case QBTorrentSortType.speed:
                    return Icons.speed_rounded;
                  case QBTorrentSortType.seeds:
                    return Icons.people_rounded;
                  case QBTorrentSortType.ratio:
                    return Icons.compare_arrows_rounded;
                  default:
                    return Icons.sort_rounded;
                }
              }

              final isSelected = sortType == currentSortType;
              final iconColor = isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant;

              return PopupMenuItem<QBTorrentSortType>(
                value: sortType,
                child: Row(
                  children: [
                    Icon(getSortIcon(sortType), size: 18, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sortType.label,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon(
            //   Icons.sort_rounded,
            //   size: 16,
            //   color: theme.colorScheme.primary,
            // ),
            // const SizedBox(width: 6),
            Text(
              currentSortType.label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_selectionMode) {
      return _buildSelectionAppBar(context);
    }
    return _buildNormalAppBar(context);
  }

  PreferredSizeWidget _buildSelectionAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visible = filteredTorrentsList;
    final allOn =
        visible.isNotEmpty &&
        visible.every((t) => _selectedHashes.contains(t.hash));
    return AppBar(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        _selectedHashes.isEmpty ? '选择项目' : '已选 ${_selectedHashes.length} 项',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      actions: [
        TextButton(
          onPressed: visible.isEmpty
              ? null
              : () => _toggleSelectAllVisible(visible),
          child: Text(allOn ? '取消全选' : '全选'),
        ),
        TextButton(onPressed: _exitSelectionMode, child: const Text('取消选择')),
        const SizedBox(width: 4),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleText =
        controller.config?.name ?? controller.config?.url.split('/').last ?? '';

    return AppBar(
      backgroundColor: isDark
          ? colorScheme.surface.withValues(alpha: 0.95)
          : colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 52,
      leadingWidth: 52,
      leading: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: theme.primaryColor.withAlpha(48),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Get.back(),
            child: Icon(CupertinoIcons.chevron_back, color: theme.primaryColor),
          ),
        ),
      ),
      titleSpacing: 4,
      title: Text(
        titleText,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.4,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: false,
      actions: [
        PopupMenuButton<String>(
          tooltip: '菜单',
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Icon(
            Icons.more_vert_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onSelected: (v) {
            switch (v) {
              case 'select':
                setState(() => _selectionMode = true);
                break;
              case 'log':
                if (controller is QBController) {
                  Get.to(
                    () => QBLogPage(controller: controller as QBController),
                  );
                }
                break;
              case 'rss':
                if (controller is QBController) {
                  Get.to(
                    () => QBRssListPage(controller: controller as QBController),
                  );
                }
                break;
              case 'prefs':
                if (controller is QBController) {
                  Get.to(
                    () => QBPreferencesSettingsScreen(controller: controller),
                    arguments: {'id': controller.config?.id ?? ''},
                  );
                }
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'select',
              child: Row(
                children: [
                  Icon(
                    Icons.checklist_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text('多选'),
                ],
              ),
            ),
            if (isQBittorrent && controller is QBController) ...[
              PopupMenuItem(
                value: 'log',
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    const Text('日志'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'rss',
                child: Row(
                  children: [
                    Icon(
                      Icons.rss_feed_outlined,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    const Text('RSS 订阅'),
                  ],
                ),
              ),
            ],
            if (supportsPreferences && controller is QBController)
              PopupMenuItem(
                value: 'prefs',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    const Text('设置'),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(width: 2),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Column(
          children: [
            _buildAppBarSpeedStrip(context),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? colorScheme.outline.withValues(alpha: 0.2)
                        : colorScheme.outline.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarSpeedStrip(BuildContext context) {
    return Obx(() {
      final state = controller.serverStateUniversal;
      final dl = state?.dlInfoSpeed ?? 0;
      final ul = state?.upInfoSpeed ?? 0;
      final dht = state?.dhtNodes ?? 0;
      final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      );
      return Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${dl.toHumanReadableFileSize(round: 1)}/s',
                style: textStyle,
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${ul.toHumanReadableFileSize(round: 1)}/s',
                style: textStyle,
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.public_rounded,
                size: 14,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Text('DHT $dht', style: textStyle),
            ],
          ),
        ),
      );
    });
  }
}

class _SelectionBarOp {
  const _SelectionBarOp(
    this.id,
    this.icon,
    this.label,
    this.action,
    this.enabled, {
    this.tooltip,
  });
  final String id;
  final IconData icon;
  final String label;
  final Future<void> Function() action;
  final bool enabled;
  final String? tooltip;

  String get tooltipMessage => tooltip ?? label;
}
