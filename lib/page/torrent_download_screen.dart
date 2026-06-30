import 'package:altman_downloader_control/controller/downloader_config.dart';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/downloader_app_bar_back_button.dart';
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
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.36,
      maxChildSize: 1,
      expand: false,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: TorrentDownloadScreen(
          downloadUrls: downloadUrls,
          localFilePaths: localFilePaths,
          controller: controller,
          scrollController: scrollController,
        ),
      ),
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
    this.scrollController,
  });

  final String? downloadUrls;
  final List<String>? localFilePaths;
  final DownloaderControllerProtocol controller;
  final ScrollController? scrollController;

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            _buildSheetHandle(),
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  18 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildErrorBanner(),
                    _buildTorrentSection(),
                    _buildBasicInfoSection(),
                    _buildDownloadControlSection(),
                    _buildDownloadOptionsSection(),
                    _buildSpeedLimitSection(),
                  ],
                ),
              ),
            ),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
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

  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    final downloaderName =
        widget.controller.config?.name ??
        (_isQBittorrent ? 'qBittorrent' : 'Transmission');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.add_link_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '新建下载任务',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '添加到 $downloaderName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
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

  Widget _buildErrorBanner() {
    return Obx(() {
      final msg = _errorMsg.value;
      if (msg == null || msg.isEmpty) return const SizedBox.shrink();
      final scheme = Theme.of(context).colorScheme;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.error.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPanelSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTorrentSection() {
    return _buildPanelSection(
      icon: Icons.link_rounded,
      title: '下载源',
      subtitle: '支持 HTTP、Magnet、info-hash；多条链接可按行输入。',
      children: [
        TextField(
          controller: _linkController,
          minLines: 4,
          maxLines: 7,
          textInputAction: TextInputAction.newline,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(
            hintText: '粘贴下载链接，每行一个',
            alignLabelWithHint: true,
          ),
        ),
        _buildLocalFilesSection(),
      ],
    );
  }

  Widget _buildLocalFilesSection() {
    return Obx(() {
      if (_files.isEmpty) return const SizedBox.shrink();
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Material(
          color: scheme.surfaceContainer.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) =>
                      LocalTorrentFilesPage(filePaths: _files.toList()),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, color: scheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已准备 ${_files.length} 个本地文件',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _files.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTextFieldRow({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(labelText: label, hintText: hintText),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    String? subtitle,
    required RxBool value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value.value,
              activeThumbColor: scheme.primary,
              activeTrackColor: scheme.primary.withValues(alpha: 0.28),
              onChanged: (next) => value.value = next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionRow({
    required String label,
    required String value,
    required List<PopupMenuEntry<String>> items,
    required ValueChanged<String> onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: label,
            borderRadius: BorderRadius.circular(12),
            onSelected: onSelected,
            itemBuilder: (_) => items,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建基本信息部分
  Widget _buildBasicInfoSection() {
    return _buildPanelSection(
      icon: Icons.folder_copy_outlined,
      title: '保存策略',
      subtitle: '设置任务落盘位置、分类和显示名称。',
      children: [
        _buildSwitchRow(
          title: '自动管理种子',
          subtitle: '允许下载器按分类规则管理保存路径。',
          value: _autoTMM,
        ),
        _buildTextFieldRow(
          label: '保存文件到',
          controller: _directoryController,
          hintText: '/downloads',
        ),
        _buildTextFieldRow(label: '重命名种子', controller: _renameController),
        if (_isQBittorrent)
          Obx(
            () => _buildSelectionRow(
              label: '分类',
              value: _category.value?.isNotEmpty == true
                  ? _category.value!
                  : '无',
              onSelected: (value) =>
                  _category.value = value.isEmpty ? null : value,
              items: [
                const PopupMenuItem(value: '', child: Text('无')),
                ..._categories.map(
                  (c) => PopupMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
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
    return _buildPanelSection(
      icon: Icons.play_circle_outline_rounded,
      title: '启动行为',
      subtitle: '决定任务加入队列后的启动和停止方式。',
      children: [
        _buildSwitchRow(
          title: '开始下载',
          subtitle: '关闭后会以暂停状态添加。',
          value: _autoStartDownload,
        ),
        _buildSwitchRow(
          title: '添加到队列顶部',
          subtitle: '优先处理这批新任务。',
          value: _addToTopOfQueue,
        ),
        if (_isQBittorrent)
          Obx(
            () => _buildSelectionRow(
              label: '停止条件',
              value: _stopConditionLabel(_stopCondition.value),
              onSelected: (value) => _stopCondition.value = value,
              items: const [
                PopupMenuItem(value: 'None', child: Text('无')),
                PopupMenuItem(value: 'MetadataReceived', child: Text('接收到元数据')),
                PopupMenuItem(value: 'FilesChecked', child: Text('文件检查完成')),
              ],
            ),
          ),
      ],
    );
  }

  /// 构建下载选项部分
  Widget _buildDownloadOptionsSection() {
    return _buildPanelSection(
      icon: Icons.tune_rounded,
      title: '下载选项',
      subtitle: '校验、文件布局和分片下载策略。',
      children: [
        _buildSwitchRow(
          title: '跳过哈希检查',
          subtitle: '适合已确认完整的本地数据。',
          value: _skipHashCheck,
        ),
        if (_isQBittorrent)
          Obx(
            () => _buildSelectionRow(
              label: '内容布局',
              value: _contentLayoutLabel(_contentLayout.value),
              onSelected: (value) => _contentLayout.value = value,
              items: const [
                PopupMenuItem(value: 'Original', child: Text('原始')),
                PopupMenuItem(value: 'Subfolder', child: Text('子文件夹')),
                PopupMenuItem(value: 'NoSubfolder', child: Text('无子文件夹')),
              ],
            ),
          ),
        _buildSwitchRow(
          title: '顺序下载',
          subtitle: '按文件顺序下载，适合边下边看。',
          value: _sequentialDownload,
        ),
        _buildSwitchRow(
          title: '优先下载首尾片段',
          subtitle: '加快媒体文件识别和预览。',
          value: _firstLastPiece,
        ),
      ],
    );
  }

  /// 构建速度限制部分
  Widget _buildSpeedLimitSection() {
    return _buildPanelSection(
      icon: Icons.speed_rounded,
      title: '速度限制',
      subtitle: '单位 KB/s，0 表示不限制。',
      children: [
        _buildTextFieldRow(
          label: '限制下载速度',
          controller: _dlSpeedLimitController,
          keyboardType: TextInputType.number,
          hintText: '0',
        ),
        _buildTextFieldRow(
          label: '限制上传速度',
          controller: _upSpeedLimitController,
          keyboardType: TextInputType.number,
          hintText: '0',
        ),
      ],
    );
  }

  String _stopConditionLabel(String value) {
    switch (value) {
      case 'MetadataReceived':
        return '接收到元数据';
      case 'FilesChecked':
        return '文件检查完成';
      default:
        return '无';
    }
  }

  String _contentLayoutLabel(String value) {
    switch (value) {
      case 'Subfolder':
        return '子文件夹';
      case 'NoSubfolder':
        return '无子文件夹';
      default:
        return '原始';
    }
  }

  Widget _buildSubmitBar() {
    final scheme = Theme.of(context).colorScheme;
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
      child: Obx(() {
        if (_isUploading.value) {
          return SizedBox(
            height: 48,
            child: Center(
              child: CupertinoActivityIndicator(color: scheme.primary),
            ),
          );
        }

        return SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _onDownload,
            icon: const Icon(Icons.add_task_rounded, size: 19),
            label: const Text('添加下载任务'),
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
      appBar: AppBar(
        title: const Text('本地文件路径'),
        automaticallyImplyLeading: false,
        leadingWidth: DownloaderAppBarBackButton.leadingWidth,
        leading: const DownloaderAppBarBackButton(),
      ),
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
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemCount: filePaths.length,
      ),
    );
  }
}
