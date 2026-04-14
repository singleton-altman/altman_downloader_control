import 'dart:async';
import 'package:altman_downloader_control/model/qb_preferences_model.dart';
import 'package:altman_downloader_control/model/server_state_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/string_utils.dart';

/// 仿 iOS 邮件底部工具栏的下载器状态浮窗
/// 支持所有下载器类型，使用通用的 ServerStateModel
class DownloaderStateWidget extends StatefulWidget {
  const DownloaderStateWidget({
    super.key,
    required this.errorMessage,
    required this.isConnected,
    required this.serverState,
    this.preferences,
    this.totalTorrentSize = 0,
    this.onAddPressed,
  });

  final String errorMessage;
  final bool isConnected;
  final ServerStateModel? serverState;
  final QBPreferencesModel? preferences; // 可选，仅 qBittorrent 支持
  final double totalTorrentSize;
  final VoidCallback? onAddPressed;

  @override
  State<DownloaderStateWidget> createState() => _DownloaderStateWidgetState();
}

class _DownloaderStateWidgetState extends State<DownloaderStateWidget> {
  List<String> _tickerMessages = const [];
  int _tickerIndex = 0;
  Timer? _tickerTimer;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _tickerMessages = _buildTickerMessages();
    _ensureTickerTimer();
  }

  @override
  void didUpdateWidget(covariant DownloaderStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextMessages = _buildTickerMessages();
    if (!listEquals(nextMessages, _tickerMessages)) {
      _tickerMessages = nextMessages;
      _tickerIndex = 0;
      _ensureTickerTimer();
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  double get diskTotal {
    if (widget.serverState == null) return 0;
    final freeSpace = widget.serverState!.freeSpaceOnDisk.toDouble();
    return freeSpace + widget.totalTorrentSize;
  }

  double get diskUsed => widget.totalTorrentSize;

  double get diskUsedPercent {
    final total = diskTotal;
    if (total <= 0) return 0;
    return diskUsed / total;
  }

  double get downloadSpeed => widget.serverState?.dlInfoSpeed.toDouble() ?? 0.0;

  double get uploadSpeed => widget.serverState?.upInfoSpeed.toDouble() ?? 0.0;

  void _ensureTickerTimer() {
    _tickerTimer?.cancel();
    if (_tickerMessages.length <= 1) {
      return;
    }
    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _tickerIndex = (_tickerIndex + 1) % _tickerMessages.length;
      });
    });
  }

  List<String> _buildTickerMessages() {
    final messages = <String>[];
    // if (widget.totalTorrentSize > 0) {
    //   messages.add(
    //     '总量 ${widget.totalTorrentSize.toInt().toHumanReadableFileSize()}',
    //   );
    // }

    final state = widget.serverState;
    if (state != null) {
      messages.add(
        '${state.alltimeDl.toInt().toHumanReadableFileSize(round: 0)} ↓ / '
        '${state.alltimeUl.toInt().toHumanReadableFileSize(round: 0)} ↑',
      );
      messages.add(
        '连接 ${state.totalPeerConnections} · 队列 ${state.totalQueuedSize.toInt().toHumanReadableFileSize()}',
      );
    }

    if (messages.isEmpty) {
      messages.add(widget.isConnected ? '等待更多统计数据' : '尚未连接下载器');
    }

    return messages;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 220),
        crossFadeState: _expanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: _buildCollapsedView(theme),
        secondChild: _buildExpandedView(theme),
      ),
    );
  }

  Widget _buildLeftSection(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.serverState;
    final statusKey =
        state?.connectionStatus ??
        (widget.isConnected ? 'connected' : 'disconnected');
    final statusColor = widget.isConnected
        ? _getConnectionStatusColor(context, statusKey)
        : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isConnected ? _getConnectionStatusText(statusKey) : '未连接',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              widget.isConnected
                  ? ' ${state?.totalPeerConnections ?? 0} 个节点'
                  : '请检查下载器状态',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (diskTotal > 0) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '容量 ${diskTotal.toInt().toHumanReadableFileSize()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (widget.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorMessage,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCenterSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSpeedBadge(
                context,
                icon: Icons.arrow_downward_rounded,
                speed: downloadSpeed,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSpeedBadge(
                context,
                icon: Icons.arrow_upward_rounded,
                speed: uploadSpeed,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTicker(BuildContext context) {
    final theme = Theme.of(context);
    final text = _tickerMessages[_tickerIndex % _tickerMessages.length];

    return Row(
      children: [
        Icon(
          Icons.autorenew_rounded,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            text,
            key: ValueKey(text),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedBadge(
    BuildContext context, {
    required IconData icon,
    required double speed,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 5),
              Text(
                speed > 0
                    ? '${speed.toInt().toHumanReadableFileSize(round: 1)}/s'
                    : '0 B/s',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getConnectionStatusColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return Theme.of(context).colorScheme.primary;
      case 'firewalled':
        return Colors.orange;
      case 'disconnected':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getConnectionStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return '已连接';
      case 'firewalled':
        return '防火墙保护';
      case 'disconnected':
        return '未连接';
      default:
        return status;
    }
  }

  Widget _buildExpandButton(ThemeData theme) {
    return _buildIconButton(
      theme,
      icon: Icons.expand_more_rounded,
      tooltip: _expanded ? '收起' : '展开',
      rotationTurns: _expanded ? 0.5 : 0.0,
      onTap: () {
        setState(() {
          _expanded = !_expanded;
        });
      },
    );
  }

  Widget _buildCollapsedView(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildCollapsedStats()),
                const SizedBox(width: 12),
                _buildExpandButton(theme),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            onPressed: widget.onAddPressed,
            icon: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLeftSection(context)),
              _buildExpandButton(theme),
            ],
          ),
          const SizedBox(height: 6),
          _buildTicker(context),
          const SizedBox(height: 12),
          _buildCenterSection(context),
        ],
      ),
    );
  }

  Widget _buildCollapsedStats() {
    final theme = Theme.of(context);
    final dht = widget.serverState?.dhtNodes ?? 0;
    return Row(
      children: [
        Expanded(
          child: _buildCollapsedItem(
            theme,
            icon: Icons.arrow_downward_rounded,
            color: theme.colorScheme.primary,
            value: _formatSpeed(downloadSpeed),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCollapsedItem(
            theme,
            icon: Icons.arrow_upward_rounded,
            color: theme.colorScheme.secondary,
            value: _formatSpeed(uploadSpeed),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCollapsedItem(
            theme,
            icon: Icons.public,
            color: theme.colorScheme.tertiary,
            value: 'DHT $dht',
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedItem(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _formatSpeed(double value) {
    return value > 0
        ? '${value.toInt().toHumanReadableFileSize(round: 1)}/s'
        : '0 B/s';
  }

  Widget _buildIconButton(
    ThemeData theme, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    double rotationTurns = 0.0,
  }) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedRotation(
          turns: rotationTurns,
          duration: const Duration(milliseconds: 220),
          child: Icon(icon, size: 24),
        ),
      ),
    );
  }
}
