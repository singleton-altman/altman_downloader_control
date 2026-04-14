import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_rss_item_model.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_rss_item_detail_sheet.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/header.dart';
import 'package:altman_downloader_control/widget/input_dialog.dart'
    hide showMSInputDialog;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// qBittorrent RSS 列表页面
/// 使用 ExpansionTile 显示 RSS feeds 和 items
class QBRssListPage extends StatefulWidget {
  final QBController controller;

  const QBRssListPage({super.key, required this.controller});

  @override
  State<QBRssListPage> createState() => _QBRssListPageState();
}

class _QBRssListPageState extends State<QBRssListPage> {
  // 存储每个 RSS Feed 的展开状态
  final Map<String, bool> _expandedStates = {};

  @override
  void initState() {
    super.initState();
    // 初始化时加载 RSS 数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.refreshRssItems();
    });
  }

  bool _isExpanded(String feedPath) {
    return _expandedStates[feedPath] ?? false;
  }

  void _toggleExpanded(String feedPath) {
    setState(() {
      _expandedStates[feedPath] = !(_expandedStates[feedPath] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.rss_feed,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('RSS 订阅'),
          ],
        ),
        actions: [
          Obx(
            () => widget.controller.isLoadingRss.value
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      widget.controller.refreshRssItems();
                    },
                    tooltip: '刷新',
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRssFeedDialog,
            tooltip: '添加订阅',
          ),
        ],
      ),
      body: Obx(() {
        final feeds = widget.controller.rssFeeds;
        final isLoading = widget.controller.isLoadingRss.value;
        final errorMessage = widget.controller.rssErrorMessage.value;

        // 如果未连接，显示提示
        if (!widget.controller.isConnected.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '未连接到 qBittorrent',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }

        // 错误信息
        if (errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.controller.refreshRssItems();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        // 加载状态
        if (isLoading && feeds.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // 空状态
        if (!isLoading && feeds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rss_feed_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无 RSS 订阅',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddRssFeedDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('添加 RSS 订阅'),
                ),
              ],
            ),
          );
        }

        // RSS Feeds 列表 - 使用 ListView.builder 优化性能
        final feedList = feeds.entries.toList();
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: feedList.length,
          itemBuilder: (context, index) {
            // RSS Feed item
            final feedEntry = feedList[index];
            final feedPath = feedEntry.key;
            final feed = feedEntry.value;

            return _buildRssFeedItem(feedPath, feed);
          },
        );
      }),
    );
  }

  /// 构建 RSS Feed Item
  Widget _buildRssFeedItem(String feedPath, QBRssFeedModel feed) {
    final displayItems = feed.getItems() ?? [];
    final itemCount = feed.articleCount ?? displayItems.length;
    final isExpanded = _isExpanded(feedPath);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // RSS Feed Header - 使用 MSDefaultHeader
          InkWell(
            onTap: () => _toggleExpanded(feedPath),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Column(
              children: [
                MSDefaultHeader(
                  title: feed.title ?? feedPath,
                  subTitle: itemCount > 0 ? '$itemCount 条' : null,
                  useSectionStyle: true,
                  showLeadingAccent: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  withBackground: true,
                  showBottomDivider: false,
                ),
                // Feed URL 和操作按钮
                if (feed.url != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feed.url!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 展开/收起图标
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        // 操作菜单
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _showRenameFeedDialog(
                                  feedPath,
                                  feed.title ?? feedPath,
                                );
                                break;
                              case 'refresh':
                                widget.controller.refreshRssFeed(feedPath);
                                break;
                              case 'remove':
                                _showRemoveFeedConfirm(
                                  feedPath,
                                  feed.title ?? feedPath,
                                );
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('重命名'),
                                ],
                              ),
                            ),
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
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '删除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 展开/收起图标
                        IconButton(
                          icon: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                          ),
                          onPressed: () => _toggleExpanded(feedPath),
                          tooltip: isExpanded ? '收起' : '展开',
                        ),
                        // 操作菜单
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _showRenameFeedDialog(
                                  feedPath,
                                  feed.title ?? feedPath,
                                );
                                break;
                              case 'refresh':
                                widget.controller.refreshRssFeed(feedPath);
                                break;
                              case 'remove':
                                _showRemoveFeedConfirm(
                                  feedPath,
                                  feed.title ?? feedPath,
                                );
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('重命名'),
                                ],
                              ),
                            ),
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
                                  Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '删除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
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
          // 可展开的内容区域
          if (isExpanded)
            Column(
              children: [
                // RSS Items 列表 - 使用 MSDefaultHeader 作为分隔
                if (displayItems.isNotEmpty)
                  MSDefaultHeader(
                    title: '内容列表',
                    subTitle: '$itemCount 条',
                    useSectionStyle: true,
                    showBottomDivider: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                if (displayItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '暂无内容',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...displayItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildRssItem(
                      item,
                      feedPath,
                      showDivider: index > 0,
                    );
                  }),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建 RSS Item
  Widget _buildRssItem(
    QBRssItemModel item,
    String feedPath, {
    bool showDivider = false,
  }) {
    final isRead = item.isRead == true;

    return Column(
      children: [
        // Divider 分割线
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        // Item 内容
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // 如果未读，点击后标记为已读
              if (!isRead) {
                try {
                  await widget.controller.markRssAsRead(itemPath: feedPath);
                } catch (e) {
                  showToast(message: '标记已读失败: $e');
                }
              }
              // 显示详情页面
              showQBRssItemDetailSheet(
                context,
                item: item,
                qbController: widget.controller,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 发布时间 - 显示在标题顶部
                  if (item.date != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.date!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  // 标题行：状态指示器 + 标题
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 状态指示器
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6, right: 10),
                        decoration: BoxDecoration(
                          color: isRead
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // 标题
                      Expanded(
                        child: Text(
                          item.title ?? '无标题',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                color: isRead
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant
                                          .withValues(alpha: 0.8)
                                    : Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                height: 1.4,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // 分类标签
                  if (item.category != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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
