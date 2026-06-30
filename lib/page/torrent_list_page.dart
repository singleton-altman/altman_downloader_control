import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:altman_downloader_control/page/downloader_shell_chrome.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_log_page.dart';
import 'package:altman_downloader_control/page/torrent_download_screen.dart';
import 'package:altman_downloader_control/theme/downloader_cupertino_theme.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/downloader_app_bar_back_button.dart';
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

enum _SortDirectionChoice { ascending, descending }

enum _AppBarMenuAction { filter, select, log }

class DownloaderTorrentListTab extends StatefulWidget {
  const DownloaderTorrentListTab({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<DownloaderTorrentListTab> createState() =>
      _DownloaderTorrentListTabState();
}

class _DownloaderTorrentListTabState extends State<DownloaderTorrentListTab> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final DownloaderControllerProtocol controller;
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  final _isBootstrapping = true.obs;
  bool _selectionMode = false;
  final Set<String> _selectedHashes = <String>{};
  final Map<QBTorrentSortType, bool> _qbSortAscending = {};
  final Map<TransmissionTorrentSortType, bool> _trSortAscending = {};

  @override
  void initState() {
    super.initState();
    controller = Get.find<DownloaderControllerProtocol>();
    _searchController = TextEditingController();
    _syncSearchFromController();
    _searchController.addListener(_onSearchChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _setShellTabBarHidden(false);
    super.dispose();
  }

  void _setShellTabBarHidden(bool hidden) {
    if (!widget.embeddedInShell) return;
    if (DownloaderShellChrome.hideTabBar.value == hidden) return;
    DownloaderShellChrome.hideTabBar.value = hidden;
  }

  void _setSelectionMode(bool value, {bool clearSelection = false}) {
    setState(() {
      _selectionMode = value;
      if (clearSelection) {
        _selectedHashes.clear();
      }
    });
    _setShellTabBarHidden(value);
  }

  void _enterSelectionMode({String? hash}) {
    setState(() {
      if (hash != null) {
        _selectedHashes.add(hash);
      }
      _selectionMode = true;
    });
    _setShellTabBarHidden(true);
  }

  void _syncSearchFromController() {
    if (controller is QBController) {
      _searchController.text =
          (controller as QBController).filter.value.searchKeyword;
    } else if (controller is TransmissionController) {
      _searchController.text =
          (controller as TransmissionController).listSearchKeyword.value;
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      final text = _searchController.text.trim();
      if (controller is QBController) {
        final qb = controller as QBController;
        if (qb.filter.value.searchKeyword != text) {
          qb.setFilter(qb.filter.value.copyWith(searchKeyword: text));
        }
      } else if (controller is TransmissionController) {
        (controller as TransmissionController).listSearchKeyword.value = text;
      }
    });
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

  bool _defaultQbAscending(QBTorrentSortType type) {
    switch (type) {
      case QBTorrentSortType.name:
      case QBTorrentSortType.status:
        return true;
      case QBTorrentSortType.size:
      case QBTorrentSortType.progress:
      case QBTorrentSortType.dateAdded:
      case QBTorrentSortType.speed:
      case QBTorrentSortType.seeds:
      case QBTorrentSortType.ratio:
        return false;
    }
  }

  bool _defaultTransmissionAscending(TransmissionTorrentSortType type) {
    switch (type) {
      case TransmissionTorrentSortType.name:
        return true;
      case TransmissionTorrentSortType.size:
      case TransmissionTorrentSortType.progress:
      case TransmissionTorrentSortType.dateAdded:
      case TransmissionTorrentSortType.speed:
      case TransmissionTorrentSortType.seeds:
      case TransmissionTorrentSortType.ratio:
        return false;
    }
  }

  bool _isQbSortAscending(QBTorrentSortType type) {
    return _qbSortAscending.putIfAbsent(type, () => _defaultQbAscending(type));
  }

  bool _isTransmissionSortAscending(TransmissionTorrentSortType type) {
    return _trSortAscending.putIfAbsent(
      type,
      () => _defaultTransmissionAscending(type),
    );
  }

  int _withDirection(int compare, {required bool ascending}) {
    return ascending ? compare : -compare;
  }

  int _compareAddedOn(
    TorrentModel a,
    TorrentModel b, {
    required bool ascending,
  }) {
    final aVal = a.addedOn;
    final bVal = b.addedOn;
    final aValid = aVal > 0;
    final bValid = bVal > 0;
    if (!aValid && !bValid) return 0;
    if (!aValid) return 1;
    if (!bValid) return -1;
    return _withDirection(aVal.compareTo(bVal), ascending: ascending);
  }

  List<TorrentModel> get filteredTorrentsList {
    if (controller is QBController) {
      final qbController = controller as QBController;
      final sortType = qbController.torrentSortType.value;
      final ascending = _isQbSortAscending(sortType);
      final list = qbController.filter.value.hasFilters
          ? qbController.filteredTorrents
                .map((t) => t.toTorrentModel())
                .toList()
          : List<TorrentModel>.from(qbController.torrentsUniversal);
      _sortQbList(list, sortType, ascending: ascending);
      return list;
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
      _sortTransmissionList(
        list,
        tr.listSortType.value,
        ascending: _isTransmissionSortAscending(tr.listSortType.value),
      );
      return list;
    }
    return controller.torrentsUniversal;
  }

  void _sortQbList(
    List<TorrentModel> list,
    QBTorrentSortType type, {
    required bool ascending,
  }) {
    switch (type) {
      case QBTorrentSortType.name:
        list.sort(
          (a, b) => _withDirection(
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ascending: ascending,
          ),
        );
        break;
      case QBTorrentSortType.size:
        list.sort(
          (a, b) =>
              _withDirection(a.size.compareTo(b.size), ascending: ascending),
        );
        break;
      case QBTorrentSortType.progress:
        list.sort(
          (a, b) => _withDirection(
            a.progress.compareTo(b.progress),
            ascending: ascending,
          ),
        );
        break;
      case QBTorrentSortType.status:
        list.sort(
          (a, b) => _withDirection(
            a.state.toLowerCase().compareTo(b.state.toLowerCase()),
            ascending: ascending,
          ),
        );
        break;
      case QBTorrentSortType.dateAdded:
        list.sort((a, b) => _compareAddedOn(a, b, ascending: ascending));
        break;
      case QBTorrentSortType.speed:
        list.sort((a, b) {
          final sa = a.dlspeed + a.upspeed;
          final sb = b.dlspeed + b.upspeed;
          return _withDirection(sa.compareTo(sb), ascending: ascending);
        });
        break;
      case QBTorrentSortType.seeds:
        list.sort(
          (a, b) => _withDirection(
            a.numSeeds.compareTo(b.numSeeds),
            ascending: ascending,
          ),
        );
        break;
      case QBTorrentSortType.ratio:
        list.sort(
          (a, b) =>
              _withDirection(a.ratio.compareTo(b.ratio), ascending: ascending),
        );
        break;
    }
  }

  void _sortTransmissionList(
    List<TorrentModel> list,
    TransmissionTorrentSortType type, {
    required bool ascending,
  }) {
    switch (type) {
      case TransmissionTorrentSortType.name:
        list.sort(
          (a, b) => _withDirection(
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ascending: ascending,
          ),
        );
        break;
      case TransmissionTorrentSortType.size:
        list.sort(
          (a, b) => _withDirection(
            a.totalSize.compareTo(b.totalSize),
            ascending: ascending,
          ),
        );
        break;
      case TransmissionTorrentSortType.progress:
        list.sort(
          (a, b) => _withDirection(
            a.progress.compareTo(b.progress),
            ascending: ascending,
          ),
        );
        break;
      case TransmissionTorrentSortType.dateAdded:
        list.sort((a, b) => _compareAddedOn(a, b, ascending: ascending));
        break;
      case TransmissionTorrentSortType.speed:
        list.sort((a, b) {
          final sa = a.dlspeed + a.upspeed;
          final sb = b.dlspeed + b.upspeed;
          return _withDirection(sa.compareTo(sb), ascending: ascending);
        });
        break;
      case TransmissionTorrentSortType.seeds:
        list.sort(
          (a, b) => _withDirection(
            a.numSeeds.compareTo(b.numSeeds),
            ascending: ascending,
          ),
        );
        break;
      case TransmissionTorrentSortType.ratio:
        list.sort(
          (a, b) =>
              _withDirection(a.ratio.compareTo(b.ratio), ascending: ascending),
        );
        break;
    }
  }

  void _exitSelectionMode() {
    _setSelectionMode(false, clearSelection: true);
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
    if (_selectedHashes.isEmpty) {
      _setShellTabBarHidden(false);
    }
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
    final ops = _selectionBarOps();
    const primaryCount = 4;
    const wideBarW = 640.0;
    const exitButtonSize = 48.0;
    const actionSlotHeight = 44.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final primary = ops.take(primaryCount).toList();
          final secondary = ops.length > primaryCount
              ? ops.sublist(primaryCount)
              : <_SelectionBarOp>[];
          final showAllInline = constraints.maxWidth >= wideBarW;
          final inlineOps = showAllInline ? ops : primary;

          return Row(
            children: [
              _buildSelectionExitFab(context, size: exitButtonSize),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 52,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: _floatingBarDecoration(context),
                      child: Row(
                        children: [
                          for (final o in inlineOps)
                            Expanded(
                              child: _selectionBarIcon(
                                context,
                                o,
                                height: actionSlotHeight,
                              ),
                            ),
                          if (!showAllInline && secondary.isNotEmpty)
                            Expanded(
                              child: _buildSelectionMoreButton(
                                context,
                                secondary,
                                height: actionSlotHeight,
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
        },
      ),
    );
  }

  Widget _buildSelectionExitFab(BuildContext context, {double size = 52}) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Material(
          color: scheme.surface.withValues(alpha: 0.92),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
          ),
          child: InkWell(
            onTap: _exitSelectionMode,
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                Icons.close_rounded,
                size: 21,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionBarIcon(
    BuildContext context,
    _SelectionBarOp o, {
    double height = 48,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = _selectionBarIconColor(scheme, o);
    return SizedBox(
      height: height,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: o.tooltipMessage,
        icon: Icon(o.icon, size: 20, color: iconColor),
        onPressed: o.enabled
            ? () async {
                await o.action();
              }
            : null,
      ),
    );
  }

  Widget _buildSelectionMoreButton(
    BuildContext context,
    List<_SelectionBarOp> secondary, {
    double height = 48,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: PopupMenuButton<String>(
        tooltip: '更多操作',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_horiz_rounded,
          size: 21,
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
                        color: _selectionBarIconColor(menuScheme, o),
                      ),
                      const SizedBox(width: 12),
                      Text(o.label, style: Theme.of(ctx).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
          ];
        },
      ),
    );
  }

  // 辅助方法：是否支持筛选功能（仅 qBittorrent 支持）
  bool get supportsFilter => isQBittorrent;

  // 辅助方法：是否支持 RSS 功能（仅 qBittorrent 支持）
  bool get supportsRSS => isQBittorrent;

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
    return _buildPageScaffold(context);
  }

  double _bottomContentInset(BuildContext context) {
    final base = MediaQuery.paddingOf(context).bottom;
    final tabBar = widget.embeddedInShell && !_selectionMode
        ? DownloaderCupertinoTheme.shellTabBarHeight
        : 0.0;
    return base + tabBar + (_selectionMode ? 88 : 24);
  }

  Widget _buildPageScaffold(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      onEndDrawerChanged: (isOpened) {
        _setShellTabBarHidden(isOpened || _selectionMode);
      },
      endDrawer: controller is QBController
          ? _buildFilterDrawer(context)
          : null,
      appBar: _buildAppBar(context),
      floatingActionButton: _selectionMode
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: widget.embeddedInShell
                    ? DownloaderCupertinoTheme.shellTabBarHeight
                    : 0,
              ),
              child: FloatingActionButton(
                onPressed: () =>
                    showTorrentDownloadScreen(context, controller: controller),
                child: const Icon(CupertinoIcons.add),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Obx(() {
        filteredTorrentsList;
        _isBootstrapping.value;
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refreshData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildErrorMessage(context)),
                  SliverToBoxAdapter(child: _buildSearchBar(context)),
                  SliverToBoxAdapter(child: _buildListControlSummary(context)),
                  _buildTorrentListSliver(context),
                  SliverToBoxAdapter(
                    child: SizedBox(height: _bottomContentInset(context)),
                  ),
                ],
              ),
            ),
            if (_selectionMode)
              Positioned(
                left: 0,
                right: 0,
                bottom:
                    MediaQuery.paddingOf(context).bottom +
                    (widget.embeddedInShell && !_selectionMode
                        ? DownloaderCupertinoTheme.shellTabBarHeight
                        : 0) +
                    8,
                child: _buildSelectionFloatingBar(context),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterDrawer(BuildContext context) {
    final qb = controller as QBController;
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      width: min(360, MediaQuery.sizeOf(context).width * 0.88),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    Text(
                      '筛选',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                        ),
                        child: const Text('清除'),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: QBFilterWidget(controller: qb, embeddedInSheet: true),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height:
                    MediaQuery.paddingOf(context).bottom +
                    (widget.embeddedInShell
                        ? DownloaderCupertinoTheme.shellTabBarHeight
                        : 0) +
                    12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: AnimatedBuilder(
        animation: _searchController,
        builder: (context, _) {
          final hasKeyword = _searchController.text.trim().isNotEmpty;
          final fillColor = isDark
              ? const Color(0xFF24272D)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.62);

          return Container(
            height: 40,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasKeyword
                    ? scheme.primary.withValues(alpha: 0.22)
                    : Colors.transparent,
                width: 0.7,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  CupertinoIcons.search,
                  size: 17,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.62),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: CupertinoTextField.borderless(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    cursorColor: scheme.primary,
                    placeholder: controller is TransmissionController
                        ? '搜索名称、分类、标签'
                        : '搜索标题、分类、标签',
                    placeholderStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.58),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    padding: EdgeInsets.zero,
                    decoration: null,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                if (hasKeyword)
                  CupertinoButton(
                    minimumSize: const Size(34, 34),
                    padding: EdgeInsets.zero,
                    onPressed: _searchController.clear,
                    child: Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 17,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.46),
                    ),
                  )
                else
                  const SizedBox(width: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  String _activeSearchKeyword() {
    if (controller is QBController) {
      return (controller as QBController).filter.value.searchKeyword.trim();
    }
    if (controller is TransmissionController) {
      return (controller as TransmissionController).listSearchKeyword.value
          .trim();
    }
    return '';
  }

  bool _hasActiveFilters() {
    if (controller is QBController) {
      return (controller as QBController).filter.value.hasFilters;
    }
    if (controller is TransmissionController) {
      return (controller as TransmissionController).listSearchKeyword.value
          .trim()
          .isNotEmpty;
    }
    return false;
  }

  String _currentSortLabel() {
    if (controller is QBController) {
      return (controller as QBController).torrentSortType.value.label;
    }
    if (controller is TransmissionController) {
      return (controller as TransmissionController).listSortType.value.label;
    }
    return '默认';
  }

  bool _currentSortAscending() {
    if (controller is QBController) {
      final qb = controller as QBController;
      return _isQbSortAscending(qb.torrentSortType.value);
    }
    if (controller is TransmissionController) {
      final tr = controller as TransmissionController;
      return _isTransmissionSortAscending(tr.listSortType.value);
    }
    return true;
  }

  void _clearListFilters() {
    _searchController.clear();
    if (controller is QBController) {
      (controller as QBController).clearFilter();
    } else if (controller is TransmissionController) {
      (controller as TransmissionController).listSearchKeyword.value = '';
    }
  }

  Widget _buildListControlSummary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayCount = filteredTorrentsList.length;
    final totalCount = controller.torrentsUniversal.length;
    final keyword = _activeSearchKeyword();
    final hasFilters = _hasActiveFilters();
    final sortAscending = _currentSortAscending();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildSummaryPill(
              context,
              icon: Icons.format_list_bulleted_rounded,
              text: totalCount == displayCount
                  ? '$displayCount 个任务'
                  : '显示 $displayCount / $totalCount',
              color: scheme.primary,
            ),
            const SizedBox(width: 6),
            _buildSummaryPill(
              context,
              icon: sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              text: '按 ${_currentSortLabel()} ${sortAscending ? '正序' : '倒序'}',
              color: scheme.onSurfaceVariant,
            ),
            if (keyword.isNotEmpty) ...[
              const SizedBox(width: 6),
              _buildSummaryPill(
                context,
                icon: CupertinoIcons.search,
                text: keyword,
                color: scheme.secondary,
              ),
            ],
            if (hasFilters) ...[
              const SizedBox(width: 6),
              _buildClearFilterPill(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color == scheme.onSurfaceVariant
                    ? scheme.onSurfaceVariant
                    : color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearFilterPill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _clearListFilters,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: scheme.error.withValues(alpha: 0.18),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded, size: 13, color: scheme.error),
              const SizedBox(width: 5),
              Text(
                '清除筛选',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.error,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _floatingBarDecoration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? const Color(0xFF2C2C2E).withValues(alpha: 0.96)
          : scheme.surface.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.45),
        width: 0.8,
      ),
    );
  }

  PopupMenuItem<Object> _popupMenuSectionLabel(String label) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuItem<Object>(
      enabled: false,
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  PopupMenuItem<Object> _popupMenuCheckRow({
    required Object value,
    required IconData icon,
    required String label,
    required bool selected,
    Color? selectedColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final accent = selectedColor ?? scheme.primary;
    final iconColor = selected ? accent : scheme.onSurfaceVariant;
    return PopupMenuItem<Object>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? accent : scheme.onSurface,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 15,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.check_circle_rounded, size: 18, color: accent),
        ],
      ),
    );
  }

  List<PopupMenuEntry<Object>> _appBarSortMenuEntries(BuildContext context) {
    if (controller is QBController) {
      final qb = controller as QBController;
      final current = qb.torrentSortType.value;
      final ascending = _isQbSortAscending(current);
      IconData iconFor(QBTorrentSortType type) {
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

      return [
        _popupMenuSectionLabel('排序字段'),
        ...QBTorrentSortType.sortTypes.map(
          (sortType) => _popupMenuCheckRow(
            value: sortType,
            icon: iconFor(sortType),
            label: sortType.label,
            selected: sortType == current,
          ),
        ),
        const PopupMenuDivider(),
        _popupMenuSectionLabel('排序方向'),
        _popupMenuCheckRow(
          value: _SortDirectionChoice.ascending,
          icon: Icons.arrow_upward_rounded,
          label: '正序',
          selected: ascending,
        ),
        _popupMenuCheckRow(
          value: _SortDirectionChoice.descending,
          icon: Icons.arrow_downward_rounded,
          label: '倒序',
          selected: !ascending,
        ),
      ];
    }
    if (controller is TransmissionController) {
      final tr = controller as TransmissionController;
      final current = tr.listSortType.value;
      final ascending = _isTransmissionSortAscending(current);
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

      return [
        _popupMenuSectionLabel('排序字段'),
        ...TransmissionTorrentSortType.sortTypes.map(
          (sortType) => _popupMenuCheckRow(
            value: sortType,
            icon: iconFor(sortType),
            label: sortType.label,
            selected: sortType == current,
          ),
        ),
        const PopupMenuDivider(),
        _popupMenuSectionLabel('排序方向'),
        _popupMenuCheckRow(
          value: _SortDirectionChoice.ascending,
          icon: Icons.arrow_upward_rounded,
          label: '正序',
          selected: ascending,
        ),
        _popupMenuCheckRow(
          value: _SortDirectionChoice.descending,
          icon: Icons.arrow_downward_rounded,
          label: '倒序',
          selected: !ascending,
        ),
      ];
    }
    return [];
  }

  void _onAppBarMenuSelected(Object value) {
    if (value is _AppBarMenuAction) {
      switch (value) {
        case _AppBarMenuAction.filter:
          if (controller is QBController) {
            _scaffoldKey.currentState?.openEndDrawer();
          }
        case _AppBarMenuAction.select:
          _enterSelectionMode();
        case _AppBarMenuAction.log:
          if (controller is QBController) {
            Get.to(() => QBLogPage(controller: controller as QBController));
          }
      }
      return;
    }
    if (value is QBTorrentSortType) {
      (controller as QBController).sortTorrents(value);
      return;
    }
    if (value is TransmissionTorrentSortType) {
      (controller as TransmissionController).listSortType.value = value;
      return;
    }
    if (value is _SortDirectionChoice) {
      setState(() {
        if (controller is QBController) {
          final qb = controller as QBController;
          _qbSortAscending[qb.torrentSortType.value] =
              value == _SortDirectionChoice.ascending;
        } else if (controller is TransmissionController) {
          final tr = controller as TransmissionController;
          _trSortAscending[tr.listSortType.value] =
              value == _SortDirectionChoice.ascending;
        }
      });
    }
  }

  Widget _buildAppBarViewMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final hasFilters = controller is QBController
          ? (controller as QBController).filter.value.hasFilters
          : false;

      return PopupMenuButton<Object>(
        tooltip: '视图与筛选',
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: Icon(
          CupertinoIcons.slider_horizontal_3,
          size: 21,
          color: hasFilters ? scheme.primary : scheme.onSurfaceVariant,
        ),
        onSelected: _onAppBarMenuSelected,
        itemBuilder: (ctx) => [
          if (controller is QBController) ...[
            _popupMenuSectionLabel('筛选'),
            PopupMenuItem<Object>(
              value: _AppBarMenuAction.filter,
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.slider_horizontal_3,
                    size: 18,
                    color: hasFilters
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '筛选',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasFilters
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: hasFilters ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                  ),
                  if (hasFilters)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(),
          ],
          ..._appBarSortMenuEntries(ctx),
        ],
      );
    });
  }

  Widget _buildAppBarActionsMenu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<Object>(
      tooltip: '任务操作',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      icon: Icon(
        CupertinoIcons.ellipsis_circle,
        size: 22,
        color: scheme.onSurfaceVariant,
      ),
      onSelected: _onAppBarMenuSelected,
      itemBuilder: (ctx) => [
        _popupMenuSectionLabel('任务'),
        PopupMenuItem<Object>(
          value: _AppBarMenuAction.select,
          child: Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              const Text('多选', style: TextStyle(fontSize: 15)),
            ],
          ),
        ),
        if (isQBittorrent && controller is QBController) ...[
          const PopupMenuDivider(),
          _popupMenuSectionLabel('诊断'),
          PopupMenuItem<Object>(
            value: _AppBarMenuAction.log,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                const Text('日志', style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ],
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

  static const _torrentGridHPad = 16.0;
  static const _torrentGridGap = 6.0;
  static const _torrentGridMinCardWidth = 300.0;
  static const _torrentGridMainAxisExtent = 138.0;

  int _torrentGridCrossAxisCount(double width) {
    if (width < 600) return 1;
    final usable = width - _torrentGridHPad;
    return max(
      2,
      min(
        6,
        ((usable + _torrentGridGap) /
                (_torrentGridMinCardWidth + _torrentGridGap))
            .floor(),
      ),
    );
  }

  SliverGridDelegate _torrentGridDelegate(double width) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: _torrentGridCrossAxisCount(width),
      mainAxisSpacing: _torrentGridGap,
      crossAxisSpacing: _torrentGridGap,
      mainAxisExtent: _torrentGridMainAxisExtent,
    );
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
    final fill = selected
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.1),
            scheme.surface,
          )
        : scheme.surface;
    return Material(
      color: fill,
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
              width: selected ? 1.3 : 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(width: 6),
                    Icon(
                      selected
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.circle,
                      size: 16,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.45),
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

  Widget _buildTorrentListSliver(BuildContext context) {
    final displayTorrents = filteredTorrentsList;
    final isWideLayout = MediaQuery.sizeOf(context).width > 600;
    if (_isBootstrapping.value && displayTorrents.isEmpty) {
      return _buildSkeletonList(context, isWideLayout: isWideLayout);
    }

    if (displayTorrents.isEmpty) {
      final hasAnyTorrent = controller.torrentsUniversal.isNotEmpty;
      final hasFilters = _hasActiveFilters();
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasAnyTorrent
                      ? Icons.search_off_rounded
                      : Icons.cloud_download_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.28),
                ),
                const SizedBox(height: 16),
                Text(
                  hasAnyTorrent ? '没有匹配的任务' : '暂无种子',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasAnyTorrent
                      ? '换个关键词，或清除筛选条件后再看看。'
                      : '点击右下角添加任务，或下拉刷新当前下载器。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (hasFilters) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _clearListFilters,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('清除筛选'),
                  ),
                ],
              ],
            ),
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
            onLongPressEnterSelect: () =>
                _enterSelectionMode(hash: torrent.hash),
          );
        },
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid.builder(
        gridDelegate: _torrentGridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: displayTorrents.length,
        itemBuilder: (context, index) {
          final torrent = displayTorrents[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TorrentListItem(
              torrent: torrent,
              controller: controller,
              compact: true,
              selectionMode: _selectionMode,
              selected: _selectedHashes.contains(torrent.hash),
              onToggleSelected: () => _toggleHash(torrent.hash),
              onLongPressEnterSelect: () =>
                  _enterSelectionMode(hash: torrent.hash),
            ),
          );
        },
      ),
    );
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
        gridDelegate: _torrentGridDelegate(MediaQuery.sizeOf(context).width),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(10),
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
      leadingWidth: DownloaderAppBarBackButton.leadingWidth,
      leading: DownloaderAppBarBackButton(
        onPressed: () {
          _exitSelectionMode();
        },
      ),
      title: Text(
        _selectedHashes.isEmpty ? '选择项目' : '已选 ${_selectedHashes.length} 项',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: _buildSelectionActionChip(
            context: context,
            icon: allOn
                ? Icons.checklist_rtl_rounded
                : Icons.select_all_rounded,
            label: allOn ? '取消全选' : '全选',
            emphasized: allOn,
            onTap: visible.isEmpty
                ? null
                : () => _toggleSelectAllVisible(visible),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildSelectionActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool emphasized = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = emphasized
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final background = emphasized
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);
    final borderColor = emphasized
        ? colorScheme.primary.withValues(alpha: 0.22)
        : colorScheme.outlineVariant.withValues(alpha: 0.28);

    return Material(
      color: onTap == null ? background.withValues(alpha: 0.45) : background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: onTap == null
                      ? foreground.withValues(alpha: 0.55)
                      : foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
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
      leadingWidth: DownloaderAppBarBackButton.leadingWidth,
      leading: const DownloaderAppBarBackButton(),
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
        _buildAppBarViewMenu(context),
        _buildAppBarActionsMenu(context),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(31),
        child: DecoratedBox(
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
          child: _buildAppBarSummaryStrip(context),
        ),
      ),
    );
  }

  Widget _summaryDot(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '·',
        style: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
          fontSize: 11,
          height: 1,
        ),
      ),
    );
  }

  Widget _summaryMetric({
    required IconData icon,
    required Color iconColor,
    required String text,
    required TextStyle? textStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(width: 3),
        Text(text, style: textStyle),
      ],
    );
  }

  Widget _buildAppBarSummaryStrip(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: 11.5,
      height: 1,
      letterSpacing: -0.1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Obx(() {
      final state = controller.serverStateUniversal;
      final dl = state?.dlInfoSpeed ?? 0;
      final ul = state?.upInfoSpeed ?? 0;
      final dht = state?.dhtNodes ?? 0;
      final displayTorrents = filteredTorrentsList;
      var totalSize = 0;
      for (final torrent in displayTorrents) {
        totalSize += torrent.totalSize > 0 ? torrent.totalSize : torrent.size;
      }

      return SizedBox(
        height: 30,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _summaryMetric(
                icon: Icons.arrow_downward_rounded,
                iconColor: scheme.primary,
                text: '${dl.toHumanReadableFileSize(round: 1)}/s',
                textStyle: textStyle,
              ),
              _summaryDot(scheme),
              _summaryMetric(
                icon: Icons.arrow_upward_rounded,
                iconColor: scheme.secondary,
                text: '${ul.toHumanReadableFileSize(round: 1)}/s',
                textStyle: textStyle,
              ),
              _summaryDot(scheme),
              _summaryMetric(
                icon: Icons.public_rounded,
                iconColor: scheme.tertiary,
                text: 'DHT $dht',
                textStyle: textStyle,
              ),
              _summaryDot(scheme),
              _summaryMetric(
                icon: Icons.format_list_bulleted_rounded,
                iconColor: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                text: '${displayTorrents.length} 个',
                textStyle: textStyle,
              ),
              if (displayTorrents.isNotEmpty) ...[
                _summaryDot(scheme),
                _summaryMetric(
                  icon: Icons.storage_rounded,
                  iconColor: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                  text: totalSize.toHumanReadableFileSize(),
                  textStyle: textStyle,
                ),
              ],
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
