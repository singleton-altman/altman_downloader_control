import 'dart:ui';

import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/model/torrent_item_model.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_log_page.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_preferences_settings_page.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_rss_list_page.dart';
import 'package:altman_downloader_control/page/torrent_download_screen.dart';
import 'package:altman_downloader_control/widget/filter_widget.dart';
import 'package:altman_downloader_control/widget/torrent_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/controller/transmission/transmission_controller.dart';
import 'package:altman_downloader_control/model/qb_sort_type.dart';
import 'package:altman_downloader_control/model/transmission_list_sort_type.dart';
import 'package:altman_downloader_control/utils/string_utils.dart';

class DownloaderTorrentListPage extends StatefulWidget {
  const DownloaderTorrentListPage({super.key});

  @override
  State<DownloaderTorrentListPage> createState() =>
      _DownloaderTorrentListPageState();
}

class _DownloaderTorrentListPageState extends State<DownloaderTorrentListPage> {
  late final DownloaderControllerProtocol controller;
  final _isBootstrapping = true.obs;

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
    return _buildPageScaffold(context);
  }

  Widget _buildPageScaffold(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingToolbar(context),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildErrorMessage(context)),
            _buildTorrentInfo(context),
            _buildTorrentList(context),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 76,
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

      if (!isWideLayout) {
        return SliverList.builder(
          itemCount: displayTorrents.length,
          itemBuilder: (context, index) {
            final torrent = displayTorrents[index];
            return TorrentListItem(torrent: torrent, controller: controller);
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
            return TorrentListItem(torrent: torrent, controller: controller);
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
                    // 排序类型图标
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
                    // 选中标记
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark
          ? colorScheme.surface.withValues(alpha: 0.95)
          : colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.primaryColor.withAlpha(50),
            borderRadius: BorderRadius.circular(44),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(CupertinoIcons.chevron_left, color: theme.primaryColor),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      title: Text(
        controller.config?.name ?? controller.config?.url.split('/').last ?? '',
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
        // RSS 和 Log 整合为一个整体（降低视觉重量）
        if (isQBittorrent && controller is QBController)
        // 日志按钮
        ...[
          _buildIOSActionButton(
            context: context,
            icon: Icons.description_outlined,
            tooltip: '日志',
            onPressed: () {
              Get.to(() => QBLogPage(controller: controller as QBController));
            },
            showContainer: false, // 不显示独立容器
          ),
          _buildIOSActionButton(
            context: context,
            icon: Icons.rss_feed_outlined,
            tooltip: 'RSS订阅',
            onPressed: () {
              Get.to(
                () => QBRssListPage(controller: controller as QBController),
              );
            },
            showContainer: false, // 不显示独立容器
          ),
        ],

        // 仅 qBittorrent 支持偏好设置（独立显示）
        if (supportsPreferences && controller is QBController)
          _buildIOSActionButton(
            context: context,
            icon: Icons.settings_outlined,
            tooltip: '设置',
            onPressed: () {
              Get.to(
                () => QBPreferencesSettingsScreen(controller: controller),
                arguments: {'id': controller.config?.id ?? ''},
              );
            },
          ),
        const SizedBox(width: 8),
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

  /// 构建 iOS 风格的操作按钮
  Widget _buildIOSActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool showContainer = true, // 是否显示独立容器
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (!showContainer) {
      // 不显示容器，直接返回按钮（用于 RSS 和 Log，降低视觉重量）
      return CupertinoButton(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: onPressed,
        child: Icon(
          icon,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          size: 16, // 进一步减小图标尺寸
        ),
      );
    }

    // 显示独立容器（用于 Setting，增强视觉重量）
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: 20, // 增大图标尺寸以突出显示
        ),
      ),
    );
  }
}
