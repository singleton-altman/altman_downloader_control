import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/label_switch_form.dart';
import 'package:altman_downloader_control/widget/lable_textfield_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// 显示 Torrent 下载页面
/// 使用 bottomSheet 风格显示
/// [downloaderIds] 可选的下载器ID列表，如果为空则显示所有支持的下载器类型（qBittorrent 和 Transmission）
void showTorrentDownloadScreen(
  BuildContext context, {
  String? downloadUrls,
  List<String>? localFilePaths,
  required DownloaderControllerProtocol controller,
}) {
  showCupertinoSheet(
    context: context,
    builder: (context) => TorrentDownloadScreen(
      downloadUrls: downloadUrls,
      localFilePaths: localFilePaths,
      controller: controller,
    ),
  );
}

/// Torrent 下载页面
class TorrentDownloadScreen extends StatefulWidget {
  const TorrentDownloadScreen({
    super.key,
    this.downloadUrls,
    this.localFilePaths,
    required this.controller,
  });

  final String? downloadUrls;
  final List<String>? localFilePaths;
  final DownloaderControllerProtocol controller;

  @override
  State<TorrentDownloadScreen> createState() => _TorrentDownloadScreenState();
}

class _TorrentDownloadScreenState extends State<TorrentDownloadScreen> {
  DownloaderControllerProtocol get _downloaderController => widget.controller;

  bool get _isQBittorrent =>
      widget.controller.config?.type == DownloaderType.qbittorrent;

  QBController? get _qbController => _downloaderController is QBController
      ? _downloaderController as QBController
      : null;

  final _linkController = TextEditingController();

  // 文件列表（存储文件路径）
  final _files = <String>[].obs;
  final _autoTMM = false.obs;
  // 目录选择
  final _directoryController = TextEditingController(text: '/downloads');

  // 分类选择
  final _category = Rxn<String>();
  final _categories = <String>[].obs;

  // 重命名
  final _renameController = TextEditingController();

  // 下载选项
  final _autoStartDownload = true.obs;
  final _skipHashCheck = false.obs;
  final _addToTopOfQueue = false.obs;

  // 文件布局
  final _contentLayout = 'Original'.obs;

  // 下载顺序
  final _sequentialDownload = false.obs;
  final _firstLastPiece = false.obs;

  // 速度限制（单位 KiB/s）
  final _upSpeedLimitController = TextEditingController(text: '0');
  final _dlSpeedLimitController = TextEditingController(text: '0');

  // 停止条件
  final _stopCondition = 'None'.obs;

  // 错误消息
  final _errorMsg = Rxn<String>();

  // 是否正在上传
  final _isUploading = false.obs;

  final _preferences = Rxn<QBPreferencesModel>();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 初始化下载器

    // 设置传入的下载链接
    if (widget.downloadUrls != null && widget.downloadUrls!.isNotEmpty) {
      _linkController.text = widget.downloadUrls!;
    }
    if (widget.localFilePaths != null && widget.localFilePaths!.isNotEmpty) {
      _files.assignAll(
        widget.localFilePaths!
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );
    }

    // 读取剪贴板内容
    if (_linkController.text.isEmpty) {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null &&
          clipboardData.text != null &&
          _isPossibleDownloadLink(clipboardData.text!)) {
        _linkController.text = clipboardData.text!;
      }
    }

    // 获取分类列表
    await _getCategories();

    // 获取应用偏好设置
    await _getAppPreferences();
  }

  /// 获取分类列表（仅 qBittorrent 支持）
  Future<void> _getCategories() async {
    if (!_isQBittorrent) return;
    try {
      final categories = await _qbController?.getCategories();
      _categories.value = categories?.keys.toList() ?? [];
    } catch (e) {
      // 静默失败
    }
  }

  /// 获取应用偏好设置（仅 qBittorrent 支持）
  Future<void> _getAppPreferences() async {
    if (!_isQBittorrent) return;
    try {
      await _downloaderController.refreshPreferences();
      _preferences.value = _downloaderController.preferences.value;

      // 如果目录为空，设置默认保存路径
      if (_directoryController.text.isEmpty ||
          _directoryController.text == '/downloads') {
        final defaultPath = _preferences.value?.savePath;
        if (defaultPath != null && defaultPath.isNotEmpty) {
          _directoryController.text = defaultPath;
        }
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// 判断是否为可能的下载链接
  bool _isPossibleDownloadLink(String text) {
    return text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('magnet:?') ||
        text.length == 40; // info hash
  }

  /// 提交下载
  Future<void> _onDownload() async {
    // 验证输入
    if (_linkController.text.trim().isEmpty && _files.isEmpty) {
      _errorMsg.value = '请输入下载链接或选择文件';
      return;
    }

    if (_directoryController.text.trim().isEmpty) {
      _errorMsg.value = '请输入保存目录';
      return;
    }

    // 检查分类的保存路径（仅 qBittorrent 支持）
    String savePath = _directoryController.text.trim();
    if (_category.value != null && _category.value!.isNotEmpty) {
      try {
        if (_downloaderController is QBController) {
          final categories = await _qbController?.getCategories() ?? {};
          final categoryInfo = categories[_category.value!];
          if (categoryInfo is Map && categoryInfo.containsKey('savePath')) {
            final categoryPath = categoryInfo['savePath'] as String?;
            if (categoryPath != null && categoryPath.isNotEmpty) {
              savePath = categoryPath;
            }
          }
        }
      } catch (e) {
        // 使用默认路径
      }
    }

    // 转换为 KiB/s 到字节/秒
    // 注意：0 表示不限速，应该传递 0 而不是 null
    int? dlLimit;
    int? upLimit;

    try {
      final dlLimitValue = int.tryParse(_dlSpeedLimitController.text);
      if (dlLimitValue != null && dlLimitValue >= 0) {
        // 如果为 0，表示不限速，传递 0；如果大于 0，转换为字节/秒
        dlLimit = dlLimitValue > 0 ? dlLimitValue * 1024 : 0;
      }
    } catch (e) {
      // 忽略，保持为 null
    }

    try {
      final upLimitValue = int.tryParse(_upSpeedLimitController.text);
      if (upLimitValue != null && upLimitValue >= 0) {
        // 如果为 0，表示不限速，传递 0；如果大于 0，转换为字节/秒
        upLimit = upLimitValue > 0 ? upLimitValue * 1024 : 0;
      }
    } catch (e) {
      // 忽略，保持为 null
    }

    _isUploading.value = true;
    _errorMsg.value = null;

    try {
      bool? success = false;

      // 如果是 qBittorrent，使用 addTorrentDetailed 方法（支持更多参数）
      if (_isQBittorrent && _qbController != null) {
        success = await _qbController?.addTorrentDetailed(
          urls: _linkController.text.trim().isNotEmpty
              ? _linkController.text.trim()
              : null,
          torrentFilePaths: _files.isNotEmpty ? _files.toList() : null,
          savePath: savePath,
          autoTMM: _autoTMM.value,
          rename: _renameController.text.trim().isNotEmpty
              ? _renameController.text.trim()
              : null,
          category: _category.value != null && _category.value!.isNotEmpty
              ? _category.value!
              : null,
          paused: !_autoStartDownload.value,
          stopCondition: _stopCondition.value,
          skipChecking: _skipHashCheck.value,
          contentLayout: _contentLayout.value,
          dlLimit: dlLimit,
          upLimit: upLimit,
        );
      } else {
        // 使用协议方法 addTorrent（支持所有下载器类型，包括 Transmission）
        // Transmission 的参数格式：{ "arguments": { "download-dir": "...", "filename": "...", "paused": false } }

        // 对于 Transmission，需要逐个添加（每次只能添加一个）
        if (_files.isNotEmpty) {
          // 添加文件
          for (final filePath in _files) {
            final result = await _downloaderController.addTorrent(
              torrent: filePath, // Transmission 的 filename 可以是文件路径
              savePath: savePath,
              category:
                  _isQBittorrent &&
                      _category.value != null &&
                      _category.value!.isNotEmpty
                  ? _category.value!
                  : null,
              tags: null,
              paused: !_autoStartDownload.value,
              skipChecking: _skipHashCheck.value,
            );
            if (!result) {
              _errorMsg.value = '添加文件失败: $filePath';
              return;
            }
          }
          success = true;
        }

        // 添加链接（URL 或磁力链接）
        if (_linkController.text.trim().isNotEmpty) {
          // 处理多行链接（每行一个）
          final links = _linkController.text.trim().split('\n');
          for (final link in links) {
            if (link.trim().isEmpty) continue;
            final result = await _downloaderController.addTorrent(
              torrent: link.trim(), // Transmission 的 filename 可以是 URL 或磁力链接
              savePath: savePath,
              category:
                  _isQBittorrent &&
                      _category.value != null &&
                      _category.value!.isNotEmpty
                  ? _category.value!
                  : null,
              tags: null,
              paused: !_autoStartDownload.value,
              skipChecking: _skipHashCheck.value,
            );
            if (!result) {
              _errorMsg.value = '添加链接失败: ${link.trim()}';
              return;
            }
          }
          success = true;
        }

        // 如果添加成功且有速度限制，需要通过 torrent-set 设置（在添加后）
        // 注意：Transmission 的 torrent-add 不支持直接设置限速
        // 需要在添加后通过其他方法设置限速
        if (success && (dlLimit != null || upLimit != null)) {}
      }

      if (success != null && success) {
        showToast(message: '下载任务已添加');
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        _errorMsg.value = _downloaderController.errorMessage.value.isNotEmpty
            ? _downloaderController.errorMessage.value
            : '添加下载任务失败';
      }
    } catch (e) {
      _errorMsg.value = '添加下载任务失败: ${e.toString()}';
    } finally {
      _isUploading.value = false;
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _directoryController.dispose();
    _renameController.dispose();
    _upSpeedLimitController.dispose();
    _dlSpeedLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('新建任务'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [_buildBottomButton()],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Obx(() {
                final msg = _errorMsg.value;
                if (msg == null || msg.isEmpty) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }),
              // Torrent 链接输入
              _buildTorrentSection(),
              _buildLocalFilesSection(),
              // Torrent 选项
              _buildBasicInfoSection(),
              _buildDownloadControlSection(),
              _buildDownloadOptionsSection(),
              _buildSpeedLimitSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTorrentSection() {
    return CupertinoListSection.insetGrouped(
      separatorColor: Colors.transparent,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: TextField(
            controller: _linkController,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: '请输入下载链接（每行一个）\n支持 HTTP 链接、Magnet 链接和 info-hash',
              hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalFilesSection() {
    return Obx(() {
      if (_files.isEmpty) return const SizedBox.shrink();
      return CupertinoListSection.insetGrouped(
        separatorColor: Colors.transparent,
        header: Text('本地文件', style: Theme.of(context).textTheme.titleMedium),
        children: [
          CupertinoListTile.notched(
            title: Text('已准备 ${_files.length} 个本地文件'),
            subtitle: Text(
              _files.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) =>
                      LocalTorrentFilesPage(filePaths: _files.toList()),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  /// 构建基本信息部分
  Widget _buildBasicInfoSection() {
    return CupertinoListSection.insetGrouped(
      separatorColor: Colors.transparent,
      header: Text('基本信息', style: Theme.of(context).textTheme.titleMedium),
      children: [
        LabelSwitchForm(
          title: '自动管理种子',
          initialValue: _autoTMM.value,
          onChanged: (value) => _autoTMM.value = value,
        ),

        // Save files to location
        LabelTextFieldForm(
          title: '保存文件到',
          controller: _directoryController,
          hintText: '/downloads',
        ),
        const SizedBox(height: 16),

        // Rename torrent
        LabelTextFieldForm(title: '重命名种子', controller: _renameController),

        // Category（仅 qBittorrent 支持）
        if (_isQBittorrent)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Text(
                  '分类',
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                PopupMenuButton(
                  onSelected: (value) => _category.value = value,
                  borderRadius: BorderRadius.circular(12),
                  itemBuilder: (context) => _categories
                      .map(
                        (c) => PopupMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                      .toList(),
                  child: Obx(
                    () => Text(
                      _category.value ?? '无',
                      style: Get.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Get.theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 构建下载控制部分
  Widget _buildDownloadControlSection() {
    return CupertinoListSection.insetGrouped(
      separatorColor: Colors.transparent,
      header: Text('下载控制', style: Theme.of(context).textTheme.titleMedium),
      children: [
        // Start torrent
        LabelSwitchForm(
          title: '开始下载',
          initialValue: _autoStartDownload.value,
          onChanged: (value) {
            _autoStartDownload.value = value;
          },
        ),

        // Add to top of queue
        LabelSwitchForm(
          title: '添加到队列顶部',
          initialValue: _addToTopOfQueue.value,
          onChanged: (value) {
            _addToTopOfQueue.value = value;
          },
        ),

        // Stop condition（仅 qBittorrent 支持）
        if (_isQBittorrent)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Text(
                  '停止条件',
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                PopupMenuButton(
                  onSelected: (value) => _stopCondition.value = value,
                  borderRadius: BorderRadius.circular(12),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'None',
                      child: Text(
                        '无',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'MetadataReceived',
                      child: Text(
                        '接收到元数据',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'FilesChecked',
                      child: Text(
                        '文件检查完成',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  child: Obx(
                    () => Text(
                      _stopCondition.value,
                      style: Get.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Get.theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 构建下载选项部分
  Widget _buildDownloadOptionsSection() {
    return CupertinoListSection.insetGrouped(
      separatorColor: Colors.transparent,
      header: Text('下载选项', style: Theme.of(context).textTheme.titleMedium),
      children: [
        // Skip hash check
        LabelSwitchForm(
          title: '跳过哈希检查',
          initialValue: _skipHashCheck.value,
          onChanged: (value) {
            _skipHashCheck.value = value;
          },
        ),

        // Content layout（仅 qBittorrent 支持）
        if (_isQBittorrent)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Text(
                  '内容布局',
                  style: Get.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Get.theme.colorScheme.onSurface,
                  ),
                ),
                Spacer(),
                PopupMenuButton(
                  borderRadius: BorderRadius.circular(12),
                  onSelected: (value) => _contentLayout.value = value,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'Original',
                      child: Text(
                        '原始',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'Subfolder',
                      child: Text(
                        '子文件夹',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'NoSubfolder',
                      child: Text(
                        '无子文件夹',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  child: Obx(
                    () => Text(
                      _contentLayout.value,
                      style: Get.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Get.theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Download in sequential order
        LabelSwitchForm(
          title: '顺序下载',
          initialValue: _sequentialDownload.value,
          onChanged: (value) {
            _sequentialDownload.value = value;
          },
        ),

        // Download first and last pieces first
        LabelSwitchForm(
          title: '优先下载首尾片段',
          initialValue: _firstLastPiece.value,
          onChanged: (value) {
            _firstLastPiece.value = value;
          },
        ),
      ],
    );
  }

  /// 构建速度限制部分
  Widget _buildSpeedLimitSection() {
    return CupertinoListSection.insetGrouped(
      separatorColor: Colors.transparent,
      header: Text('速度限制', style: Theme.of(context).textTheme.titleMedium),
      children: [
        // Limit download rate
        LabelTextFieldForm(
          title: '限制下载速度',
          controller: _dlSpeedLimitController,
          keyboardType: TextInputType.number,
          hintText: '0',
        ),
        // Limit upload rate
        LabelTextFieldForm(
          title: '限制上传速度',
          controller: _upSpeedLimitController,
          keyboardType: TextInputType.number,
          hintText: '0',
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Obx(() {
        if (_isUploading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        return ElevatedButton(
          onPressed: _onDownload,
          child: const Text(
            '下载',
            style: TextStyle(              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }),
    );
  }
}

class LocalTorrentFilesPage extends StatelessWidget {
  const LocalTorrentFilesPage({super.key, required this.filePaths});

  final List<String> filePaths;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本地文件路径')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final path = filePaths[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: SelectableText(
              path,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: filePaths.length,
      ),
    );
  }
}
