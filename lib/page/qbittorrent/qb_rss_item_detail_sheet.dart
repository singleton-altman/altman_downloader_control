import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_rss_item_model.dart';
import 'package:altman_downloader_control/page/torrent_download_screen.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

/// 显示 RSS Item 详情页面的 Modal Sheet
void showQBRssItemDetailSheet(
  BuildContext context, {
  required QBRssItemModel item,
  QBController? qbController,
}) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
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

  List<String> _extractImageUrls(String? html) {
    if (html == null || html.isEmpty) return [];

    final imageUrls = <String>[];
    final imgRegex = RegExp(
      r'''<img[^>]+src=["']([^"']+)["']''',
      caseSensitive: false,
    );

    for (final match in imgRegex.allMatches(html)) {
      final url = match.group(1);
      if (url != null && url.isNotEmpty) {
        imageUrls.add(url);
      }
    }

    return imageUrls;
  }

  Future<void> _copyWebLink() async {
    if (item.link == null || item.link!.isEmpty) {
      showToast(message: '链接不可用');
      return;
    }

    await Clipboard.setData(ClipboardData(text: item.link!));
    showToast(message: '已复制 Web 链接');
  }

  void _openDownloadPage(BuildContext context) {
    if (item.torrentURL == null || item.torrentURL!.isEmpty) {
      showToast(message: '下载链接不可用');
      return;
    }

    if (qbController == null) {
      showToast(message: '下载器不可用');
      return;
    }

    Navigator.of(context).pop();
    showTorrentDownloadScreen(
      context,
      downloadUrls: item.torrentURL,
      controller: qbController!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = _extractImageUrls(item.description).length;
    final hasDescription =
        item.description != null && item.description!.trim().isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.36,
      maxChildSize: 1,
      expand: false,
      builder: (context, scrollController) {
        final scheme = Theme.of(context).colorScheme;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Material(
            color: scheme.surface,
            child: Column(
              children: [
                _buildSheetHandle(context),
                _buildHeader(context, imageCount: imageCount),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: hasDescription
                        ? _buildDescription(context)
                        : _buildEmptyDescription(context),
                  ),
                ),
                _buildActionBar(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required int imageCount}) {
    final scheme = Theme.of(context).colorScheme;
    final hasTorrent = item.torrentURL?.isNotEmpty == true;
    final hasLink = item.link?.isNotEmpty == true;
    final title = item.title?.trim().isNotEmpty == true ? item.title! : '无标题';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.rss_feed_rounded, color: scheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (item.date?.isNotEmpty == true)
                      _buildMetaChip(
                        context,
                        icon: Icons.schedule_rounded,
                        text: item.date!,
                        color: scheme.onSurfaceVariant,
                      ),
                    if (item.category?.isNotEmpty == true)
                      _buildMetaChip(
                        context,
                        icon: Icons.label_outline_rounded,
                        text: item.category!,
                        color: scheme.tertiary,
                      ),
                    if (hasTorrent)
                      _buildMetaChip(
                        context,
                        icon: Icons.download_rounded,
                        text: '种子',
                        color: scheme.secondary,
                      ),
                    if (hasLink)
                      _buildMetaChip(
                        context,
                        icon: Icons.open_in_new_rounded,
                        text: 'Web',
                        color: scheme.primary,
                      ),
                    if (imageCount > 0)
                      _buildMetaChip(
                        context,
                        icon: Icons.image_outlined,
                        text: '$imageCount 张图',
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '关闭',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
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
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.72 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
          width: 0.7,
        ),
      ),
      child: HtmlWidget(
        item.description!,
        textStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(height: 1.6),
        customStylesBuilder: (element) {
          if (element.localName == 'img') {
            return {'max-width': '100%', 'height': 'auto'};
          }
          if (element.localName == 'a') {
            return {'color': '#0A84FF', 'text-decoration': 'none'};
          }
          return null;
        },
        customWidgetBuilder: (element) {
          if (element.localName == 'img') {
            final src = element.attributes['src'];
            if (src != null && src.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildRemoteImage(context, src),
              );
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRemoteImage(BuildContext context, String url) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        width: double.infinity,
        progressIndicatorBuilder: (context, url, progress) => Container(
          height: 210,
          color: scheme.surfaceContainer.withValues(alpha: 0.45),
          child: Center(
            child: CircularProgressIndicator(
              value: progress.progress,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 210,
          color: scheme.surfaceContainer.withValues(alpha: 0.45),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.broken_image_outlined,
                  size: 42,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 8),
                Text(
                  '图片加载失败',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDescription(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
          width: 0.7,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 14),
          Text(
            '暂无描述内容',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canDownload =
        item.torrentURL?.isNotEmpty == true && qbController != null;
    final canCopyLink = item.link?.isNotEmpty == true;
    if (!canDownload && !canCopyLink) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
            width: 0.7,
          ),
        ),
      ),
      child: Row(
        children: [
          if (canCopyLink) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyWebLink,
                icon: const Icon(Icons.link_rounded, size: 18),
                label: const Text('复制链接'),
              ),
            ),
            if (canDownload) const SizedBox(width: 10),
          ],
          if (canDownload)
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openDownloadPage(context),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('下载种子'),
              ),
            ),
        ],
      ),
    );
  }
}
