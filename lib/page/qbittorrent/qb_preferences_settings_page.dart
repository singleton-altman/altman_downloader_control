import 'dart:math';
import 'package:altman_downloader_control/controller/protocol.dart';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/utils/string_utils.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:altman_downloader_control/widget/label_switch_form.dart';
import 'package:altman_downloader_control/widget/lable_textfield_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';

class QBPreferencesSettingsScreen extends StatefulWidget {
  const QBPreferencesSettingsScreen({super.key, required this.controller});
  final DownloaderControllerProtocol controller;
  @override
  State<QBPreferencesSettingsScreen> createState() =>
      _QBPreferencesSettingsScreenState();
}

class _QBPreferencesSettingsScreenState
    extends State<QBPreferencesSettingsScreen> {
  QBPreferencesModel? _preferences;
  bool _isLoading = false;

  DownloaderControllerProtocol get controller => widget.controller;
  // 可编辑字段的控制器
  final _savePathController = TextEditingController();
  final _tempPathController = TextEditingController();
  final _listenPortController = TextEditingController();
  final _upLimitController = TextEditingController();
  final _dlLimitController = TextEditingController();
  final _maxActiveCheckingTorrentsController = TextEditingController();
  final _maxActiveDownloadsController = TextEditingController();
  final _maxActiveUploadsController = TextEditingController();
  final _maxActiveTorrentsController = TextEditingController();
  final _altDlLimitController = TextEditingController();
  final _altUpLimitController = TextEditingController();
  final _webUiPortController = TextEditingController();
  final _webUiSessionTimeoutController = TextEditingController();
  final _webUiApiKeyController = TextEditingController();
  final _hostnameCacheTtlController = TextEditingController();

  // 开关状态
  bool _incompleteFilesExt = false;
  bool _queueingEnabled = false;
  bool _tempPathEnabled = false;
  bool _webUiClickjackingProtectionEnabled = false;
  bool _webUiCsrfProtectionEnabled = false;
  bool _webUiSecureCookieEnabled = false;
  bool _webUiHostHeaderValidationEnabled = false;
  bool _dht = true;
  bool _pex = true;
  bool _lsd = true;
  bool _anonymousMode = false;
  bool _resolvePeerHostNames = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _savePathController.dispose();
    _tempPathController.dispose();
    _listenPortController.dispose();
    _upLimitController.dispose();
    _dlLimitController.dispose();
    _maxActiveCheckingTorrentsController.dispose();
    _maxActiveDownloadsController.dispose();
    _maxActiveUploadsController.dispose();
    _maxActiveTorrentsController.dispose();
    _altDlLimitController.dispose();
    _altUpLimitController.dispose();
    _webUiPortController.dispose();
    _webUiSessionTimeoutController.dispose();
    _webUiApiKeyController.dispose();
    _hostnameCacheTtlController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 同时更新模型用于 UI 显示
      await controller.refreshPreferences();
      _preferences = controller.preferences.value;
      if (_preferences != null) {
        _updateControllers();
      }
    } catch (e) {
      failToast(message: '加载设置失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateControllers() {
    if (_preferences == null) return;

    _incompleteFilesExt = _preferences!.incompleteFilesExt;
    _savePathController.text = _preferences!.savePath;
    _tempPathController.text = _preferences!.tempPath;
    _listenPortController.text = _preferences!.listenPort.toString();
    // 速度限制转换为 KB/s 显示（字节转 KB）
    _upLimitController.text = _preferences!.upLimit > 0
        ? (_preferences!.upLimit ~/ 1024).toString()
        : '0';
    _dlLimitController.text = _preferences!.dlLimit > 0
        ? (_preferences!.dlLimit ~/ 1024).toString()
        : '0';
    _maxActiveCheckingTorrentsController.text = _preferences!
        .maxActiveCheckingTorrents
        .toString();
    _maxActiveDownloadsController.text = _preferences!.maxActiveDownloads
        .toString();
    _maxActiveUploadsController.text = _preferences!.maxActiveUploads
        .toString();
    _maxActiveTorrentsController.text = _preferences!.maxActiveTorrents
        .toString();

    _altDlLimitController.text = _preferences!.altDlLimit > 0
        ? (_preferences!.altDlLimit ~/ 1024).toString()
        : '0';
    _altUpLimitController.text = _preferences!.altUpLimit > 0
        ? (_preferences!.altUpLimit ~/ 1024).toString()
        : '0';
    _webUiPortController.text = _preferences!.webUiPort.toString();
    _webUiSessionTimeoutController.text = _preferences!.webUiSessionTimeout
        .toString();
    _webUiApiKeyController.clear();
    _hostnameCacheTtlController.text = _preferences!.hostnameCacheTtl
        .toString();

    _dht = _preferences!.dht;
    _pex = _preferences!.pex;
    _lsd = _preferences!.lsd;
    _anonymousMode = _preferences!.anonymousMode;
    _resolvePeerHostNames = _preferences!.resolvePeerHostNames;

    _queueingEnabled = _preferences!.queueingEnabled;
    _tempPathEnabled = _preferences!.tempPathEnabled;
    _webUiClickjackingProtectionEnabled =
        _preferences!.webUiClickjackingProtectionEnabled;
    _webUiCsrfProtectionEnabled = _preferences!.webUiCsrfProtectionEnabled;
    _webUiSecureCookieEnabled = _preferences!.webUiSecureCookieEnabled;
    _webUiHostHeaderValidationEnabled =
        _preferences!.webUiHostHeaderValidationEnabled;
  }

  Future<void> _save() async {
    if (_preferences == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      showToast();

      // 只发送修改过的字段，而不是所有数据
      final updateData = <String, dynamic>{};

      // 1. 为不完整的文件添加扩展名
      if (_incompleteFilesExt != _preferences!.incompleteFilesExt) {
        updateData['incomplete_files_ext'] = _incompleteFilesExt;
      }

      // 2. 默认保存路径
      if (_savePathController.text != _preferences!.savePath) {
        updateData['save_path'] = _savePathController.text;
      }

      // 3. 保存未完成的 torrent 到
      if (_tempPathEnabled != _preferences!.tempPathEnabled) {
        updateData['temp_path_enabled'] = _tempPathEnabled;
      }
      if (_tempPathController.text != _preferences!.tempPath) {
        updateData['temp_path'] = _tempPathController.text;
      }

      // 4. 监听端口（1000-65535）
      final listenPort = int.tryParse(_listenPortController.text);
      if (listenPort != null &&
          listenPort != _preferences!.listenPort &&
          listenPort >= 1000 &&
          listenPort <= 65535) {
        updateData['listen_port'] = listenPort;
      }

      // 5. 全局速度限制（转换为字节）
      final upLimit = int.tryParse(_upLimitController.text);
      if (upLimit != null && upLimit >= 0) {
        final upLimitBytes = upLimit * 1024; // KB/s 转字节/秒
        if (upLimitBytes != _preferences!.upLimit) {
          updateData['up_limit'] = upLimitBytes;
        }
      }
      final dlLimit = int.tryParse(_dlLimitController.text);
      if (dlLimit != null && dlLimit >= 0) {
        final dlLimitBytes = dlLimit * 1024; // KB/s 转字节/秒
        if (dlLimitBytes != _preferences!.dlLimit) {
          updateData['dl_limit'] = dlLimitBytes;
        }
      }

      final altUpLimit = int.tryParse(_altUpLimitController.text);
      if (altUpLimit != null && altUpLimit >= 0) {
        final bytes = altUpLimit * 1024;
        if (bytes != _preferences!.altUpLimit) {
          updateData['alt_up_limit'] = bytes;
        }
      }
      final altDlLimit = int.tryParse(_altDlLimitController.text);
      if (altDlLimit != null && altDlLimit >= 0) {
        final bytes = altDlLimit * 1024;
        if (bytes != _preferences!.altDlLimit) {
          updateData['alt_dl_limit'] = bytes;
        }
      }

      final webUiPort = int.tryParse(_webUiPortController.text);
      if (webUiPort != null &&
          webUiPort != _preferences!.webUiPort &&
          webUiPort >= 1 &&
          webUiPort <= 65535) {
        updateData['web_ui_port'] = webUiPort;
      }

      final webUiSessionTimeout = int.tryParse(
        _webUiSessionTimeoutController.text,
      );
      if (webUiSessionTimeout != null &&
          webUiSessionTimeout >= 0 &&
          webUiSessionTimeout != _preferences!.webUiSessionTimeout) {
        updateData['web_ui_session_timeout'] = webUiSessionTimeout;
      }

      if (_webUiApiKeyController.text.isNotEmpty) {
        updateData['web_ui_api_key'] = _webUiApiKeyController.text;
      }

      final hostnameTtl = int.tryParse(_hostnameCacheTtlController.text);
      if (hostnameTtl != null &&
          hostnameTtl > 0 &&
          hostnameTtl != _preferences!.hostnameCacheTtl) {
        updateData['hostname_cache_ttl'] = hostnameTtl;
      }

      if (_dht != _preferences!.dht) {
        updateData['dht'] = _dht;
      }
      if (_pex != _preferences!.pex) {
        updateData['pex'] = _pex;
      }
      if (_lsd != _preferences!.lsd) {
        updateData['lsd'] = _lsd;
      }
      if (_anonymousMode != _preferences!.anonymousMode) {
        updateData['anonymous_mode'] = _anonymousMode;
      }
      if (_resolvePeerHostNames != _preferences!.resolvePeerHostNames) {
        updateData['resolve_peer_host_names'] = _resolvePeerHostNames;
      }

      // 6. 最大活跃检查 Torrent 数
      final maxActiveCheckingTorrents = int.tryParse(
        _maxActiveCheckingTorrentsController.text,
      );
      if (maxActiveCheckingTorrents != null &&
          maxActiveCheckingTorrents > 0 &&
          maxActiveCheckingTorrents !=
              _preferences!.maxActiveCheckingTorrents) {
        updateData['max_active_checking_torrents'] = maxActiveCheckingTorrents;
      }

      // 7. Torrent 排队
      if (_queueingEnabled != _preferences!.queueingEnabled) {
        updateData['queueing_enabled'] = _queueingEnabled;
      }

      // 8. 最大活动的下载数
      final maxActiveDownloads = int.tryParse(
        _maxActiveDownloadsController.text,
      );
      if (maxActiveDownloads != null &&
          maxActiveDownloads > 0 &&
          maxActiveDownloads != _preferences!.maxActiveDownloads) {
        updateData['max_active_downloads'] = maxActiveDownloads;
      }

      // 9. 最大活动的上传数
      final maxActiveUploads = int.tryParse(_maxActiveUploadsController.text);
      if (maxActiveUploads != null &&
          maxActiveUploads > 0 &&
          maxActiveUploads != _preferences!.maxActiveUploads) {
        updateData['max_active_uploads'] = maxActiveUploads;
      }

      // 10. 最大活动的 torrent 数
      final maxActiveTorrents = int.tryParse(_maxActiveTorrentsController.text);
      if (maxActiveTorrents != null &&
          maxActiveTorrents > 0 &&
          maxActiveTorrents != _preferences!.maxActiveTorrents) {
        updateData['max_active_torrents'] = maxActiveTorrents;
      }

      // 11. 验证相关设置
      if (_webUiClickjackingProtectionEnabled !=
          _preferences!.webUiClickjackingProtectionEnabled) {
        updateData['web_ui_clickjacking_protection_enabled'] =
            _webUiClickjackingProtectionEnabled;
      }
      if (_webUiCsrfProtectionEnabled !=
          _preferences!.webUiCsrfProtectionEnabled) {
        updateData['web_ui_csrf_protection_enabled'] =
            _webUiCsrfProtectionEnabled;
      }
      if (_webUiSecureCookieEnabled != _preferences!.webUiSecureCookieEnabled) {
        updateData['web_ui_secure_cookie_enabled'] = _webUiSecureCookieEnabled;
      }
      if (_webUiHostHeaderValidationEnabled !=
          _preferences!.webUiHostHeaderValidationEnabled) {
        updateData['web_ui_host_header_validation_enabled'] =
            _webUiHostHeaderValidationEnabled;
      }

      // 检查是否有实际更改
      if (updateData.isEmpty) {
        successToast(message: '没有需要保存的更改');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final success = await controller.updatePreferences(updateData);
      if (success) {
        successToast(message: '保存成功');
        await _loadPreferences();
      }
    } catch (e) {
      failToast(message: '保存失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFileSaveSection() {
    // 1. 为不完整的文件添加扩展名
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text('文件保存', style: Theme.of(context).textTheme.titleMedium),
        ),
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(
          context,
        ),
        children: [
          LabelSwitchForm(
            title: '为不完整的文件添加扩展名 .!qB',
            value: _incompleteFilesExt,
            onChanged: (value) {
              setState(() {
                _incompleteFilesExt = value;
              });
            },
          ),
          LabelTextFieldForm(
            title: '默认保存路径',
            tip: '下载文件的默认保存路径',
            controller: _savePathController,
          ),
          LabelTextFieldForm(
            title: '保存未完成的 torrent 到',
            tip: '未完成文件的临时保存路径',
            controller: _tempPathController,
            enabled: _tempPathEnabled,
            headerTrailing: CupertinoSwitch(
              activeColor: Get.theme.colorScheme.primary,
              value: _tempPathEnabled,
              onChanged: (value) {
                setState(() {
                  _tempPathEnabled = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text('连接设置', style: Theme.of(context).textTheme.titleMedium),
        ),
        children: [
          LabelTextFieldForm(
            title: '监听端口',
            tip: '用于传入连接的端口（1000-65535）',
            controller: _listenPortController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffixIcon: TextButton(
              child: const Text('随机'),
              onPressed: () {
                final random = Random();
                final randomPort = 1000 + random.nextInt(65535 - 1000 + 1);
                _listenPortController.text = randomPort.toString();
              },
            ),
          ),
          LabelTextFieldForm(
            title: '主机名缓存 TTL（秒）',
            tip: 'DNS 缓存 TTL',
            controller: _hostnameCacheTtlController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedLimitSection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text('速度限制', style: Theme.of(context).textTheme.titleMedium),
        ),
        children: [
          LabelTextFieldForm(
            title: '上传速度限制 (KB/s)',
            tip: '0 表示无限制',
            controller: _upLimitController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: '下载速度限制 (KB/s)',
            tip: '0 表示无限制',
            controller: _dlLimitController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: '备用上传限速 (KB/s)',
            tip: '计划限速等场景；0 为无限制',
            controller: _altUpLimitController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: '备用下载限速 (KB/s)',
            tip: '0 为无限制',
            controller: _altDlLimitController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildBitTorrentSection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            'BitTorrent',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        children: [
          LabelSwitchForm(
            title: 'DHT',
            value: _dht,
            onChanged: (value) {
              setState(() {
                _dht = value;
              });
            },
          ),
          LabelSwitchForm(
            title: 'PEX',
            value: _pex,
            onChanged: (value) {
              setState(() {
                _pex = value;
              });
            },
          ),
          LabelSwitchForm(
            title: '本地对等端发现 (LSD)',
            value: _lsd,
            onChanged: (value) {
              setState(() {
                _lsd = value;
              });
            },
          ),
          LabelSwitchForm(
            title: '匿名模式',
            value: _anonymousMode,
            onChanged: (value) {
              setState(() {
                _anonymousMode = value;
              });
            },
          ),
          LabelSwitchForm(
            title: '解析对等端主机名',
            value: _resolvePeerHostNames,
            onChanged: (value) {
              setState(() {
                _resolvePeerHostNames = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWebUiSection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text('Web 界面', style: Theme.of(context).textTheme.titleMedium),
        ),
        children: [
          LabelTextFieldForm(
            title: 'Web UI 端口',
            controller: _webUiPortController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: '会话超时 (秒)',
            tip: 'Cookie 过期时间',
            controller: _webUiSessionTimeoutController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: 'Web API 密钥',
            tip: _preferences!.webUiApiKey.isEmpty
                ? '可选'
                : '已配置密钥；填入新值将覆盖',
            controller: _webUiApiKeyController,
            obscureText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTorrentManagementSection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            'Torrent 管理',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        children: [
          LabelSwitchForm(
            title: 'Torrent 排队',
            value: _queueingEnabled,
            onChanged: (value) {
              setState(() {
                _queueingEnabled = value;
              });
            },
          ),
          LabelTextFieldForm(
            title: '最大活跃检查 Torrent 数',
            controller: _maxActiveCheckingTorrentsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: '最大活动的下载数',
            controller: _maxActiveDownloadsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: '最大活动的上传数',
            controller: _maxActiveUploadsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          LabelTextFieldForm(
            title: '最大活动的 torrent 数',
            controller: _maxActiveTorrentsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text('安全设置', style: Theme.of(context).textTheme.titleMedium),
        ),

        children: [
          LabelSwitchForm(
            title: '启用“点击劫持”保护',
            value: _webUiClickjackingProtectionEnabled,
            onChanged: (value) {
              setState(() {
                _webUiClickjackingProtectionEnabled = value;
              });
            },
          ),
          LabelSwitchForm(
            title: '启用跨站请求伪造 (CSRF) 保护',
            value: _webUiCsrfProtectionEnabled,
            onChanged: (value) {
              setState(() {
                _webUiCsrfProtectionEnabled = value;
              });
            },
          ),
          LabelSwitchForm(
            title: '启用 cookie 安全标志',
            value: _webUiSecureCookieEnabled,
            onChanged: (value) {
              setState(() {
                _webUiSecureCookieEnabled = value;
              });
            },
          ),
          LabelSwitchForm(
            title: '启用 Host header 属性验证',
            value: _webUiHostHeaderValidationEnabled,
            onChanged: (value) {
              setState(() {
                _webUiHostHeaderValidationEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadReadOnlySection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            '只读-下载, 如有需求请提交 Issure',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        children: [
          _buildReadOnlyItem(
            '导出目录',
            _preferences!.exportDir.isEmpty ? '未设置' : _preferences!.exportDir,
          ),
          _buildReadOnlyItem(
            '完成导出目录',
            _preferences!.exportDirFin.isEmpty
                ? '未设置'
                : _preferences!.exportDirFin,
          ),
          _buildReadOnlyItem('自动删除模式', _preferences!.autoDeleteMode.toString()),
          _buildReadOnlyItem(
            '预分配所有文件',
            _preferences!.preallocateAll ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '使用不需要的文件夹',
            _preferences!.useUnwantedFolder ? '是' : '否',
          ),
          _buildReadOnlyItem(
            'Torrent 内容布局',
            _preferences!.torrentContentLayout,
          ),
          _buildReadOnlyItem(
            'Torrent 停止条件',
            _preferences!.torrentStopCondition,
          ),
          _buildReadOnlyItem(
            'Torrent 文件大小限制',
            _preferences!.torrentFileSizeLimit.toHumanReadableFileSize(),
          ),
          _buildReadOnlyItem(
            '确认删除',
            _preferences!.confirmTorrentDeletion ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '确认重新检查',
            _preferences!.confirmTorrentRecheck ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '重新检查完成的 Torrent',
            _preferences!.recheckCompletedTorrents ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '删除 Torrent 内容文件',
            _preferences!.deleteTorrentContentFiles ? '是' : '否',
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionReadOnlySection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            '只读-连接, 如有需求请提交 Issure',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        children: [
          _buildReadOnlyItem('最大连接数', _preferences!.maxConnec.toString()),
          _buildReadOnlyItem(
            '解析对等端国家/地区',
            _preferences!.resolvePeerCountries ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '主机名缓存 TTL',
            '${_preferences!.hostnameCacheTtl} 秒',
          ),
          _buildReadOnlyItem(
            '每个 Torrent 最大连接数',
            _preferences!.maxConnecPerTorrent.toString(),
          ),
          _buildReadOnlyItem('最大上传数', _preferences!.maxUploads.toString()),
          _buildReadOnlyItem(
            '每个 Torrent 最大上传数',
            _preferences!.maxUploadsPerTorrent.toString(),
          ),
          _buildReadOnlyItem(
            '当前网络接口',
            _preferences!.currentNetworkInterface.isEmpty
                ? '未设置'
                : _preferences!.currentNetworkInterface,
          ),
          _buildReadOnlyItem(
            '当前接口名称',
            _preferences!.currentInterfaceName.isEmpty
                ? '未设置'
                : _preferences!.currentInterfaceName,
          ),
          _buildReadOnlyItem(
            '当前接口地址',
            _preferences!.currentInterfaceAddress.isEmpty
                ? '未设置'
                : _preferences!.currentInterfaceAddress,
          ),
          _buildReadOnlyItem('连接速度', '${_preferences!.connectionSpeed}'),
          _buildReadOnlyItem('UPnP', _preferences!.upnp ? '启用' : '禁用'),
          _buildReadOnlyItem(
            'UPnP 租期时长',
            _preferences!.upnpLeaseDuration.toString(),
          ),
          _buildReadOnlyItem(
            '出站端口范围',
            _preferences!.outgoingPortsMin == 0 &&
                    _preferences!.outgoingPortsMax == 0
                ? '随机'
                : '${_preferences!.outgoingPortsMin}-${_preferences!.outgoingPortsMax}',
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedLimitReadOnlySection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            '只读-速度限制, 如有需求请提交 Issure',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        children: [
          _buildReadOnlyItem(
            '下载速度限制',
            _preferences!.dlLimit == 0
                ? '无限制'
                : '${(_preferences!.dlLimit / 1024).toStringAsFixed(0)} KB/s',
          ),
          _buildReadOnlyItem(
            '上传速度限制',
            _preferences!.upLimit == 0
                ? '无限制'
                : '${(_preferences!.upLimit / 1024).toStringAsFixed(0)} KB/s',
          ),
          _buildReadOnlyItem(
            '限制 UTP 速率',
            _preferences!.limitUtpRate ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '限制 TCP 开销',
            _preferences!.limitTcpOverhead ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '限制局域网对等点',
            _preferences!.limitLanPeers ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '慢速 Torrent 下载速率阈值',
            '${_preferences!.slowTorrentDlRateThreshold} KB/s',
          ),
          _buildReadOnlyItem(
            '慢速 Torrent 上传速率阈值',
            '${_preferences!.slowTorrentUlRateThreshold} KB/s',
          ),
          _buildReadOnlyItem(
            '慢速 Torrent 非活动计时器',
            '${_preferences!.slowTorrentInactiveTimer} 秒',
          ),
          _buildReadOnlyItem(
            '不计算慢速 Torrent',
            _preferences!.dontCountSlowTorrents ? '是' : '否',
          ),
        ],
      ),
    );
  }

  Widget _buildBitTorrentReadOnlySection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            '只读-BitTorrent, 如有需求请提交 Issure',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        children: [
          _buildReadOnlyItem('DHT 引导节点', _preferences!.dhtBootstrapNodes),
          _buildReadOnlyItem(
            '解析对等端主机名',
            _preferences!.resolvePeerHostNames ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '加密',
            _preferences!.encryption == 0
                ? '允许'
                : _preferences!.encryption == 1
                ? '首选'
                : '强制',
          ),
          _buildReadOnlyItem(
            'BitTorrent 协议',
            _preferences!.bittorrentProtocol == 0
                ? 'TCP 和 uTP'
                : _preferences!.bittorrentProtocol == 1
                ? '仅 TCP'
                : '仅 uTP',
          ),
          _buildReadOnlyItem(
            'UTP-TCP 混合模式',
            _preferences!.utpTcpMixedMode == 0
                ? '禁用'
                : _preferences!.utpTcpMixedMode == 1
                ? '启用'
                : 'TCP 优先',
          ),
          _buildReadOnlyItem(
            '阻止特权端口上的对等点',
            _preferences!.blockPeersOnPrivilegedPorts ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '启用同一 IP 的多连接',
            _preferences!.enableMultiConnectionsFromSameIp ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '验证 HTTPS Tracker 证书',
            _preferences!.validateHttpsTrackerCertificate ? '是' : '否',
          ),
          _buildReadOnlyItem(
            'SSRF 缓解',
            _preferences!.ssrfMitigation ? '启用' : '禁用',
          ),
          _buildReadOnlyItem(
            '向所有层宣布',
            _preferences!.announceToAllTiers ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '向所有 Tracker 宣布',
            _preferences!.announceToAllTrackers ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '宣布 IP',
            _preferences!.announceIp.isEmpty ? '未设置' : _preferences!.announceIp,
          ),
          _buildReadOnlyItem(
            '宣布端口',
            _preferences!.announcePort == 0
                ? '未设置'
                : _preferences!.announcePort.toString(),
          ),
          _buildReadOnlyItem(
            '最大并发 HTTP 宣布',
            _preferences!.maxConcurrentHttpAnnounces.toString(),
          ),
          _buildReadOnlyItem(
            '停止 Tracker 超时',
            '${_preferences!.stopTrackerTimeout} 秒',
          ),
          _buildReadOnlyItem('对等点 TOS', _preferences!.peerTos.toString()),
          _buildReadOnlyItem('对等点周转', _preferences!.peerTurnover.toString()),
          _buildReadOnlyItem(
            '对等点周转截止',
            _preferences!.peerTurnoverCutoff.toString(),
          ),
          _buildReadOnlyItem(
            '对等点周转间隔',
            '${_preferences!.peerTurnoverInterval} 秒',
          ),
          _buildReadOnlyItem(
            '上传阻塞算法',
            _preferences!.uploadChokingAlgorithm == 0 ? '固定槽位' : '速率',
          ),
          _buildReadOnlyItem(
            '上传槽位行为',
            _preferences!.uploadSlotsBehavior == 0 ? '固定槽位' : '上传速率',
          ),
          _buildReadOnlyItem(
            '启用上传建议',
            _preferences!.enableUploadSuggestions ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '合并 Tracker',
            _preferences!.mergeTrackers ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '添加 Tracker 启用',
            _preferences!.addTrackersEnabled ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '添加 Tracker',
            _preferences!.addTrackers.isEmpty
                ? '未设置'
                : _preferences!.addTrackers,
          ),
        ],
      ),
    );
  }

  Widget _buildWebUIReadOnlySection() {
    return SliverToBoxAdapter(
      child: CupertinoListSection.insetGrouped(
        header: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
          child: Text(
            '只读-Web UI, 如有需求请提交 Issure',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        children: [
          _buildReadOnlyItem('Web UI 地址', _preferences!.webUiAddress),
          _buildReadOnlyItem(
            'Web API 密钥',
            _preferences!.webUiApiKey.isEmpty ? '未配置' : '***',
          ),
          _buildReadOnlyItem('Web UI 用户名', _preferences!.webUiUsername),
          _buildReadOnlyItem(
            'Web UI 会话超时',
            '${_preferences!.webUiSessionTimeout} 秒',
          ),
          _buildReadOnlyItem('使用 HTTPS', _preferences!.useHttps ? '是' : '否'),
          _buildReadOnlyItem(
            'Web UI HTTPS 证书路径',
            _preferences!.webUiHttpsCertPath.isEmpty
                ? '未设置'
                : _preferences!.webUiHttpsCertPath,
          ),
          _buildReadOnlyItem(
            'Web UI HTTPS 密钥路径',
            _preferences!.webUiHttpsKeyPath.isEmpty
                ? '未设置'
                : _preferences!.webUiHttpsKeyPath,
          ),
          _buildReadOnlyItem(
            'Web UI UPnP',
            _preferences!.webUiUpnp ? '启用' : '禁用',
          ),
          _buildReadOnlyItem('Web UI 域名列表', _preferences!.webUiDomainList),
          _buildReadOnlyItem(
            '绕过本地认证',
            _preferences!.bypassLocalAuth ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '绕过认证子网白名单启用',
            _preferences!.bypassAuthSubnetWhitelistEnabled ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '绕过认证子网白名单',
            _preferences!.bypassAuthSubnetWhitelist.isEmpty
                ? '未设置'
                : _preferences!.bypassAuthSubnetWhitelist,
          ),
          _buildReadOnlyItem(
            'Web UI 最大认证失败次数',
            _preferences!.webUiMaxAuthFailCount.toString(),
          ),
          _buildReadOnlyItem(
            'Web UI 封禁时长',
            '${_preferences!.webUiBanDuration} 秒',
          ),
          _buildReadOnlyItem(
            '替代 Web UI 启用',
            _preferences!.alternativeWebuiEnabled ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '替代 Web UI 路径',
            _preferences!.alternativeWebuiPath.isEmpty
                ? '未设置'
                : _preferences!.alternativeWebuiPath,
          ),
          _buildReadOnlyItem(
            '使用自定义 HTTP 头启用',
            _preferences!.webUiUseCustomHttpHeadersEnabled ? '是' : '否',
          ),
          _buildReadOnlyItem(
            'Web UI 自定义 HTTP 头',
            _preferences!.webUiCustomHttpHeaders.isEmpty
                ? '未设置'
                : _preferences!.webUiCustomHttpHeaders,
          ),
          _buildReadOnlyItem(
            '反向代理启用',
            _preferences!.webUiReverseProxyEnabled ? '是' : '否',
          ),
          _buildReadOnlyItem(
            '反向代理列表',
            _preferences!.webUiReverseProxiesList.isEmpty
                ? '未设置'
                : _preferences!.webUiReverseProxiesList,
          ),
          _buildReadOnlyItem('语言', _preferences!.locale),
          _buildReadOnlyItem('刷新间隔', '${_preferences!.refreshInterval}ms'),
          _buildReadOnlyItem(
            '状态栏外部 IP',
            _preferences!.statusBarExternalIp ? '显示' : '隐藏',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('qBittorrent 设置'),
        actions: [
          IconButton(
            onPressed: _preferences != null && !_isLoading ? _save : null,
            icon: const Icon(Icons.save),
            tooltip: '保存',
          ),
        ],
      ),
      body: KeyboardDismissOnTap(
        child: _isLoading && _preferences == null
            ? const Center(child: CircularProgressIndicator())
            : _preferences == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text('无法加载设置'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPreferences,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  _buildFileSaveSection(),
                  _buildConnectionSection(),
                  _buildBitTorrentSection(),
                  _buildSpeedLimitSection(),
                  _buildTorrentManagementSection(),
                  _buildSecuritySection(),
                  _buildWebUiSection(),
                  _buildDownloadReadOnlySection(),
                  _buildConnectionReadOnlySection(),
                  _buildSpeedLimitReadOnlySection(),

                  _buildBitTorrentReadOnlySection(),

                  _buildWebUIReadOnlySection(),
                ],
              ),
      ),
    );
  }

  Widget _buildReadOnlyItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
