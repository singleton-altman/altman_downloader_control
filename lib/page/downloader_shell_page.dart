import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/page/downloader_shell_chrome.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/page/downloader_profile_page.dart';
import 'package:altman_downloader_control/page/qbittorrent/qb_rss_list_page.dart';
import 'package:altman_downloader_control/page/torrent_list_page.dart';
import 'package:altman_downloader_control/theme/downloader_cupertino_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DownloaderShellPage extends StatefulWidget {
  const DownloaderShellPage({super.key});

  @override
  State<DownloaderShellPage> createState() => _DownloaderShellPageState();
}

class DownloaderTorrentListPage extends StatelessWidget {
  const DownloaderTorrentListPage({super.key});

  @override
  Widget build(BuildContext context) => const DownloaderShellPage();
}

class _DownloaderShellPageState extends State<DownloaderShellPage> {
  late final DownloaderControllerProtocol controller;

  bool get _isQb => controller.config?.type == DownloaderType.qbittorrent;

  @override
  void initState() {
    super.initState();
    controller = Get.find<DownloaderControllerProtocol>();
  }

  Widget _buildTab(int index) {
    if (_isQb) {
      switch (index) {
        case 0:
          return const DownloaderTorrentListTab(embeddedInShell: true);
        case 1:
          return QBRssListPage(
            controller: controller as QBController,
            embedded: true,
          );
        case 2:
          return DownloaderProfilePage(controller: controller, embedded: true);
      }
    }
    switch (index) {
      case 0:
        return const DownloaderTorrentListTab(embeddedInShell: true);
      case 1:
        return DownloaderProfilePage(controller: controller, embedded: true);
    }
    return const SizedBox.shrink();
  }

  List<BottomNavigationBarItem> _tabItems(BuildContext context) {
    return [
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.arrow_down_circle),
        activeIcon: Icon(CupertinoIcons.arrow_down_circle_fill),
        label: '种子',
      ),
      if (_isQb)
        const BottomNavigationBarItem(
          icon: Icon(Icons.rss_feed_outlined),
          activeIcon: Icon(Icons.rss_feed),
          label: 'RSS',
        ),
      const BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person),
        activeIcon: Icon(CupertinoIcons.person_fill),
        label: '信息',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);

    return ValueListenableBuilder<bool>(
      valueListenable: DownloaderShellChrome.hideTabBar,
      builder: (context, hideTabBar, _) {
        return CupertinoTabScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          tabBar: CupertinoTabBar(
            activeColor: hideTabBar
                ? Colors.transparent
                : DownloaderCupertinoTheme.primaryBlue,
            inactiveColor: hideTabBar
                ? Colors.transparent
                : CupertinoColors.inactiveGray.resolveFrom(context),
            backgroundColor: hideTabBar
                ? Colors.transparent
                : CupertinoTheme.of(context).barBackgroundColor,
            border: hideTabBar
                ? null
                : Border(top: BorderSide(color: separator, width: 0.5)),
            iconSize: hideTabBar ? 0 : 24,
            height: hideTabBar ? 0 : DownloaderCupertinoTheme.shellTabBarHeight,
            items: _tabItems(context),
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              builder: (context) => Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: _buildTab(index),
              ),
            );
          },
        );
      },
    );
  }
}
