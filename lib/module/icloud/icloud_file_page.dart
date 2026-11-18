import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icloud_storage_plus/icloud_storage.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/empty_widget.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';

class IcloudFilePage extends ConsumerStatefulWidget {
  const IcloudFilePage({super.key});

  @override
  ConsumerState<IcloudFilePage> createState() => IcloudFilePageState();
}

class IcloudFilePageState extends ConsumerState<IcloudFilePage> {
  List<ICloudFile> list = [];
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    final bool dark = ref.watch(themeProvider).themeMode == modeDark;
    final ThemeColors themeColor = ref.watch(themeProvider).themeColor;
    final Color borderColor = dark
        ? const Color(0xFF2E2E31)
        : const Color(0xFFE6E8EC);

    return Scaffold(
      backgroundColor: themeColor.bg2Color(),
      appBar: QlAppBar(title: "iCloud文件"),
      body: loading
          ? const Center(child: LoadingWidget())
          : list.isEmpty
          ? const Center(child: EmptyWidget())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (c, index) {
                final file = list[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.settingBgColor(),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      file.isDirectory
                          ? CupertinoIcons.folder
                          : CupertinoIcons.doc_text,
                      size: 22,
                      color: ref.watch(themeProvider).primaryColor,
                    ),
                    title: Text(
                      file.relativePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: themeColor.titleColor(),
                      ),
                    ),
                    subtitle: Text(
                      file.isDirectory ? "文件夹" : formatSize(file.sizeInBytes),
                      style: TextStyle(
                        fontSize: 12,
                        color: themeColor.descColor(),
                      ),
                    ),
                  ),
                );
              },
              itemCount: list.length,
            ),
    );
  }

  String formatSize(int? length) {
    final int size = length ?? 0;
    if (size < 1024) return "$size B";
    if (size < 1024 * 1024) return "${(size / 1024).toStringAsFixed(1)} KB";
    return "${(size / 1024 / 1024).toStringAsFixed(1)} MB";
  }

  Future<void> getFiles() async {
    try {
      final bool available = await ICloudStorage.icloudAvailable();
      if (!available) {
        "iCloud 不可用，请检查登录状态".toast();
        if (mounted) setState(() => loading = false);
        return;
      }

      final result = await ICloudStorage.gather(
        containerId: ICloudUtils.containerID,
      );
      list.clear();
      list.addAll(result.files);
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      "获取iCloud文件失败".toast();
      if (mounted) setState(() => loading = false);
    }
  }
}
