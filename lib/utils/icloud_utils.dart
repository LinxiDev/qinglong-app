import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/userinfo_viewmodel.dart';
import 'package:qinglong_app/main.dart';
import 'package:qinglong_app/module/env/env_bean.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';
import 'package:qinglong_app/utils/utils.dart';
import 'package:path/path.dart' as path;

class ICloudUtils {
  static bool remindError = false;

  static String now() {
    return Utils.formatMessageTime(DateTime.now().millisecondsSinceEpoch);
  }

  static const containerID = "iCloud.work.newtab.ql";
  int index;

  ICloudUtils(this.index);

  Future<bool> asyncSubscribe(String list, {bool focusUpdate = false}) async {
    try {
      if (list.isEmpty) return true;
      if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeNormal) return true;
      if (SpUtil.getBool(spICloud, defValue: true) == false &&
          focusUpdate == false) {
        return true;
      }

      bool exist = await existContent(
        await FileUtil(index).getSubscribeDirectory(),
        list,
      );

      if (!exist) {
        await FileUtil(index).writeSubscribe(list);
      }
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> existContent(Directory d, String content) async {
    try {
      await for (FileSystemEntity fileSystemEntity in d.list()) {
        if ((await File(fileSystemEntity.path).readAsString()) == content) {
          return true;
        }
      }
      return false;
    } catch (e) {
      // 忽略异常，保持原有行为
    }
    return false;
  }

  Future<bool> asyncEnv(List<EnvBean> list, {bool focusUpdate = false}) async {
    try {
      if (list.isEmpty) return true;
      if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeNormal) return true;
      if (SpUtil.getBool(spICloud, defValue: true) == false &&
          focusUpdate == false) {
        return true;
      }
      bool exist = await existContent(
        await FileUtil(index).getEnvDirectory(),
        jsonEncode(list),
      );

      if (!exist) {
        await FileUtil(index).writeEnv(jsonEncode(list));
      }
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> asyncConfig(
    String? title,
    String? content, {
    bool focusUpdate = false,
  }) async {
    try {
      if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeNormal) return true;

      if (content == null || content.isEmpty) return true;
      if (SpUtil.getBool(spICloud, defValue: true) == false &&
          focusUpdate == false) {
        return true;
      }

      bool exist = await existContent(
        await FileUtil(index).getConfigHolDirectory(title ?? "nameNotFound.sh"),
        content,
      );

      if (!exist) {
        await FileUtil(index).writeConfig(title ?? "nameNotFound.sh", content);
      }
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  void restoreEnv(String? path) async {
    if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeNormal) return;

    if (path == null) {
      final List<PlatformFile> files = await FilePicker.pickFiles();
      if (files.isNotEmpty && files.first.path != null) {
        if (!files.first.path!.endsWith(FileUtil.env)) {
          "只支持 .${FileUtil.env} 结尾的文件".toast();
        } else {
          _handleRestoreEnv(files.first.path!);
        }
      }
    } else {
      _handleRestoreEnv(path);
    }
  }

  void restoreSubscribe(String? path) async {
    if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeNormal) return;
    if (path == null) {
      final List<PlatformFile> files = await FilePicker.pickFiles();
      if (files.isNotEmpty && files.first.path != null) {
        if (!files.first.path!.endsWith(FileUtil.subscribe)) {
          "只支持 .${FileUtil.subscribe} 结尾的文件".toast();
        } else {
          _handleRestoreSubscribe(files.first.path!);
        }
      }
    } else {
      _handleRestoreSubscribe(path);
    }
  }

  void restoreConfig(String? path) async {
    if (SpUtil.getInt(spVIP, defValue: typeNormal) == typeNormal) return;
    if (path == null) {
      final List<PlatformFile> files = await FilePicker.pickFiles();
      if (files.isNotEmpty && files.first.path != null) {
        if (!files.first.path!.endsWith(FileUtil.config)) {
          "只支持 .${FileUtil.config} 结尾的文件".toast();
        } else {
          String p = files.first.path!;
          String title = "nameNotFound.sh";

          try {
            //获取倒数第二个/的内容
            List<String> temp = p.split("/");
            if (temp.length > 1) {
              title = temp[temp.length - 2];
            }
            _handleRestoreConfig(title, p);
          } catch (e) {
            // 忽略异常，保持原有行为
          }
        }
      }
    } else {
      String title = "nameNotFound.sh";
      try {
        //获取倒数第二个/的内容
        List<String> temp = path.split("/");
        if (temp.length > 1) {
          title = temp[temp.length - 2];
        }
        _handleRestoreConfig(title, path);
      } catch (e) {
        // 忽略异常，保持原有行为
      }
    }
  }

  void _handleRestoreSubscribe(String localSubscribePath) async {
    try {
      final File file = File(localSubscribePath);
      final String contents = await file.readAsString();
      final List<dynamic> data = jsonDecode(contents);
      final Api api = Api(index);

      /// 按 alias/url 匹配现有订阅，已存在则更新，避免重复还原产生重复订阅
      final Map<String, Map<String, dynamic>> existing = {};
      final current = await api.subscribes();
      if (current.success && current.bean != null) {
        final dynamic decoded = jsonDecode(current.bean!);
        if (decoded is List) {
          for (final dynamic item in decoded) {
            if (item is Map) {
              final Map<String, dynamic> map = Map<String, dynamic>.from(item);
              final String key = (map["alias"] ?? map["url"] ?? "").toString();
              if (key.isNotEmpty) {
                existing[key] = map;
              }
            }
          }
        }
      }

      int created = 0;
      int updated = 0;
      int failed = 0;
      for (final dynamic item in data) {
        if (item is! Map) {
          continue;
        }
        final Map<String, dynamic> value = Map<String, dynamic>.from(item);
        final String key = (value["alias"] ?? value["url"] ?? "").toString();
        final Map<String, dynamic>? old = existing[key];
        value.remove("status");
        value.remove("pid");
        value.remove("log_path");
        value.remove("createdAt");
        value.remove("updatedAt");

        final bool exists = old != null && old["id"] != null;
        if (exists) {
          value["id"] = old["id"];
        } else {
          value.remove("id");
          value.remove("is_disabled");
        }
        final response = exists
            ? await api.updateSubscribes(value)
            : await api.addSubscribes(value);
        if (response.success) {
          if (exists) {
            updated++;
          } else {
            created++;
          }
        } else {
          failed++;
        }
      }
      if (failed > 0) {
        "还原完成：新增 $created，更新 $updated，失败 $failed".toast();
      } else {
        "已还原订阅（新增 $created，更新 $updated），未删除现有订阅".toast();
      }
    } catch (e) {
      e.toString().toast();
    }
  }

  void _handleRestoreEnv(String localEnvPath) async {
    try {
      final File file = File(localEnvPath);
      final String contents = await file.readAsString();
      final List<dynamic> data = jsonDecode(contents);
      final List<EnvBean> list = data.map((e) => EnvBean.fromJson(e)).toList();
      final Api api = Api(index);

      /// 按变量名 upsert：不删除面板已有变量，保留其状态与置顶
      final Map<String, EnvBean> existing = {};
      final result = await api.envs("");
      if (result.success && result.bean != null) {
        for (final EnvBean item in result.bean!) {
          if (item.name != null) {
            existing[item.name!] = item;
          }
        }
      }

      int created = 0;
      int updated = 0;
      int failed = 0;
      for (final EnvBean value in list) {
        if (value.name == null || value.value == null) {
          continue;
        }
        final EnvBean? old = existing[value.name!];
        final response = old != null
            ? await api.addEnv(
                value.name!,
                value.value!,
                value.remarks ?? "",
                id: old.id,
                nId: old.nId,
              )
            : await api.addEnv(value.name!, value.value!, value.remarks ?? "");
        if (!response.success) {
          failed++;
          continue;
        }
        if (old == null) {
          created++;
        } else {
          updated++;
        }

        /// 同步启用状态（以备份为准）
        if (old != null &&
            old.sId != null &&
            old.sId!.isNotEmpty &&
            value.status != null) {
          if (value.status == 1 && old.status != 1) {
            await api.disableEnv([old.sId!]);
          } else if (value.status == 0 && old.status == 1) {
            await api.enableEnv([old.sId!]);
          }
        }
      }
      if (failed > 0) {
        "还原完成：新增 $created，更新 $updated，失败 $failed".toast();
      } else {
        "已还原变量（新增 $created，更新 $updated），未删除现有变量".toast();
      }
    } catch (e) {
      e.toString().toast();
    }
  }

  void _handleRestoreConfig(String title, String localConfigPath) async {
    try {
      final File file = File(localConfigPath);
      final String contents = await file.readAsString();

      final response = await Api(index).saveFile(title, contents);
      if (response.success) {
        "已还原$title文件".toast();
      } else {
        (response.message ?? "还原$title失败").toast();
      }
    } catch (e) {
      e.toString().toast();
    }
  }
}

class FileUtil {
  int index;

  FileUtil(this.index);

  static const String config = "config";
  static const String env = "env";
  static const String subscribe = "subscribe";
  static const String downloadFiles = "download_files";

  String today() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String time() {
    return DateFormat('HH-mm-ss').format(DateTime.now());
  }

  String getHost() {
    String? temp = getIt<UserInfoViewModel>(instanceName: index.toString())
        .host;

    if (temp == null) return "";

    return temp
        .trim()
        .replaceAll("http://", "")
        .replaceAll("https://", "")
        .replaceAll("/", "-")
        .replaceAll("\\", "-")
        .replaceAll(":", "-")
        .replaceAll("*", "_")
        .replaceAll("?", "_")
        .replaceAll("<", "_")
        .replaceAll(">", "_")
        .replaceAll("|", "_");
  }

  Future<String> get downloadFilePath async {
    Directory directory;
    if (Platform.isAndroid) {
      var temp = await getExternalStorageDirectory();

      if (temp != null) {
        directory = temp;
      } else {
        directory = Directory("storage/emulated/0");
      }
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    return directory.path;
  }

  Future<String> get sourcePath async {
    Directory directory;
    if (Platform.isAndroid) {
      directory = await getApplicationSupportDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    return directory.path;
  }

  Future<String> get localPath async {
    return (await sourcePath) + path.separator + getHost();
  }

  Future<Directory> getSubscribeDirectory() async {
    final path = await localPath;
    Directory f = Directory('$path/${today()}/$subscribe/');
    if (!(await f.exists())) {
      await f.create(recursive: true);
    }
    return f;
  }

  Future<File> get _localSubscribeFile async {
    final path = await localPath;
    File f = File('$path/${today()}/$subscribe/${time()}.$subscribe');
    if (f.existsSync()) {
      f.deleteSync();
    }
    return f;
  }

  Future<Directory> getEnvDirectory() async {
    final path = await localPath;
    Directory f = Directory('$path/${today()}/$env/');
    if (!(await f.exists())) {
      await f.create(recursive: true);
    }
    return f;
  }

  Future<File> get _localEnvFile async {
    final path = await localPath;
    File f = File('$path/${today()}/$env/${time()}.$env');
    if (f.existsSync()) {
      f.deleteSync();
    }
    return f;
  }

  Future<File> writeDownloadFile(String suffix, String content) async {
    final path = await downloadFilePath;
    File f;
    if (Platform.isAndroid) {
      f = File('$path/qinglong_app/$downloadFiles/$suffix');
    } else {
      f = File('$path/$downloadFiles/$suffix');
    }
    if (f.existsSync()) {
      f.deleteSync();
    }
    await f.create(recursive: true);
    return f.writeAsString(content);
  }

  Future<File> writeSubscribe(String content) async {
    final file = await _localSubscribeFile;
    await file.create(recursive: true);
    return file.writeAsString(content);
  }

  Future<File> writeEnv(String content) async {
    final file = await _localEnvFile;
    await file.create(recursive: true);
    return file.writeAsString(content);
  }

  Future<Directory> getConfigHolDirectory(String name) async {
    final path = await localPath;
    Directory f = Directory('$path/${today()}/$config/$name/');
    if (!(await f.exists())) {
      await f.create(recursive: true);
    }
    return f;
  }

  Future<File> locaConfigHolFile(String title) async {
    final path = await localPath;
    File f = File('$path/${today()}/$config/$title/${time()}.$config');
    if (f.existsSync()) {
      f.deleteSync();
    }
    return f;
  }

  Future<File> writeConfig(String title, String content) async {
    final file = await locaConfigHolFile(title);
    await file.create(recursive: true);
    return file.writeAsString(content);
  }
}
