import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/controller/transmission/transmission_controller.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_preferences_settings_page.dart';
import 'package:altman_downloader_control/theme/downloader_cupertino_theme.dart';
import 'package:altman_downloader_control/utils/string_utils.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/downloader_app_bar_back_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloaderProfilePage extends StatefulWidget {
  const DownloaderProfilePage({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final DownloaderControllerProtocol controller;
  final bool embedded;

  @override
  State<DownloaderProfilePage> createState() => _DownloaderProfilePageState();
}

class _DownloaderProfilePageState extends State<DownloaderProfilePage> {
  Map<String, dynamic> _categories = {};
  List<String> _tags = [];

  DownloaderControllerProtocol get c => widget.controller;

  DownloaderConfig? get _cfg => c.config;

  bool get _isQb => c is QBController;

  Color get _groupedBg => CupertinoDynamicColor.resolve(
    CupertinoColors.systemGroupedBackground,
    context,
  );

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

  Future<void> _openQbSettings() async {
    if (c is! QBController) return;
    await Get.to(
      () => QBPreferencesSettingsScreen(controller: c as QBController),
    );
    if (mounted) {
      await _refresh();
    }
  }

  String _limitKbps(int bytesPerSec) {
    if (bytesPerSec <= 0) return '无限制';
    return '${(bytesPerSec / 1024).toStringAsFixed(0)} KB/s';
  }

  TextStyle _sectionHeaderStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
  }

  TextStyle _valueStyle(BuildContext context, {bool mono = false}) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
      fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
    );
  }

  Widget _leadingBadge(IconData icon, Color color) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }

  Widget _listTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool mono = false,
  }) {
    return CupertinoListTile.notched(
      leading: _leadingBadge(icon, iconColor),
      title: Text(title, style: const TextStyle(fontSize: 17)),
      additionalInfo: SelectableText(
        value,
        style: _valueStyle(context, mono: mono),
      ),
    );
  }

  Widget _buildLargeTitle() {
    if (!widget.embedded) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 10, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '信息',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          if (_buildSettingsAction() case final action?) action,
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Obx(() {
      final online = c.isConnected.value;
      final name = _cfg?.name?.isNotEmpty == true ? _cfg!.name! : '下载器';
      final typeLabel = _cfg?.type == DownloaderType.qbittorrent
          ? 'qBittorrent'
          : 'Transmission';
      final statusColor = online
          ? DownloaderCupertinoTheme.signalTeal
          : CupertinoColors.systemGrey.resolveFrom(context);

      return Padding(
        padding: EdgeInsets.fromLTRB(20, widget.embedded ? 12 : 16, 20, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: DownloaderCupertinoTheme.primaryBlue.withValues(
                  alpha: 0.14,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isQb
                    ? CupertinoIcons.arrow_down_circle_fill
                    : CupertinoIcons.tray_fill,
                size: 32,
                color: DownloaderCupertinoTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        online ? '已连接' : '未连接',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLiveStatsSection() {
    return Obx(() {
      final st = c.serverStateUniversal;
      if (st == null) return const SizedBox.shrink();

      return CupertinoListSection.insetGrouped(
        backgroundColor: _groupedBg,
        header: Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 6, top: 4),
          child: Text('实时状态', style: _sectionHeaderStyle(context)),
        ),
        children: [
          _listTile(
            icon: CupertinoIcons.arrow_down,
            iconColor: DownloaderCupertinoTheme.primaryBlue,
            title: '下行速度',
            value: '${st.dlInfoSpeed.toHumanReadableFileSize(round: 1)}/s',
            mono: true,
          ),
          _listTile(
            icon: CupertinoIcons.arrow_up,
            iconColor: DownloaderCupertinoTheme.signalTeal,
            title: '上行速度',
            value: '${st.upInfoSpeed.toHumanReadableFileSize(round: 1)}/s',
            mono: true,
          ),
          if (st.freeSpaceOnDisk > 0)
            _listTile(
              icon: CupertinoIcons.archivebox_fill,
              iconColor: DownloaderCupertinoTheme.ratioGold,
              title: '磁盘剩余',
              value: st.freeSpaceOnDisk.toHumanReadableFileSize(),
              mono: true,
            ),
          if (st.dhtNodes > 0)
            _listTile(
              icon: CupertinoIcons.globe,
              iconColor: Theme.of(context).colorScheme.secondary,
              title: 'DHT 节点',
              value: '${st.dhtNodes}',
              mono: true,
            ),
        ],
      );
    });
  }

  Widget _buildEndpointSection() {
    return CupertinoListSection.insetGrouped(
      backgroundColor: _groupedBg,
      header: Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 6, top: 8),
        child: Text('端点', style: _sectionHeaderStyle(context)),
      ),
      children: [
        _listTile(
          icon: CupertinoIcons.square_stack_3d_up_fill,
          iconColor: DownloaderCupertinoTheme.primaryBlue,
          title: '类型',
          value: _cfg?.type.name ?? '—',
        ),
        _listTile(
          icon: CupertinoIcons.link,
          iconColor: DownloaderCupertinoTheme.signalTeal,
          title: '地址',
          value: _cfg?.url ?? '—',
          mono: true,
        ),
        _listTile(
          icon: CupertinoIcons.person_fill,
          iconColor: DownloaderCupertinoTheme.ratioGold,
          title: '账户',
          value: (_cfg?.username.isEmpty ?? true) ? '—' : _cfg!.username,
        ),
      ],
    );
  }

  Widget _buildSoftwareSection() {
    Widget versionTile() {
      if (_isQb) {
        return Obx(
          () => _listTile(
            icon: CupertinoIcons.info_circle_fill,
            iconColor: DownloaderCupertinoTheme.primaryBlue,
            title: '版本',
            value: (c as QBController).version.value ?? '—',
            mono: true,
          ),
        );
      }
      if (c is TransmissionController) {
        return Obx(
          () => _listTile(
            icon: CupertinoIcons.info_circle_fill,
            iconColor: DownloaderCupertinoTheme.primaryBlue,
            title: '版本',
            value: (c as TransmissionController).version.value ?? '—',
            mono: true,
          ),
        );
      }
      return _listTile(
        icon: CupertinoIcons.info_circle_fill,
        iconColor: DownloaderCupertinoTheme.primaryBlue,
        title: '版本',
        value: '—',
      );
    }

    return CupertinoListSection.insetGrouped(
      backgroundColor: _groupedBg,
      header: Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 6, top: 8),
        child: Text('软件', style: _sectionHeaderStyle(context)),
      ),
      children: [versionTile()],
    );
  }

  Widget _buildLimitsSection() {
    return Obx(() {
      final st = c.serverStateUniversal;
      final pref = _isQb ? (c as QBController).preferences.value : null;
      final children = <Widget>[];

      if (pref != null) {
        children.addAll([
          _listTile(
            icon: CupertinoIcons.arrow_down,
            iconColor: DownloaderCupertinoTheme.primaryBlue,
            title: '下载限速',
            value: _limitKbps(pref.dlLimit),
            mono: true,
          ),
          _listTile(
            icon: CupertinoIcons.arrow_up,
            iconColor: DownloaderCupertinoTheme.signalTeal,
            title: '上传限速',
            value: _limitKbps(pref.upLimit),
            mono: true,
          ),
          _listTile(
            icon: CupertinoIcons.arrow_down_to_line,
            iconColor: DownloaderCupertinoTheme.ratioGold,
            title: '备用下载',
            value: _limitKbps(pref.altDlLimit),
            mono: true,
          ),
          _listTile(
            icon: CupertinoIcons.arrow_up_to_line,
            iconColor: DownloaderCupertinoTheme.ratioGold,
            title: '备用上传',
            value: _limitKbps(pref.altUpLimit),
            mono: true,
          ),
          _listTile(
            icon: CupertinoIcons.antenna_radiowaves_left_right,
            iconColor: Theme.of(context).colorScheme.secondary,
            title: '监听端口',
            value: '${pref.listenPort}',
            mono: true,
          ),
        ]);
      } else if (st != null) {
        children.addAll([
          _listTile(
            icon: CupertinoIcons.arrow_down,
            iconColor: DownloaderCupertinoTheme.primaryBlue,
            title: '下载限速',
            value: _limitKbps(st.dlRateLimit),
            mono: true,
          ),
          _listTile(
            icon: CupertinoIcons.arrow_up,
            iconColor: DownloaderCupertinoTheme.signalTeal,
            title: '上传限速',
            value: _limitKbps(st.upRateLimit),
            mono: true,
          ),
        ]);
      }

      if (st != null && st.useAltSpeedLimits) {
        children.add(
          _listTile(
            icon: CupertinoIcons.gauge,
            iconColor: DownloaderCupertinoTheme.ratioGold,
            title: '备用限速',
            value: '已启用',
          ),
        );
      }

      if (children.isEmpty) {
        children.add(
          CupertinoListTile.notched(
            title: const Text('暂无数据', style: TextStyle(fontSize: 17)),
          ),
        );
      }

      return CupertinoListSection.insetGrouped(
        backgroundColor: _groupedBg,
        header: Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 6, top: 8),
          child: Text('限速', style: _sectionHeaderStyle(context)),
        ),
        children: children,
      );
    });
  }

  Widget _profileChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsGroupedSection({
    required String title,
    String? hint,
    required List<String> items,
    required IconData icon,
    required Color color,
    required String emptyLabel,
  }) {
    return CupertinoListSection.insetGrouped(
      backgroundColor: _groupedBg,
      header: Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 6, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _sectionHeaderStyle(context)),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ],
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: items.isEmpty
              ? Text(
                  emptyLabel,
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: items
                      .map(
                        (item) =>
                            _profileChip(icon: icon, label: item, color: color),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final keys = _categories.keys.toList()..sort();
    return _buildChipsGroupedSection(
      title: '分类',
      hint: _isQb ? null : '从当前任务列表汇总',
      items: keys.cast<String>(),
      icon: CupertinoIcons.folder_fill,
      color: DownloaderCupertinoTheme.signalTeal,
      emptyLabel: '暂无分类',
    );
  }

  Widget _buildTagsSection() {
    return _buildChipsGroupedSection(
      title: '标签',
      hint: _isQb ? null : '从当前任务列表汇总',
      items: _tags,
      icon: CupertinoIcons.tag_fill,
      color: DownloaderCupertinoTheme.ratioGold,
      emptyLabel: '暂无标签',
    );
  }

  Widget? _buildSettingsAction() {
    if (!_isQb) return null;
    return CupertinoButton(
      padding: const EdgeInsetsDirectional.only(end: 12),
      onPressed: _openQbSettings,
      child: Icon(
        CupertinoIcons.slider_horizontal_3,
        size: 26,
        color: DownloaderCupertinoTheme.primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refresh),
        SliverToBoxAdapter(child: _buildLargeTitle()),
        SliverToBoxAdapter(child: _buildHeroHeader()),
        SliverToBoxAdapter(child: _buildLiveStatsSection()),
        SliverToBoxAdapter(child: _buildEndpointSection()),
        SliverToBoxAdapter(child: _buildSoftwareSection()),
        SliverToBoxAdapter(child: _buildLimitsSection()),
        SliverToBoxAdapter(child: _buildCategoriesSection()),
        SliverToBoxAdapter(child: _buildTagsSection()),
        SliverToBoxAdapter(
          child: SizedBox(
            height: widget.embedded
                ? DownloaderCupertinoTheme.shellTabBarHeight + 24
                : 32,
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: _groupedBg,
        child: SafeArea(bottom: false, child: scrollView),
      );
    }

    return Scaffold(
      backgroundColor: _groupedBg,
      appBar: AppBar(
        backgroundColor: _groupedBg,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leadingWidth: DownloaderAppBarBackButton.leadingWidth,
        leading: const DownloaderAppBarBackButton(),
        title: const Text('信息'),
        actions: [_buildSettingsAction()].whereType<Widget>().toList(),
      ),
      body: Material(color: _groupedBg, child: scrollView),
    );
  }
}
