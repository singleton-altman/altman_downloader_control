import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_rss_item_model.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// qBittorrent RSS 列表 Widget
/// 显示 RSS feeds 和 items
class QBRssListWidget extends StatefulWidget {
  final QBController controller;

  const QBRssListWidget({super.key, required this.controller});

  @override
  State<QBRssListWidget> createState() => _QBRssListWidgetState();
}

class _QBRssListWidgetState extends State<QBRssListWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // 初始化时加载 RSS 数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshRssItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final feeds = widget.controller.rssFeeds;
      final items = widget.controller.rssItems;
      final isLoading = widget.controller.isLoadingRss.value;
      final errorMessage = widget.controller.rssErrorMessage.value;

      // 如果 RSS 功能未启用或没有数据，不显示
      if (!widget.controller.isConnected.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
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
            // 标题栏（可点击展开/收起）
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // 装饰条
                    Container(
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // RSS 图标
                    Icon(
                      Icons.rss_feed,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    // 标题
                    Expanded(
                      child: Text(
                        'RSS 订阅',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // 统计信息
                    if (!isLoading && errorMessage.isEmpty) ...[
                      Text(
                        '${feeds.length} 个订阅',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${items.length} 条内容',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // 展开/收起图标
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            // 展开的内容
            if (_isExpanded) ...[
              // 错误信息
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
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
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 加载状态
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              // RSS Feeds 列表
              if (!isLoading && errorMessage.isEmpty)
                ..._buildRssFeedsList(feeds, items),
              // 空状态
              if (!isLoading &&
                  errorMessage.isEmpty &&
                  feeds.isEmpty &&
                  items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.rss_feed_outlined,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '暂无 RSS 订阅',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _showAddRssFeedDialog,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('添加 RSS 订阅'),
                        ),
                      ],
                    ),
                  ),
                ),
              // 操作按钮
              if (!isLoading && errorMessage.isEmpty && feeds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          widget.controller.refreshRssItems();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('刷新'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _showAddRssFeedDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('添加订阅'),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      );
    });
  }

  List<Widget> _buildRssFeedsList(
    Map<String, QBRssFeedModel> feeds,
    List<QBRssItemModel> items,
  ) {
    final widgets = <Widget>[];

    if (feeds.isEmpty) {
      return widgets;
    }

    // 按 Feed 分组显示
    feeds.forEach((feedPath, feed) {
      // 使用 feed 的 getItems() 方法获取 items（优先使用 articles）
      final displayItems = feed.getItems() ?? [];

      widgets.add(_buildFeedItem(feedPath, feed, displayItems));
    });

    return widgets;
  }

  Widget _buildFeedItem(
    String feedPath,
    QBRssFeedModel feed,
    List<QBRssItemModel> items,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feed 标题和操作
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feed.title ?? feedPath,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (feed.url != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        feed.url!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 操作按钮
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  switch (value) {
                    case 'refresh':
                      widget.controller.refreshRssFeed(feedPath);
                      break;
                    case 'remove':
                      _showRemoveFeedConfirm(feedPath, feed.title ?? feedPath);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('刷新'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 统计信息
          if (feed.articleCount != null || items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.article,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${feed.articleCount ?? items.length} 条内容',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${items.where((item) => item.isRead == true).length} 已读',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Items 列表（最多显示 3 条）
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...items.take(3).map((item) => _buildRssItem(item)),
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '还有 ${items.length - 3} 条内容...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRssItem(QBRssItemModel item) {
    final isRead = item.isRead == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRead
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
            : Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isRead
              ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 已读/未读标识
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(
                  color: isRead
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? '无标题',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        color: isRead
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7)
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.category != null || item.date != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.category != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.category!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontSize: 9,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (item.date != null)
                            Text(
                              item.date!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // 操作按钮
          if (item.link != null || item.torrentURL != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.torrentURL != null)
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(item.torrentURL!);
                          // if (await canLaunchUrl(uri)) {
                          //   await launchUrl(
                          //     uri,
                          //     mode: LaunchMode.externalApplication,
                          //   );
                          // }
                        } catch (e) {
                          showToast(message: '无法打开链接: $e');
                        }
                      },
                      icon: const Icon(Icons.download, size: 14),
                      label: const Text('下载', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (item.link != null)
                    TextButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(item.link!);
                          // if (await canLaunchUrl(uri)) {
                          //   await launchUrl(
                          //     uri,
                          //     mode: LaunchMode.externalApplication,
                          //   );
                          // }
                        } catch (e) {
                          showToast(message: '无法打开链接: $e');
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('查看', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddRssFeedDialog() {
    final urlController = TextEditingController();
    final pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加 RSS 订阅'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'RSS URL',
                hintText: '请输入 RSS Feed URL',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                labelText: '路径（可选）',
                hintText: 'RSS Feed 路径',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
                showToast(message: '请输入 RSS URL');
                return;
              }
              Navigator.of(context).pop();
              await widget.controller.addRssFeed(
                url: url,
                path: pathController.text.trim().isEmpty
                    ? null
                    : pathController.text.trim(),
              );
              showToast(message: '添加成功');
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
}
