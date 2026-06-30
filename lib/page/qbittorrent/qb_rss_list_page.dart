import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_rss_item_model.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_rss_item_detail_sheet.dart';
import 'package:altman_downloader_control/theme/downloader_cupertino_theme.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/downloader_app_bar_back_button.dart';
import 'package:altman_downloader_control/widget/input_dialog.dart'
    hide showMSInputDialog;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QBRssListPage extends StatefulWidget {
  const QBRssListPage({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final QBController controller;
  final bool embedded;

  @override
  State<QBRssListPage> createState() => _QBRssListPageState();
}

class _QBRssListPageState extends State<QBRssListPage> {
  final Map<String, bool> _expandedStates = {};

  Color get _groupedBg => CupertinoDynamicColor.resolve(
    CupertinoColors.systemGroupedBackground,
    context,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshRssItems();
    });
  }

  bool _isExpanded(String feedPath) => _expandedStates[feedPath] ?? false;

  void _toggleExpanded(String feedPath) {
    setState(() {
      _expandedStates[feedPath] = !(_expandedStates[feedPath] ?? false);
    });
  }

  TextStyle _sectionHeaderStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
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

  Future<void> _onRefresh() async {
    await widget.controller.refreshRssItems();
  }

  Widget _buildToolbarActions({bool compact = false}) {
    return Obx(() {
      final loading = widget.controller.isLoadingRss.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size(compact ? 36 : 44, compact ? 36 : 44),
            onPressed: loading ? null : _onRefresh,
            child: loading
                ? const CupertinoActivityIndicator(radius: 9)
                : Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: compact ? 22 : 24,
                    color: DownloaderCupertinoTheme.primaryBlue,
                  ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size(compact ? 36 : 44, compact ? 36 : 44),
            onPressed: _showAddRssFeedDialog,
            child: Icon(
              CupertinoIcons.add,
              size: compact ? 22 : 24,
              color: DownloaderCupertinoTheme.primaryBlue,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmbeddedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'RSS',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          _buildToolbarActions(compact: true),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (widget.embedded) return null;
    return AppBar(
      backgroundColor: _groupedBg,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leadingWidth: DownloaderAppBarBackButton.leadingWidth,
      leading: const DownloaderAppBarBackButton(),
      title: const Text('RSS'),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: _buildToolbarActions(),
        ),
      ],
    );
  }

  Widget _buildCenterState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
    Color? iconColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color:
                  iconColor ??
                  CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    final feeds = widget.controller.rssFeeds;
    final isLoading = widget.controller.isLoadingRss.value;
    final errorMessage = widget.controller.rssErrorMessage.value;

    if (!widget.controller.isConnected.value) {
      return _buildCenterState(
        icon: CupertinoIcons.wifi_slash,
        title: '未连接到 qBittorrent',
      );
    }

    if (errorMessage.isNotEmpty) {
      return _buildCenterState(
        icon: CupertinoIcons.exclamationmark_circle,
        title: errorMessage,
        iconColor: DownloaderCupertinoTheme.dangerRed,
        action: CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          onPressed: _onRefresh,
          child: const Text('重试'),
        ),
      );
    }

    if (isLoading && feeds.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }

    if (!isLoading && feeds.isEmpty) {
      return _buildCenterState(
        icon: Icons.rss_feed_outlined,
        title: '暂无 RSS 订阅',
        action: CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          onPressed: _showAddRssFeedDialog,
          child: const Text('添加订阅'),
        ),
      );
    }

    final feedList = feeds.entries.toList();
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _onRefresh),
        if (widget.embedded) SliverToBoxAdapter(child: _buildEmbeddedHeader()),
        SliverToBoxAdapter(child: _buildRssOverview(feedList)),
        SliverPadding(
          padding: EdgeInsets.only(
            top: widget.embedded ? 4 : 8,
            bottom: widget.embedded
                ? DownloaderCupertinoTheme.shellTabBarHeight + 12
                : 16,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = feedList[index];
              return _buildRssFeedSection(entry.key, entry.value);
            }, childCount: feedList.length),
          ),
        ),
      ],
    );
  }

  Widget _buildRssOverview(List<MapEntry<String, QBRssFeedModel>> feeds) {
    final unreadCount = feeds.fold<int>(
      0,
      (sum, entry) =>
          sum +
          (entry.value.getItems() ?? []).where((i) => i.isRead != true).length,
    );
    final itemCount = feeds.fold<int>(
      0,
      (sum, entry) =>
          sum +
          (entry.value.articleCount ?? entry.value.getItems()?.length ?? 0),
    );
    final torrentCount = feeds.fold<int>(
      0,
      (sum, entry) =>
          sum +
          (entry.value.getItems() ?? [])
              .where((i) => i.torrentURL?.isNotEmpty == true)
              .length,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewTile(
              icon: Icons.rss_feed_rounded,
              label: '订阅',
              value: '${feeds.length}',
              color: DownloaderCupertinoTheme.ratioGold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildOverviewTile(
              icon: CupertinoIcons.circle_fill,
              label: '未读',
              value: '$unreadCount',
              color: DownloaderCupertinoTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildOverviewTile(
              icon: CupertinoIcons.arrow_down_doc,
              label: '种子',
              value: '$torrentCount/$itemCount',
              color: DownloaderCupertinoTheme.signalTeal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final fill = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    );
    final labelColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    final textColor = CupertinoColors.label.resolveFrom(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator
              .resolveFrom(context)
              .withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _feedContextMenuActions(String feedPath, String title) {
    return [
      CupertinoContextMenuAction(
        onPressed: () => _showRenameFeedDialog(feedPath, title),
        trailingIcon: CupertinoIcons.pencil,
        child: const Text('重命名'),
      ),
      CupertinoContextMenuAction(
        onPressed: () => widget.controller.refreshRssFeed(feedPath),
        trailingIcon: CupertinoIcons.arrow_clockwise,
        child: const Text('刷新'),
      ),
      CupertinoContextMenuAction(
        isDestructiveAction: true,
        onPressed: () => _showRemoveFeedConfirm(feedPath, title),
        trailingIcon: CupertinoIcons.delete,
        child: const Text('删除'),
      ),
    ];
  }

  Widget _buildCollapsedPreview(QBRssItemModel item) {
    final isRead = item.isRead == true;
    final tertiary = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final hasTorrent = item.torrentURL?.isNotEmpty == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator
              .resolveFrom(context)
              .withValues(alpha: 0.35),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isRead
                  ? CupertinoColors.systemGrey3.resolveFrom(context)
                  : DownloaderCupertinoTheme.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.date != null) ...[
                  Row(
                    children: [
                      Icon(CupertinoIcons.time, size: 12, color: tertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.date!,
                          style: TextStyle(fontSize: 12, color: tertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasTorrent)
                        _buildItemBadge(
                          '种子',
                          DownloaderCupertinoTheme.signalTeal,
                          dense: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  item.title ?? '无标题',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w500,
                    height: 1.35,
                    color: isRead
                        ? CupertinoColors.secondaryLabel.resolveFrom(context)
                        : CupertinoColors.label.resolveFrom(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTitleRow({
    required String title,
    required int itemCount,
    required TextStyle titleStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildItemBadge(
          itemCount > 0 ? '$itemCount 条' : '暂无',
          itemCount > 0
              ? DownloaderCupertinoTheme.primaryBlue
              : CupertinoColors.systemGrey.resolveFrom(context),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: titleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _contextMenuChild(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 32;
        return SizedBox(width: width, child: child);
      },
    );
  }

  Widget _buildCollapsedFeedTile({
    required String feedPath,
    required String title,
    required int itemCount,
    required int unreadCount,
    required QBRssItemModel? latestItem,
  }) {
    final fill = CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
      context,
    );
    final separator = CupertinoColors.separator.resolveFrom(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _toggleExpanded(feedPath),
        child: Container(
          color: fill,
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _leadingBadge(
                    Icons.rss_feed,
                    DownloaderCupertinoTheme.ratioGold,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeedTitleRow(
                          title: title,
                          itemCount: itemCount,
                          titleStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildItemBadge(
                                '$unreadCount 条未读',
                                DownloaderCupertinoTheme.primaryBlue,
                                dense: true,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: separator.withValues(alpha: 0.34),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
                ],
              ),
              if (latestItem != null) ...[
                const SizedBox(height: 12),
                _buildCollapsedPreview(latestItem),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedFeedHeader({
    required String feedPath,
    required String title,
    required int itemCount,
    required int unreadCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _leadingBadge(Icons.rss_feed, DownloaderCupertinoTheme.ratioGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeedTitleRow(
                  title: title,
                  itemCount: itemCount,
                  titleStyle: _sectionHeaderStyle(
                    context,
                  ).copyWith(fontSize: 18),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  _buildItemBadge(
                    '$unreadCount 条未读',
                    DownloaderCupertinoTheme.primaryBlue,
                  ),
                ],
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(36, 36),
            onPressed: () => _toggleExpanded(feedPath),
            child: Icon(
              CupertinoIcons.chevron_up,
              size: 16,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRssFeedSection(String feedPath, QBRssFeedModel feed) {
    final displayItems = feed.getItems() ?? [];
    final itemCount = feed.articleCount ?? displayItems.length;
    final isExpanded = _isExpanded(feedPath);
    final title = feed.title ?? feedPath;
    final unreadCount = displayItems.where((i) => i.isRead != true).length;
    final latestItem = displayItems.isNotEmpty ? displayItems.first : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: CupertinoListSection.insetGrouped(
          backgroundColor: _groupedBg,
          children: [
            if (!isExpanded)
              CupertinoContextMenu(
                actions: _feedContextMenuActions(feedPath, title),
                child: _contextMenuChild(
                  _buildCollapsedFeedTile(
                    feedPath: feedPath,
                    title: title,
                    itemCount: itemCount,
                    unreadCount: unreadCount,
                    latestItem: latestItem,
                  ),
                ),
              )
            else
              CupertinoContextMenu(
                actions: _feedContextMenuActions(feedPath, title),
                child: _contextMenuChild(
                  _buildExpandedFeedHeader(
                    feedPath: feedPath,
                    title: title,
                    itemCount: itemCount,
                    unreadCount: unreadCount,
                  ),
                ),
              ),
            if (isExpanded) ...[
              if (feed.url != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _leadingBadge(
                        CupertinoIcons.link,
                        DownloaderCupertinoTheme.signalTeal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '订阅地址',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              feed.url!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (displayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Center(
                    child: Text(
                      '暂无内容',
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...displayItems.asMap().entries.map(
                  (entry) => _buildRssItemRow(
                    entry.value,
                    feedPath,
                    showDivider: entry.key > 0,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemBadge(String label, Color color, {bool dense = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(dense ? 5 : 6),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: dense ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }

  Future<void> _openRssItem(QBRssItemModel item, String feedPath) async {
    final isRead = item.isRead == true;
    if (!isRead) {
      try {
        await widget.controller.markRssAsRead(itemPath: feedPath);
      } catch (e) {
        showToast(message: '标记已读失败: $e');
      }
    }
    if (!mounted) return;
    showQBRssItemDetailSheet(
      context,
      item: item,
      qbController: widget.controller,
    );
  }

  Widget _buildRssItemRow(
    QBRssItemModel item,
    String feedPath, {
    required bool showDivider,
  }) {
    final isRead = item.isRead == true;
    final hasTorrent = item.torrentURL?.isNotEmpty == true;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final tertiary = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final rowFill = isRead
        ? Colors.transparent
        : DownloaderCupertinoTheme.primaryBlue.withValues(alpha: 0.035);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openRssItem(item, feedPath),
            child: Container(
              color: rowFill,
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (item.date != null) ...[
                              Icon(
                                CupertinoIcons.time,
                                size: 12,
                                color: tertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.date!,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: secondary,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else
                              const Spacer(),
                            if (!isRead)
                              _buildItemBadge(
                                '未读',
                                DownloaderCupertinoTheme.primaryBlue,
                                dense: true,
                              ),
                            if (hasTorrent) ...[
                              if (!isRead) const SizedBox(width: 6),
                              _buildItemBadge(
                                '种子',
                                DownloaderCupertinoTheme.signalTeal,
                                dense: true,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.title ?? '无标题',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: isRead
                                ? FontWeight.w400
                                : FontWeight.w700,
                            height: 1.32,
                            color: isRead ? secondary : label,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((item.author != null && item.author!.isNotEmpty) ||
                            (item.category != null &&
                                item.category!.isNotEmpty)) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (item.author != null &&
                                  item.author!.isNotEmpty)
                                _buildRssMetaText(
                                  icon: CupertinoIcons.person,
                                  text: item.author!,
                                  color: tertiary,
                                ),
                              if (item.category != null &&
                                  item.category!.isNotEmpty)
                                _buildItemBadge(
                                  item.category!,
                                  DownloaderCupertinoTheme.ratioGold,
                                  dense: true,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 22),
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRssMetaText({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 210),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = Obx(() => _buildBodyContent());

    if (widget.embedded) {
      return Material(
        color: _groupedBg,
        child: SafeArea(bottom: false, child: body),
      );
    }

    return Scaffold(
      backgroundColor: _groupedBg,
      appBar: _buildAppBar(),
      body: Material(color: _groupedBg, child: body),
    );
  }

  void _showAddRssFeedDialog() {
    final urlController = TextEditingController();
    final pathController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => MSDialog(
        title: '添加 RSS 订阅',
        titleIcon: Icons.rss_feed,
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                style: Get.textTheme.bodySmall,
                controller: urlController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'RSS URL',
                  hintText: '请输入 RSS Feed URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入 RSS URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: Get.textTheme.bodySmall,
                controller: pathController,
                decoration: InputDecoration(
                  labelText: '路径（可选）',
                  hintText: 'RSS Feed 路径',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final url = urlController.text.trim();
                Navigator.of(context).pop();
                await widget.controller.addRssFeed(
                  url: url,
                  path: pathController.text.trim().isEmpty
                      ? null
                      : pathController.text.trim(),
                );
                showToast(message: '添加成功');
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showRemoveFeedConfirm(String feedPath, String feedTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 RSS 订阅:\n$feedTitle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.controller.removeRssFeed(feedPath);
              showToast(message: '删除成功');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameFeedDialog(
    String feedPath,
    String currentName,
  ) async {
    final result = await showMSInputDialog(
      context,
      title: '重命名 RSS 订阅',
      labelText: '新名称',
      hintText: '请输入新的 RSS Feed 名称',
      initialValue: currentName,
      icon: Icons.edit,
      confirmText: '确定',
      cancelText: '取消',
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return '请输入新名称';
        }
        if (trimmed == currentName) {
          return '新名称不能与当前名称相同';
        }
        return null;
      },
    );

    if (result != null && result.isNotEmpty) {
      final trimmedName = result.trim();
      if (trimmedName != currentName) {
        final success = await widget.controller.renameRssFeed(
          itemPath: feedPath,
          destPath: trimmedName,
        );
        if (success) {
          showToast(message: '重命名成功');
        } else {
          showToast(message: '重命名失败');
        }
      }
    }
  }
}
