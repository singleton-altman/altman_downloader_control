import 'package:altman_downloader_control/controller/qbittorrent/qb_controller.dart';
import 'package:altman_downloader_control/utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 显示 category picker 对话框
Future<String?> showQBCategoryPicker(
  BuildContext context,
  QBController controller,
) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QBCategoryPicker(controller: controller),
  );
}

/// qBittorrent 分类选择器
class QBCategoryPicker extends StatefulWidget {
  const QBCategoryPicker({super.key, required this.controller});

  final QBController controller;

  @override
  State<QBCategoryPicker> createState() => _QBCategoryPickerState();
}

class _QBCategoryPickerState extends State<QBCategoryPicker> {
  late final QBController controller = widget.controller;
  final categories = <String, dynamic>{}.obs;
  final isLoading = false.obs;
  final isCreating = false.obs;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    isLoading.value = true;
    try {
      final result = await controller.getCategories();
      categories.value = result;
    } catch (e) {
      showToast(message: '加载分类列表失败: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createCategory() async {
    final categoryController = TextEditingController();
    final savePathController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建分类'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                  hintText: '请输入分类名称',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: savePathController,
                decoration: const InputDecoration(
                  labelText: '保存路径（可选）',
                  hintText: '例如：/downloads/movies',
                  border: OutlineInputBorder(),
                  helperText: '留空则使用默认路径',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final categoryName = categoryController.text.trim();
              if (categoryName.isEmpty) {
                showToast(message: '请输入分类名称');
                return;
              }
              // 检查分类是否已存在
              if (categories.containsKey(categoryName)) {
                showToast(message: '分类已存在');
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true) {
      final categoryName = categoryController.text.trim();
      final savePath = savePathController.text.trim();
      isCreating.value = true;
      try {
        final success = await controller.createCategory(
          category: categoryName,
          savePath: savePath.isEmpty ? null : savePath,
        );
        if (success) {
          showToast(message: '创建成功');
          // 重新加载分类列表
          await _loadCategories();
        } else {
          showToast(message: '创建失败');
        }
      } catch (e) {
        showToast(message: '创建失败: ${e.toString()}');
      } finally {
        isCreating.value = false;
        categoryController.dispose();
        savePathController.dispose();
      }
    } else {
      categoryController.dispose();
      savePathController.dispose();
    }
  }

  String _getSavePath(dynamic categoryInfo) {
    if (categoryInfo is Map && categoryInfo.containsKey('savePath')) {
      return categoryInfo['savePath'] as String? ?? '';
    }
    return '';
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
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 标题栏
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      '选择分类',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // 创建按钮
                    Obx(
                      () => IconButton(
                        icon: isCreating.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        onPressed: isCreating.value ? null : _createCategory,
                        tooltip: '创建分类',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '关闭',
                    ),
                  ],
                ),
              ),
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: '搜索分类...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              // 分类列表
              Expanded(
                child: Obx(() {
                  if (isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final searchText = searchController.text.toLowerCase();
                  final filteredCategories = categories.entries.where((entry) {
                    if (searchText.isEmpty) return true;
                    return entry.key.toLowerCase().contains(searchText);
                  }).toList();

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchText.isEmpty ? '暂无分类' : '未找到匹配的分类',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (searchText.isEmpty)
                            ElevatedButton.icon(
                              onPressed: _createCategory,
                              icon: const Icon(Icons.add),
                              label: const Text('创建分类'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredCategories.length + 1, // +1 用于"无分类"选项
                    itemBuilder: (context, index) {
                      // "无分类"选项（清除分类）
                      if (index == 0 && searchText.isEmpty) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              Icons.cancel_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: const Text('无分类'),
                            subtitle: const Text('清除当前分类'),
                            onTap: () => Navigator.of(context).pop(''),
                          ),
                        );
                      }

                      // 实际的分类项
                      final actualIndex = searchText.isEmpty
                          ? index - 1
                          : index;
                      final entry = filteredCategories[actualIndex];
                      final categoryName = entry.key;
                      final savePath = _getSavePath(entry.value);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.category,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: savePath.isNotEmpty
                              ? Text(
                                  '路径: $savePath',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onTap: () => Navigator.of(context).pop(categoryName),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
