import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 显示 tag picker 对话框（支持多选）
/// 返回选中的标签列表
Future<List<String>?> showQBTagPicker(
  BuildContext context, {
  required List<String> initialSelectedTags,
  required QBController controller,
}) async {
  return await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QBTagPicker(
      initialSelectedTags: initialSelectedTags,
      controller: controller,
    ),
  );
}

/// qBittorrent 标签选择器（支持多选和反选）
class QBTagPicker extends StatefulWidget {
  const QBTagPicker({
    super.key,
    required this.initialSelectedTags,
    required this.controller,
  });

  final QBController controller;
  final List<String> initialSelectedTags;

  @override
  State<QBTagPicker> createState() => _QBTagPickerState();
}

class _QBTagPickerState extends State<QBTagPicker> {
  late final QBController controller = widget.controller;
  final allTags = <String>[].obs;
  final selectedTags = RxSet<String>();
  final isLoading = false.obs;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化已选中的标签
    selectedTags.addAll(widget.initialSelectedTags);
    _loadTags();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    isLoading.value = true;
    try {
      final result = await controller.getAllTags();
      allTags.value = result;
    } catch (e) {
      showToast(message: '加载标签列表失败: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
    // RxSet 会自动触发更新，但为了确保，可以调用 refresh
    selectedTags.refresh();
  }

  Future<void> _createTag() async {
    // Dialog 返回用户输入的标签名，如果取消则返回 null
    final tagName = await showDialog<String>(
      context: context,
      builder: (context) => _CreateTagDialog(allTags: allTags),
    );

    // 如果用户输入了标签名，则添加到列表并选中
    if (tagName != null && tagName.isNotEmpty) {
      if (!allTags.contains(tagName)) {
        allTags.add(tagName);
        allTags.sort();
        selectedTags.add(tagName);
        selectedTags.refresh();
      }
    }
  }

  void _selectAll() {
    selectedTags.clear();
    selectedTags.addAll(allTags);
    selectedTags.refresh();
  }

  void _deselectAll() {
    selectedTags.clear();
    selectedTags.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '选择标签',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // 全选/取消全选按钮
                    Obx(
                      () => TextButton(
                        onPressed: allTags.isEmpty
                            ? null
                            : selectedTags.length == allTags.length
                            ? _deselectAll
                            : _selectAll,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          selectedTags.length == allTags.length ? '取消全选' : '全选',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    // 创建按钮
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _createTag,
                      tooltip: '创建标签',
                      iconSize: 22,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '搜索标签...',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              // 已选标签数量提示
              Obx(
                () => selectedTags.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          right: 20.0,
                          top: 12.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '已选择 ${selectedTags.length} 个标签',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              // 标签列表
              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final searchText = searchController.text.toLowerCase();
                  final filteredTags = allTags.where((tag) {
                    if (searchText.isEmpty) return true;
                    return tag.toLowerCase().contains(searchText);
                  }).toList();

                  if (filteredTags.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.label_off_outlined,
                            size: 56,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            searchText.isEmpty ? '暂无标签' : '未找到匹配的标签',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (searchText.isEmpty)
                            ElevatedButton.icon(
                              onPressed: _createTag,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                '创建标签',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8.0,
                    ),
                    itemCount: filteredTags.length,
                    separatorBuilder: (context, index) => Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.15),
                    ),
                    itemBuilder: (context, index) {
                      final tag = filteredTags[index];

                      // 使用 Obx 包裹每个 item，确保响应 selectedTags 的变化
                      return Obx(() {
                        final isSelected = selectedTags.contains(tag);

                        return InkWell(
                          onTap: () => _toggleTag(tag),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 14.0,
                            ),
                            child: Row(
                              children: [
                                // 选中状态图标 - 简化设计
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 22,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 14),
                                // 标签图标和名称
                                Icon(
                                  Icons.label_outline,
                                  size: 18,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 14,
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                    },
                  );
                }),
              ),
              // 底部操作栏
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.15),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Obx(
                      () => Text(
                        '已选择 ${selectedTags.length} 个',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('取消', style: TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(selectedTags.toList());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('确定', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 创建标签对话框 - 使用延迟聚焦避免渲染树问题
/// 返回用户输入的标签名，如果取消则返回 null
class _CreateTagDialog extends StatefulWidget {
  final List<String> allTags;

  const _CreateTagDialog({required this.allTags});

  @override
  State<_CreateTagDialog> createState() => _CreateTagDialogState();
}

class _CreateTagDialogState extends State<_CreateTagDialog> {
  final _tagController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 延迟聚焦，等待渲染树完全构建
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitTag() {
    final tagName = _tagController.text.trim();
    if (tagName.isEmpty) {
      showToast(message: '请输入标签名称');
      return;
    }
    // 检查标签是否已存在
    if (widget.allTags.contains(tagName)) {
      showToast(message: '标签已存在');
      return;
    }
    // 返回标签名
    Navigator.of(context).pop(tagName);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建标签'),
      content: TextField(
        controller: _tagController,
        focusNode: _focusNode,
        decoration: const InputDecoration(
          labelText: '标签名称',
          hintText: '请输入标签名称',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submitTag(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _submitTag, child: const Text('创建')),
      ],
    );
  }
}
