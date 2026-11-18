import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/single_account_page.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/loading_widget.dart';
import 'package:qinglong_app/module/subscribe/add_subscribe_page.dart';
import 'package:qinglong_app/utils/extension.dart';

import '../base/commit_button.dart';

class PushSettingPage extends ConsumerStatefulWidget {
  const PushSettingPage({super.key});

  @override
  ConsumerState<PushSettingPage> createState() => _PushSettingPageState();
}

class _PushSettingPageState extends ConsumerState<PushSettingPage> {
  List<PushBean> list = [];

  PushBean? current;
  bool loading = true;

  @override
  void initState() {
    initData();
    super.initState();
    onLazyLoad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QlAppBar(
        title: "通知设置",
        actions: [
          CommitButton(
            onTap: () {
              commit();
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: LoadingWidget())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      const Text("通知设置", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<PushBean>(
                        items: list
                            .map<DropdownMenuItem<PushBean>>(
                              (e) => DropdownMenuItem<PushBean>(
                                value: e,
                                child: Text(getNameByKey(e.name)),
                              ),
                            )
                            .toList(),
                        style: TextStyle(
                          fontSize: 14,
                          color: ref
                              .watch(themeProvider)
                              .themeColor
                              .title2Color(),
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                        ),
                        icon: const Icon(
                          CupertinoIcons.chevron_up_chevron_down,
                          size: 16,
                        ),
                        // key 绑定当前渠道：读取回填/切换时重建表单字段，
                        // 保证 initialValue 正确显示当前配置
                        key: ValueKey<String?>(current?.key),
                        initialValue: current,
                        onChanged: (value) {
                          current = value!;
                          setState(() {});
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children:
                            current?.children
                                .map(
                                  (e) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 15),
                                      TitleWidget(e.key, required: e.required),
                                      const SizedBox(height: 10),
                                      // 官方部分字段是下拉选择（items），其余为文本输入
                                      e.items == null
                                          ? TextField(
                                              controller: e.controller,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              decoration: InputDecoration(
                                                hintText: "请输入${e.key}",
                                              ),
                                              autofocus: false,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            )
                                          : DropdownButtonFormField<String>(
                                              // key 绑定当前值，回填/切换时正确刷新显示
                                              key: ValueKey<String>(
                                                e.controller.text,
                                              ),
                                              initialValue:
                                                  e.controller.text.isEmpty
                                                  ? null
                                                  : e.controller.text,
                                              items: e.items!
                                                  .map(
                                                    (v) =>
                                                        DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: v,
                                                          child: Text(v),
                                                        ),
                                                  )
                                                  .toList(),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                hintText: "请选择",
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              onChanged: (v) {
                                                e.controller.text = v ?? "";
                                              },
                                            ),
                                      const SizedBox(height: 10),
                                      Text(
                                        e.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: ref
                                              .watch(themeProvider)
                                              .themeColor
                                              .descColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList() ??
                            [],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void initData() {
    // 渠道与字段定义对齐青龙官方 src/utils/config.ts 的
    // notificationModes / notificationModeMap（保持官方渠道顺序与字段名）
    var pushSetting = {
      "gotify": [
        {
          "label": 'gotifyUrl',
          "tip": 'gotify的url地址，例如 https://push.example.de:8080',
          "required": true,
        },
        {"label": 'gotifyToken', "tip": 'gotify的消息应用token码', "required": true},
        {"label": 'gotifyPriority', "tip": '推送消息的优先级'},
      ],
      "ntfy": [
        {
          "label": 'ntfyUrl',
          "tip": 'ntfy的url地址，例如 https://ntfy.sh',
          "required": true,
        },
        {"label": 'ntfyTopic', "tip": 'ntfy应用topic', "required": true},
        {"label": 'ntfyPriority', "tip": '推送消息的优先级'},
        {"label": 'ntfyToken', "tip": 'ntfy应用token'},
        {"label": 'ntfyUsername', "tip": 'ntfy应用用户名'},
        {"label": 'ntfyPassword', "tip": 'ntfy应用密码'},
        {"label": 'ntfyActions', "tip": 'ntfy用户动作'},
      ],
      "goCqHttpBot": [
        {
          "label": 'goCqHttpBotUrl',
          "tip": '推送到个人QQ: http://127.0.0.1/send_private_msg，群：http://127.0.0.1/send_group_msg',
          "required": true,
        },
        {"label": 'goCqHttpBotToken', "tip": '访问密钥', "required": true},
        {
          "label": 'goCqHttpBotQq',
          "tip": '如果GOBOT_URL设置 /send_private_msg 则需要填入 user_id=个人QQ；相反如果是 /send_group_msg 则需要填入 group_id=QQ群',
          "required": true,
        },
      ],
      "serverChan": [
        {"label": 'serverChanKey', "tip": 'Server酱SENDKEY', "required": true},
      ],
      "pushDeer": [
        {
          "label": 'pushDeerKey',
          "tip": 'PushDeer的Key，https://github.com/easychen/pushdeer',
          "required": true,
        },
        {
          "label": 'pushDeerUrl',
          "tip": 'PushDeer的自架API endpoint，默认 https://api2.pushdeer.com/message/push',
        },
      ],
      "bark": [
        {
          "label": 'barkPush',
          "tip": 'Bark的信息IP/设备码，例如：https://api.day.app/XXXXXXXX',
          "required": true,
        },
        {"label": 'barkIcon', "tip": 'BARK推送图标，自定义推送图标（需iOS15或以上才能显示）'},
        {"label": 'barkSound', "tip": 'BARK推送铃声，铃声列表去APP查看复制填写'},
        {"label": 'barkGroup', "tip": 'BARK推送消息的分组，默认为qinglong'},
        {"label": 'barkLevel', "tip": 'BARK推送消息的时效性，默认为active'},
        {"label": 'barkUrl', "tip": 'BARK推送消息的跳转URL'},
        {"label": 'barkArchive', "tip": 'BARK是否保存推送消息'},
      ],
      "telegramBot": [
        {
          "label": 'telegramBotToken',
          "tip": 'telegram机器人的token，例如：1077xxx4424:AAFjv0FcqxxxxxxgEMGfi22B4yh15R5uw',
          "required": true,
        },
        {
          "label": 'telegramBotUserId',
          "tip": 'telegram用户的id，例如：129xxx206',
          "required": true,
        },
        {"label": 'telegramBotProxyHost', "tip": '代理IP'},
        {"label": 'telegramBotProxyPort', "tip": '代理端口'},
        {
          "label": 'telegramBotProxyAuth',
          "tip": 'telegram代理配置认证参数，用户名与密码用英文冒号连接 user:password',
        },
        {
          "label": 'telegramBotApiHost',
          "tip": 'telegram api自建的反向代理地址，默认tg官方api',
        },
      ],
      "dingtalkBot": [
        {
          "label": 'dingtalkBotToken',
          "tip": '钉钉机器人webhook token，例如：5a544165465465645d0f31dca676e7bd07415asdasd',
          "required": true,
        },
        {
          "label": 'dingtalkBotSecret',
          "tip": '密钥，机器人安全设置页面，加签一栏下面显示的SEC开头的字符串',
        },
      ],
      "weWorkBot": [
        {
          "label": 'weWorkBotKey',
          "tip": '企业微信机器人的webhook，例如：693a91f6-7xxx-4bc4-97a0-0ec2sifa5aaa',
          "required": true,
        },
        {"label": 'weWorkOrigin', "tip": '企业微信代理地址'},
      ],
      "weWorkApp": [
        {
          "label": 'weWorkAppKey',
          "tip": 'corpid,corpsecret,touser,agentid,消息类型(选填)，用英文逗号隔开，例如：wwcfrs,B-76WERQ,qinglong,1000001,2COat',
          "required": true,
        },
        {"label": 'weWorkOrigin', "tip": '企业微信代理地址'},
      ],
      "aibotk": [
        {
          "label": 'aibotkKey',
          "tip": '密钥key，智能微秘书个人中心获取apikey，https://wechat.aibotk.com/signup?from=ql',
          "required": true,
        },
        {
          "label": 'aibotkType',
          "tip": '发送的目标：群组或好友',
          "required": true,
          "items": ['room', 'contact'],
        },
        {"label": 'aibotkName', "tip": '要发送的用户昵称或群名', "required": true},
      ],
      "iGot": [
        {
          "label": 'iGotPushKey',
          "tip": 'iGot的信息推送key，例如：https://push.hellyw.com/XXXXXXXX',
          "required": true,
        },
      ],
      "pushPlus": [
        {
          "label": 'pushPlusToken',
          "tip": '微信扫码登录后的token，参考 https://www.pushplus.plus/',
          "required": true,
        },
        {"label": 'pushPlusUser', "tip": '一对多推送的群组编码'},
        {"label": 'pushplusTemplate', "tip": '发送模板'},
        {"label": 'pushplusChannel', "tip": '发送渠道'},
        {"label": 'pushplusWebhook', "tip": 'webhook编码'},
        {"label": 'pushplusCallbackUrl', "tip": '发送结果回调地址'},
        {"label": 'pushplusTo', "tip": '好友令牌'},
      ],
      "wePlusBot": [
        {
          "label": 'wePlusBotToken',
          "tip": '用户令牌，扫描登录后 我的→设置→令牌 中获取',
          "required": true,
        },
        {"label": 'wePlusBotReceiver', "tip": '消息接收人'},
        {
          "label": 'wePlusBotVersion',
          "tip": '调用版本；专业版填 pro，个人版填 personal，为空默认专业版',
        },
      ],
      "wxPusherBot": [
        {
          "label": 'wxPusherBotAppToken',
          "tip": 'wxPusherBot的appToken',
          "required": true,
        },
        {"label": 'wxPusherBotTopicIds', "tip": 'wxPusherBot的topicIds'},
        {"label": 'wxPusherBotUids', "tip": 'wxPusherBot的uids'},
      ],
      "wxPusherSpt": [
        {
          "label": 'wxPusherSptList',
          "tip": 'wxPusherSpt的SPT',
          "required": true,
        },
      ],
      "openiLink": [
        {
          "label": 'openiLinkAppToken',
          "tip": 'OpeniLink的app_token，在OpeniLink Hub后台安装App后获取',
          "required": true,
        },
        {
          "label": 'openiLinkHubUrl',
          "tip": 'OpeniLink Hub地址，默认 https://hub.openilink.com',
        },
        {
          "label": 'openiLinkContextToken',
          "tip": 'OpeniLink的context_token，用于标识消息会话上下文',
        },
      ],
      "wpush": [
        {
          "label": 'wpushApiKey',
          "tip": 'WPUSH的API Key，在 https://wpush.cn/settings 获取',
          "required": true,
        },
        {
          "label": 'wpushChannel',
          "tip": '推送渠道，支持 wechat/app/sms/mail/webhook/dingtalk/feishu/wechat_work/clawbot/qqbot，默认 wechat',
        },
        {"label": 'wpushTopicCode', "tip": '可选，Topic 广播编码'},
      ],
      "chat": [
        {
          "label": 'synologyChatUrl',
          "tip": 'synologyChat的url地址',
          "required": true,
        },
      ],
      "email": [
        {
          "label": 'emailService',
          "tip": '邮箱服务名称，比如126、163、Gmail、QQ等',
          "required": true,
        },
        {"label": 'emailUser', "tip": '邮箱认证地址', "required": true},
        {"label": 'emailPass', "tip": 'SMTP 登录密码或授权码', "required": true},
        {"label": 'emailTo', "tip": '收件邮箱地址，多个用分号分隔，默认发送给发件邮箱地址'},
      ],
      "lark": [
        {"label": 'larkKey', "tip": '飞书群组机器人的 webhook key', "required": true},
        {"label": 'larkSecret', "tip": '飞书群组机器人加签密钥，安全设置中开启签名校验后获得'},
      ],
      "pushMe": [
        {
          "label": 'pushMeKey',
          "tip": 'PushMe的Key，https://push.i-i.me/',
          "required": true,
        },
        {"label": 'pushMeUrl', "tip": '自建PushMeServer消息接口地址，不填则使用官方接口'},
      ],
      "chronocat": [
        {
          "label": 'chronocatURL',
          "tip": 'Chronocat Red 服务的连接地址',
          "required": true,
        },
        {
          "label": 'chronocatQQ',
          "tip": '个人:user_id=个人QQ 群:group_id=QQ群，多个用英文分号隔开',
          "required": true,
        },
        {
          "label": 'chronocatToken',
          "tip": '持久化config目录下chronocat.yml文件中的token',
          "required": true,
        },
      ],
      "webhook": [
        {
          "label": 'webhookMethod',
          "tip": '请求方法',
          "required": true,
          "items": ['GET', 'POST', 'PUT'],
        },
        {
          "label": 'webhookContentType',
          "tip": '请求头 Content-Type',
          "required": true,
          "items": [
            'text/plain',
            'application/json',
            'multipart/form-data',
            'application/x-www-form-urlencoded',
          ],
        },
        {
          "label": 'webhookUrl',
          "tip": '请求链接，以 http/https 开头，url 或 body 必须包含 \$title',
          "required": true,
        },
        {
          "label": 'webhookHeaders',
          "tip": '请求头格式 Custom-Header1: Header1，多个换行分隔',
        },
        {
          "label": 'webhookBody',
          "tip": '请求体格式 key1: value1，多个换行分隔，需包含 \$title',
        },
      ],
      // 与青龙官方前端哨兵值一致，提交后端时改写为 {"type": ""}
      "closed": [],
    };

    for (var entry in pushSetting.entries) {
      list.add(
        PushBean(
          entry.key,
          entry.key,
          entry.value
              .map(
                (e) => PushChildBean(
                  e["label"].toString(),
                  e["tip"].toString(),
                  (e["required"] ?? false) as bool,
                  items: (e["items"] as List?)
                      ?.map((v) => v.toString())
                      .toList(),
                ),
              )
              .toList(),
        ),
      );
    }
  }

  void onLazyLoad() async {
    try {
      var response = await SingleAccountPageState.ofApi(context)
          .getNotifcation();

      if (!response.success) {
        // 读取失败不能让页面永远卡在 loading；下拉框回落「已关闭」
        if (mounted) {
          response.message?.toast();
          setState(() {
            current ??= list.isNotEmpty ? list.last : null;
            loading = false;
          });
        }
        return;
      }

      String result = response.bean ?? "{}";
      Map<String, dynamic> json;
      try {
        json = jsonDecode(result) as Map<String, dynamic>;
      } catch (e) {
        json = <String, dynamic>{};
      }

      if (json.isEmpty) {
        current = list.last;
        setState(() {
          loading = false;
        });
        return;
      }
      String? type = json["type"]?.toString();
      // 官方用空字符串表示关闭；兼容个别版本返回的 closed 哨兵值
      if (type == null || type.isEmpty || type == "closed") {
        current = list.last;
        setState(() {
          loading = false;
        });
        return;
      }

      int index = list.indexWhere((element) => element.key == type);
      if (index < 0) {
        // 未知渠道类型：回落到「已关闭」，保证下拉框始终有值
        current = list.last;
        setState(() {
          loading = false;
        });
        return;
      }

      for (var element in list[index].children) {
        element.controller.text = json[element.key]?.toString() ?? "";
      }
      current = list[index];
      setState(() {
        loading = false;
      });
    } catch (e) {
      // 网络等异常时降级展示，不阻塞页面；下拉框回落到「已关闭」
      if (mounted) {
        setState(() {
          current ??= list.isNotEmpty ? list.last : null;
          loading = false;
        });
      }
    }
  }

  void commit() async {
    if (current == null || current!.key == "closed") {
      EasyLoading.show(status: "提交中");

      // 与青龙官方一致：关闭通知提交 {"type": ""}
      var response = await SingleAccountPageState.ofApi(context)
          .updateNotifcation({"type": ""});
      EasyLoading.dismiss();
      if (response.success) {
        "设置成功".toast();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        response.message.toast();
      }
      return;
    }
    int? index = current?.children.indexWhere(
      (element) => element.controller.text.isEmpty && element.required == true,
    );
    index ??= -1;
    if (index >= 0) {
      ("${current?.children[index].key}为必填项").toast();
      return;
    }

    EasyLoading.show(status: "提交中");

    Map<String, dynamic> params = {};

    params["type"] = current!.key.toString();
    params.addAll(current!.children2Json());
    var response = await SingleAccountPageState.ofApi(context)
        .updateNotifcation(params);
    EasyLoading.dismiss();
    if (response.success) {
      "设置成功".toast();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      response.message.toast();
    }
  }
}

class PushBean {
  String key;
  String name;
  List<PushChildBean> children;

  PushBean(this.key, this.name, this.children);

  Map<String, dynamic> children2Json() {
    Map<String, dynamic> data = {};

    for (var e in children) {
      data[e.key] = e.controller.text.isEmpty
          ? ''
          : e.controller.text.toString();
    }
    return data;
  }
}

class PushChildBean {
  String key;
  String name;
  bool required;

  /// 官方配置中存在下拉选项的字段（如 webhookMethod、aibotkType、webhookContentType）
  List<String>? items;

  TextEditingController controller = TextEditingController();

  PushChildBean(this.key, this.name, this.required, {this.items});
}

String getNameByKey(String key) {
  // 与青龙官方 notificationModes 的 label 对齐
  const Map<String, String> names = {
    "gotify": "Gotify",
    "ntfy": "Ntfy",
    "goCqHttpBot": "GoCqHttpBot",
    "serverChan": "Server酱",
    "pushDeer": "PushDeer",
    "bark": "Bark",
    "telegramBot": "Telegram机器人",
    "dingtalkBot": "钉钉机器人",
    "weWorkBot": "企业微信机器人",
    "weWorkApp": "企业微信应用",
    "aibotk": "智能微秘书",
    "iGot": "IGot",
    "pushPlus": "PushPlus",
    "wePlusBot": "微加机器人",
    "wxPusherBot": "wxPusher",
    "wxPusherSpt": "WxPusher(极简推送SPT-推荐)",
    "openiLink": "OpeniLink",
    "wpush": "WPUSH",
    "chat": "群晖chat",
    "email": "邮箱",
    "lark": "飞书机器人",
    "pushMe": "PushMe",
    "chronocat": "Chronocat",
    "webhook": "自定义通知",
    "closed": "已关闭",
  };
  return names[key] ?? "已关闭";
}
