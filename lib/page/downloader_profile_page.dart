import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/controller/transmission/transmission_controller.dart';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/model/server_state_model.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_preferences_settings_page.dart';
import 'package:altman_downloader_control/utils/string_utils.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloaderProfilePage extends StatefulWidget {
  const DownloaderProfilePage({super.key, required this.controller});

  final DownloaderControllerProtocol controller;

  @override
  State<DownloaderProfilePage> createState() => _DownloaderProfilePageState();
}

class _DownloaderProfilePageState extends State<DownloaderProfilePage> {
  Map<String, dynamic> _categories = {};
  List<String> _tags = [];

  DownloaderControllerProtocol get c => widget.controller;

  DownloaderConfig? get _cfg => c.config;

  bool get _isQb => c is QBController;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await c.refreshVersion();
      if (c is QBController) {
        final q = c as QBController;
        await q.refreshPreferences();
        final cats = await q.getCategories();
        final tagList = await q.getAllTags();
        if (!mounted) return;
        setState(() {
          _categories = cats;
          _tags = tagList;
        });
      } else {
        await c.refreshTorrents();
        if (!mounted) return;
        _applyTorrentDerivedLabels();
      }
    } catch (e) {
      failToast(message: e.toString());
    }
  }

  void _applyTorrentDerivedLabels() {
    final catMap = <String, dynamic>{};
    final tagSet = <String>{};
    for (final t in c.torrentsUniversal) {
      if (t.category.isNotEmpty) {
        catMap.putIfAbsent(t.category, () => <String, dynamic>{});
      }
      tagSet.addAll(t.tags);
    }
    setState(() {
      _categories = catMap;
      _tags = tagSet.toList()..sort();
    });
  }

  void _openQbSettings() {
    if (c is! QBController) return;
    Get.to(() => QBPreferencesSettingsScreen(controller: c as QBController));
  }

  String _limitKbps(int bytesPerSec) {
    if (bytesPerSec <= 0) return '无限制';
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  String? _categoryPath(dynamic raw) {
    if (raw is Map) {
      final p = raw['savePath'];
      if (p is String && p.isNotEmpty) return p;
    }
    return null;
  }

  Widget _sectionTitle(
    BuildContext context,
    String title, {
    String? subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 15,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 13),
              child: Text(
                subtitle,
                style: tt.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionShell(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.4 : 0.72,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.45),
            width: 0.7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _kvRow(BuildContext context, String label, String value) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 114,
            child: Text(
              label,
              style: tt.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _speedRows(
    BuildContext context,
    QBPreferencesModel? pref,
    ServerStateModel? state,
  ) {
    final rows = <Widget>[];
    if (pref != null) {
      rows.add(_kvRow(context, '下载限速', _limitKbps(pref.dlLimit)));
      rows.add(_kvRow(context, '上传限速', _limitKbps(pref.upLimit)));
      rows.add(_kvRow(context, '备用下载', _limitKbps(pref.altDlLimit)));
      rows.add(_kvRow(context, '备用上传', _limitKbps(pref.altUpLimit)));
    } else if (state != null) {
      rows.add(_kvRow(context, '下载限速', _limitKbps(state.dlRateLimit)));
      rows.add(_kvRow(context, '上传限速', _limitKbps(state.upRateLimit)));
    }
    if (state != null) {
      rows.add(
        _kvRow(
          context,
          '当前下行',
          '${state.dlInfoSpeed.toHumanReadableFileSize(round: 1)}/s',
        ),
      );
      rows.add(
        _kvRow(
          context,
          '当前上行',
          '${state.upInfoSpeed.toHumanReadableFileSize(round: 1)}/s',
        ),
      );
      if (state.useAltSpeedLimits) {
        rows.add(_kvRow(context, '备用限速', '已启用'));
      }
    }
    if (rows.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '暂无数据',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _chipsArea(
    BuildContext context, {
    required bool empty,
    required String emptyText,
    required List<Widget> chips,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: empty
          ? Text(
              emptyText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          : Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载器信息'),
        actions: [
          if (_isQb)
            IconButton(
              tooltip: '服务器设置',
              icon: Icon(Icons.tune_rounded, color: scheme.primary),
              onPressed: _openQbSettings,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Obx(() {
                final online = c.isConnected.value;
                final t = Theme.of(context);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Material(
                    elevation: 0,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(
                              alpha: isDark ? 0.22 : 0.14,
                            ),
                            scheme.surfaceContainerHighest.withValues(
                              alpha: isDark ? 0.55 : 0.85,
                            ),
                          ],
                        ),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(
                            alpha: isDark ? 0.35 : 0.5,
                          ),
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: scheme.surface.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              online
                                  ? Icons.hub_rounded
                                  : Icons.portable_wifi_off_rounded,
                              color: online
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _cfg?.name?.isNotEmpty == true
                                      ? _cfg!.name!
                                      : '下载器',
                                  style: t.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: online
                                            ? Colors.green.shade500
                                            : scheme.outline,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      online ? '已连接' : '未连接',
                                      style: t.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            SliverToBoxAdapter(child: _sectionTitle(context, '端点')),
            SliverToBoxAdapter(
              child: _sectionShell(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _kvRow(context, '类型', _cfg?.type.name ?? '—'),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    _kvRow(context, '地址', _cfg?.url ?? '—'),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    _kvRow(
                      context,
                      '账户',
                      (_cfg?.username.isEmpty ?? true) ? '—' : _cfg!.username,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _sectionTitle(context, '软件')),
            SliverToBoxAdapter(
              child: _sectionShell(
                context,
                child: _isQb
                    ? Obx(
                        () => _kvRow(
                          context,
                          '版本',
                          (c as QBController).version.value ?? '—',
                        ),
                      )
                    : c is TransmissionController
                    ? Obx(
                        () => _kvRow(
                          context,
                          '版本',
                          (c as TransmissionController).version.value ?? '—',
                        ),
                      )
                    : _kvRow(context, '版本', '—'),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() {
                final st = c.serverStateUniversal;
                List<Widget> body = [];
                if (_isQb) {
                  final p = (c as QBController).preferences.value;
                  body = [..._speedRows(context, p, st)];
                  if (p != null) {
                    body.add(
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    );
                    body.add(_kvRow(context, '监听端口', '${p.listenPort}'));
                  }
                } else {
                  body = _speedRows(context, null, st);
                }
                if (st != null && st.freeSpaceOnDisk > 0) {
                  body.add(
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  );
                  body.add(
                    _kvRow(
                      context,
                      '磁盘剩余',
                      st.freeSpaceOnDisk.toHumanReadableFileSize(),
                    ),
                  );
                }
                if (st != null && st.dhtNodes > 0) {
                  body.add(
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  );
                  body.add(_kvRow(context, 'DHT 节点', '${st.dhtNodes}'));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle(context, '状态与限速'),
                    _sectionShell(context, child: Column(children: body)),
                  ],
                );
              }),
            ),
            SliverToBoxAdapter(
              child: _sectionTitle(
                context,
                '分类',
                subtitle: _isQb ? null : '从当前任务列表汇总',
              ),
            ),
            SliverToBoxAdapter(
              child: _sectionShell(
                context,
                child: _chipsArea(
                  context,
                  empty: _categories.isEmpty,
                  emptyText: '暂无分类',
                  chips: (_categories.keys.toList()..sort()).map((k) {
                    final path = _categoryPath(_categories[k]);
                    final chip = Chip(
                      label: Text(k),
                      backgroundColor:
                          scheme.secondaryContainer.withValues(alpha: 0.55),
                      side: BorderSide(
                        color:
                            scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                    if (path != null && path.isNotEmpty) {
                      return Tooltip(message: path, child: chip);
                    }
                    return chip;
                  }).toList(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _sectionTitle(
                context,
                '标签',
                subtitle: _isQb ? null : '从当前任务列表汇总',
              ),
            ),
            SliverToBoxAdapter(
              child: _sectionShell(
                context,
                child: _chipsArea(
                  context,
                  empty: _tags.isEmpty,
                  emptyText: '暂无标签',
                  chips: _tags
                      .map(
                        (t) => Chip(
                          label: Text(t),
                          backgroundColor:
                              scheme.tertiaryContainer.withValues(alpha: 0.5),
                          side: BorderSide(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}
