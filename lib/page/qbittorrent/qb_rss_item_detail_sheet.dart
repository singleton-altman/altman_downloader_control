import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_rss_item_model.dart';
import 'package:altman_downloader_control/page/torrent_download_screen.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// 显示 RSS Item 详情页面的 Modal Sheet
void showQBRssItemDetailSheet(
  BuildContext context, {
  required QBRssItemModel item,
  QBController? qbController,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) =>
        QBRssItemDetailSheet(item: item, qbController: qbController),
  );
}

class QBRssItemDetailSheet extends StatelessWidget {
  final QBRssItemModel item;
  final QBController? qbController;

  const QBRssItemDetailSheet({
    super.key,
    required this.item,
    this.qbController,
  });

  /// 解析 HTML 中的图片 URL
  List<String> _extractImageUrls(String? html) {
    if (html == null || html.isEmpty) return [];

    final List<String> imageUrls = [];
    final RegExp imgRegex = RegExp(
      r'<img[^>]+src=(["'
      '])([^"'
      ']+)1',
      caseSensitive: false,
    );

    final matches = imgRegex.allMatches(html);
    for (final match in matches) {
      final url = match.group(2);
      if (url != null && url.isNotEmpty) {
        imageUrls.add(url);
      }
    }

    return imageUrls;
  }

  /// 打开 Web 链接
  Future<void> _openWebLink() async {
    if (item.link == null || item.link!.isEmpty) {
      showToast(message: '链接不可用');
      return;
    }

    // try {
    //   final uri = Uri.parse(item.link!);
    //   if (await canLaunchUrl(uri)) {
    //     await launchUrl(uri, mode: LaunchMode.externalApplication);
    //   } else {
    //     showToast(message: '无法打开链接');
    //   }
    // } catch (e) {
    //   showToast(message: '打开链接失败: $e');
    // }
  }

  /// 打开下载页面
  void _openDownloadPage(BuildContext context) {
    if (item.torrentURL == null || item.torrentURL!.isEmpty) {
      showToast(message: '下载链接不可用');
      return;
    }

    if (qbController == null) {
      showToast(message: '下载器不可用');
      return;
    }

    // 关闭当前页面
    Navigator.of(context).pop();

    // 打开下载页面
    showTorrentDownloadScreen(
      context,
      downloadUrls: item.torrentURL,
      controller: qbController!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = _extractImageUrls(item.description);
    final hasDescription =
        item.description != null && item.description!.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 顶部拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.title != null)
                            Text(
                              item.title!,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (item.date != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.6),
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
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 下载按钮
                    if (item.torrentURL != null &&
                        item.torrentURL!.isNotEmpty &&
                        qbController != null)
                      IconButton(
                        icon: const Icon(Icons.download, size: 20),
                        tooltip: '下载',
                        onPressed: () => _openDownloadPage(context),
                      ),
                    // 右上角按钮：前往 Web 查看详情
                    if (item.link != null && item.link!.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 20),
                        tooltip: '前往 Web 查看详情',
                        onPressed: _openWebLink,
                      ),
                    // 关闭按钮
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 分类标签
                      if (item.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category!,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // 图片列表
                      if (imageUrls.isNotEmpty) ...[
                        ...imageUrls.map(
                          (url) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                progressIndicatorBuilder:
                                    (context, url, progress) => Container(
                                      height: 200,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainer
                                          .withValues(alpha: 0.3),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: progress.progress,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, url, error) => Container(
                                  height: 200,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer
                                      .withValues(alpha: 0.3),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '图片加载失败',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Description 内容（使用 HTML Widget 渲染）
                      if (hasDescription) ...[
                        HtmlWidget(
                          item.description!,
                          textStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 14, height: 1.6),
                          // 自定义样式
                          customStylesBuilder: (element) {
                            if (element.localName == 'img') {
                              return {'max-width': '100%', 'height': 'auto'};
                            }
                            return null;
                          },
                          // 自定义 Widget 构建器（用于图片）
                          customWidgetBuilder: (element) {
                            if (element.localName == 'img') {
                              final src = element.attributes['src'];
                              if (src != null && src.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: src,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      progressIndicatorBuilder:
                                          (context, url, progress) => Container(
                                            height: 200,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainer
                                                .withValues(alpha: 0.3),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: progress.progress,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            height: 200,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainer
                                                .withValues(alpha: 0.3),
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image,
                                                    size: 48,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    '图片加载失败',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant
                                                                  .withValues(
                                                                    alpha: 0.6,
                                                                  ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              }
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无描述内容',
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
                        ),
                      ],
                      // 底部间距
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
