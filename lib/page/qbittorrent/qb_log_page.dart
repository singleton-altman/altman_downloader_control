import 'dart:async';
import 'dart:ui';
import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/model/qb_log_model.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

enum _QBLogSortKey { time, level, id }

/// qBittorrent 日志页面
class QBLogPage extends StatefulWidget {
  final QBController controller;

  const QBLogPage({super.key, required this.controller});

  @override
  State<QBLogPage> createState() => _QBLogPageState();
}

class _QBLogPageState extends State<QBLogPage> {
  final ScrollController _scrollController = ScrollController();

  // 过滤器状态
  bool _showNormal = true;
  bool _showInfo = true;
  bool _showWarning = true;
  bool _showCritical = true;

  String _searchKeyword = '';
  Timer? _autoRefreshTimer;
  bool _autoRefresh = false;
  _QBLogSortKey _sortKey = _QBLogSortKey.time;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    // 初始化时加载日志
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshLogs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLogs() async {
    await widget.controller.refreshLogs(
      normal: _showNormal,
      info: _showInfo,
      warning: _showWarning,
      critical: _showCritical,
      incremental: false,
    );
  }

  Future<void> _refreshLogsIncremental() async {
    await widget.controller.refreshLogs(
      normal: _showNormal,
      info: _showInfo,
      warning: _showWarning,
      critical: _showCritical,
      incremental: true,
    );
  }

  // 用于 StatefulBuilder 的更新方法
  void _updateAutoRefreshState(StateSetter setState) {
    setState(() {
      _autoRefresh = !_autoRefresh;
      if (_autoRefresh) {
        // 启动自动刷新，每 3 秒刷新一次
        _autoRefreshTimer = Timer.periodic(
          const Duration(seconds: 3),
          (_) => _refreshLogsIncremental(),
        );
      } else {
        _autoRefreshTimer?.cancel();
        _autoRefreshTimer = null;
      }
    });
  }

  /// 获取过滤后的日志列表
  List<QBLogEntry> get _filteredLogs {
    final result = widget.controller.logs.where((log) {
      // 按级别过滤
      if (!_showNormal && log.isNormal) return false;
      if (!_showInfo && log.isInfo) return false;
      if (!_showWarning && log.isWarning) return false;
      if (!_showCritical && log.isCritical) return false;

      // 按关键词过滤
      if (_searchKeyword.isNotEmpty) {
        if (!log.message.toLowerCase().contains(_searchKeyword)) {
          return false;
        }
      }

      return true;
    }).toList();

    int severity(QBLogEntry log) {
      if (log.isCritical) return 4;
      if (log.isWarning) return 3;
      if (log.isInfo) return 2;
      return 1;
    }

    int direction(int value) => _sortAscending ? value : -value;

    result.sort((a, b) {
      switch (_sortKey) {
        case _QBLogSortKey.time:
          final byTime = direction(a.timestamp.compareTo(b.timestamp));
          if (byTime != 0) return byTime;
          return direction(a.id.compareTo(b.id));
        case _QBLogSortKey.level:
          final byLevel = direction(severity(a).compareTo(severity(b)));
          if (byLevel != 0) return byLevel;
          return direction(a.timestamp.compareTo(b.timestamp));
        case _QBLogSortKey.id:
          return direction(a.id.compareTo(b.id));
      }
    });

    return result;
  }

  /// 获取日志级别的颜色（适配暗黑和浅色模式）
  Color _getLogColor(QBLogEntry log, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (log.isCritical) {
      return isDark ? Colors.red.shade400 : Colors.red.shade600;
    } else if (log.isWarning) {
      return isDark ? Colors.orange.shade400 : Colors.orange.shade600;
    } else if (log.isInfo) {
      return isDark ? Colors.blue.shade400 : Colors.blue.shade600;
    } else {
      return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  /// 获取日志级别的背景颜色（适配暗黑和浅色模式）
  Color _getLogBackgroundColor(QBLogEntry log, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (log.isCritical) {
      return isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
    } else if (log.isWarning) {
      return isDark
          ? Colors.orange.withValues(alpha: 0.15)
          : Colors.orange.shade50;
    } else if (log.isInfo) {
      return isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50;
    } else {
      return isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.shade50;
    }
  }

  /// 获取日志级别的图标
  IconData _getLogIcon(QBLogEntry log) {
    if (log.isCritical) {
      return Icons.error;
    } else if (log.isWarning) {
      return Icons.warning;
    } else if (log.isInfo) {
      return Icons.info;
    } else {
      return Icons.circle;
    }
  }

  /// 格式化时间戳
  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return '';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // 如果是今天，只显示时间
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat('HH:mm:ss').format(dateTime);
    }
    // 如果是昨天
    if (difference.inDays == 1) {
      return '昨天 ${DateFormat('HH:mm:ss').format(dateTime)}';
    }
    // 如果是一周内，显示星期几
    if (difference.inDays < 7) {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      final weekdayIndex = dateTime.weekday - 1;
      return '${weekdays[weekdayIndex]} ${DateFormat('HH:mm').format(dateTime)}';
    }
    // 其他情况显示完整日期时间
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingBar(context),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Flexible(child: Text('日志')),
          ],
        ),
        actions: [
          // 自动刷新开关
          StatefulBuilder(
            builder: (context, setState) => IconButton(
              icon: Icon(
                _autoRefresh ? Icons.pause : Icons.play_arrow,
                color: _autoRefresh
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => _updateAutoRefreshState(setState),
              tooltip: _autoRefresh ? '停止自动刷新' : '开始自动刷新',
            ),
          ),
        ],
      ),
      body: Obx(() {
        final errorMessage = widget.controller.logErrorMessage.value;
        final isLoading = widget.controller.isLoadingLogs.value;
        final filteredLogs = _filteredLogs;

        if (errorMessage.isNotEmpty && filteredLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshLogs,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (filteredLogs.isEmpty && !isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchKeyword.isNotEmpty ||
                          !_showNormal ||
                          !_showInfo ||
                          !_showWarning ||
                          !_showCritical
                      ? '没有匹配的日志'
                      : '暂无日志',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshLogs,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 日志列表
              if (filteredLogs.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final log = filteredLogs[index];
                      return _buildLogItem(log);
                    }, childCount: filteredLogs.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLogItem(QBLogEntry log) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logColor = _getLogColor(log, context);
    final backgroundColor = _getLogBackgroundColor(log, context);
    final icon = _getLogIcon(log);
    final timestamp = _formatTimestamp(log.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: logColor, width: 3)),
        boxShadow: isDark
            ? [
                // 暗色模式：使用更柔和的阴影
                BoxShadow(
                  color: logColor.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                // 浅色模式：使用标准阴影
                BoxShadow(
                  color: logColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 点击可以复制日志内容
            _showLogDetailDialog(log);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 时间戳和级别标签
                Row(
                  children: [
                    // 级别标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? logColor.withValues(alpha: 0.25)
                            : logColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 12, color: logColor),
                          const SizedBox(width: 4),
                          Text(
                            log.typeName.toUpperCase(),
                            style: TextStyle(
                              color: logColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // 时间戳
                    if (timestamp.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timestamp,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // 日志消息
                SelectableText(
                  log.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
                // 日志 ID（小字显示）
                const SizedBox(height: 6),
                Text(
                  'ID: ${log.id}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogDetailDialog(QBLogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getLogIcon(log), color: _getLogColor(log, context), size: 20),
            const SizedBox(width: 8),
            Text(
              log.typeName.toUpperCase(),
              style: TextStyle(
                color: _getLogColor(log, context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (log.timestamp > 0) ...[
                Text(
                  '时间: ${_formatTimestamp(log.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'ID: ${log.id}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Text('消息:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SelectableText(
                log.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 复制日志内容
              Clipboard.setData(ClipboardData(text: log.message));
              showToast(message: '已复制到剪贴板');
              Navigator.of(context).pop();
            },
            child: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      !_showNormal || !_showInfo || !_showWarning || !_showCritical;

  String get _sortLabel {
    switch (_sortKey) {
      case _QBLogSortKey.time:
        return '时间';
      case _QBLogSortKey.level:
        return '级别';
      case _QBLogSortKey.id:
        return 'ID';
    }
  }

  Widget _buildFloatingBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                _buildFloatingFilterButton(context),
                const SizedBox(width: 10),
                Expanded(child: _buildFakeSearchBar(context)),
                const SizedBox(width: 10),
                _buildFloatingSortButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingFilterButton(BuildContext context) {
    final theme = Theme.of(context);
    final color = _hasActiveFilters
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _openFilterSheet,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(CupertinoIcons.slider_horizontal_3, color: color, size: 20),
      ),
    );
  }

  Widget _buildFakeSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final hasKeyword = _searchKeyword.isNotEmpty;
    return GestureDetector(
      onTap: _openKeywordSheet,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.search,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasKeyword ? _searchKeyword : '搜索日志内容',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: hasKeyword ? 0.9 : 0.65,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSortButton(BuildContext context) {
    final icon = _sortAscending ? Icons.north : Icons.south;
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.78);
    return PopupMenuButton<_QBLogSortKey>(
      tooltip: '排序',
      onSelected: (value) {
        setState(() {
          if (_sortKey == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortKey = value;
          }
        });
      },
      itemBuilder: (context) => [
        _buildSortMenuItem(_QBLogSortKey.time, '按时间'),
        _buildSortMenuItem(_QBLogSortKey.level, '按级别'),
        _buildSortMenuItem(_QBLogSortKey.id, '按ID'),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Icon(Icons.sort_rounded, size: 18, color: color),
            const SizedBox(width: 4),
            Text(_sortLabel, style: TextStyle(fontSize: 12.5, color: color)),
            const SizedBox(width: 2),
            Icon(icon, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_QBLogSortKey> _buildSortMenuItem(
    _QBLogSortKey key,
    String label,
  ) {
    return PopupMenuItem<_QBLogSortKey>(
      value: key,
      child: Row(
        children: [
          Icon(
            key == _sortKey
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _openKeywordSheet() async {
    final textController = TextEditingController(text: _searchKeyword);
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
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemBackground,
                ctx,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: CupertinoSearchTextField(
              controller: textController,
              autofocus: true,
              placeholder: '搜索日志内容',
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ),
        );
      },
    );
    textController.dispose();
    if (submitted == null) return;
    setState(() {
      _searchKeyword = submitted.trim().toLowerCase();
    });
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> applyNow({
            bool? normal,
            bool? info,
            bool? warning,
            bool? critical,
          }) async {
            if (!mounted) return;
            setState(() {
              if (normal != null) _showNormal = normal;
              if (info != null) _showInfo = info;
              if (warning != null) _showWarning = warning;
              if (critical != null) _showCritical = critical;
            });
            await _refreshLogs();
          }

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      ctx,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '筛选日志级别',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                SwitchListTile.adaptive(
                  value: _showNormal,
                  title: const Text('普通'),
                  onChanged: (v) async {
                    setModalState(() {});
                    await applyNow(normal: v);
                  },
                ),
                SwitchListTile.adaptive(
                  value: _showInfo,
                  title: const Text('信息'),
                  onChanged: (v) async {
                    setModalState(() {});
                    await applyNow(info: v);
                  },
                ),
                SwitchListTile.adaptive(
                  value: _showWarning,
                  title: const Text('警告'),
                  onChanged: (v) async {
                    setModalState(() {});
                    await applyNow(warning: v);
                  },
                ),
                SwitchListTile.adaptive(
                  value: _showCritical,
                  title: const Text('严重'),
                  onChanged: (v) async {
                    setModalState(() {});
                    await applyNow(critical: v);
                  },
                ),
                const SizedBox(height: 46),
              ],
            ),
          );
        },
      ),
    );
  }
}
