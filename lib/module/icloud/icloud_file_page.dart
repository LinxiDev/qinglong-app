import 'package:material_ui/material_ui.dart';
import 'package:icloud_storage_plus/icloud_storage.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/icloud_utils.dart';

class IcloudFilePage extends StatefulWidget {
  const IcloudFilePage({super.key});

  @override
  IcloudFilePageState createState() => IcloudFilePageState();
}

class IcloudFilePageState extends State<IcloudFilePage> {
  List<ICloudFile> list = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(title: "iCloud文件"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemBuilder: (c, index) {
                final file = list[index];
                return ListTile(
                  title: Text(
                    file.relativePath,
                    style: const TextStyle(fontSize: 16),
                  ),
                  subtitle: file.isDirectory
                      ? const Text("文件夹")
                      : Text(formatSize(file.sizeInBytes)),
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
