import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'chat_username_bar.dart/chat_username_bar.dart';

import 'package:twitch_chat/twitch_chat.dart';

class StreamChat extends StatefulWidget {
  final bool usernameRowPadding;

  const StreamChat({Key? key, this.usernameRowPadding = false})
      : super(key: key);

  @override
  _StreamChatState createState() => _StreamChatState();
}

class _StreamChatState extends State<StreamChat> {
  bool anyChatActive(ChatType chatType, Box<dynamic> settingsBox) {
    bool twitchActive = chatType == ChatType.Twitch &&
        settingsBox.get(SettingsKeys.SelectedTwitchUsername.name) != null;
    bool youtubeActive = chatType == ChatType.YouTube &&
        settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name) != null;
    bool owncastActive = chatType == ChatType.Owncast &&
        settingsBox.get(SettingsKeys.SelectedOwncastUsername.name) != null;

    return twitchActive || youtubeActive || owncastActive;
  }

  String? username(chatType, Box<dynamic> settingsBox) {
    switch (chatType) {
      case ChatType.YouTube:
        return settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name);
      case ChatType.Twitch:
        return settingsBox.get(SettingsKeys.SelectedTwitchUsername.name);
      case ChatType.Owncast:
        return settingsBox.get(SettingsKeys.SelectedOwncastUsername.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: this.widget.usernameRowPadding ? 4.0 : 0.0,
            right: this.widget.usernameRowPadding ? 4.0 : 0.0,
            bottom: 12.0,
          ),
          child: const ChatUsernameBar(),
        ),
        Expanded(
          child: HiveBuilder<dynamic>(
            hiveKey: HiveKeys.Settings,
            rebuildKeys: const [
              SettingsKeys.SelectedChatType,
              SettingsKeys.SelectedTwitchUsername,
              SettingsKeys.SelectedYouTubeUsername,
              SettingsKeys.SelectedOwncastUsername,
            ],
            builder: (context, settingsBox, child) {
              ChatType chatType = settingsBox.get(
                SettingsKeys.SelectedChatType.name,
                defaultValue: ChatType.Twitch,
              );

              return Stack(
                alignment: Alignment.center,
                children: [
                  /// Only add the [WebView] to the widget tree if we have an
                  /// actual chat to display because otherwise the [WebView]
                  /// will still eat up performance
                  if (anyChatActive(chatType, settingsBox))
                    if (chatType == ChatType.Twitch)
                      TwitchChatView()
                    else
                      WebChatView(
                        chatType: chatType,
                        username: username(chatType, settingsBox)
                      )
                  ,
                  if (!anyChatActive(chatType, settingsBox))
                    Positioned(
                      top: 48.0,
                      child: SizedBox(
                        height: 185,
                        width: 225,
                        child: BaseCard(
                          child: BaseResult(
                            icon: BaseResultIcon.Negative,
                            text:
                                'No ${chatType.text} username selected, so no ones chat can be displayed.',
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

Color _hexToColor(String code) {
  return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({
    Key? key,
    required this.message
  }) : super(key: key);

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> contents = [];

    for(var badge in message.badges) {
      print("Badge! " + badge.setId + "@" + badge.versionId);
      print(badge.imageUrl1x);
      print(badge.imageUrl2x);
      print(badge.imageUrl4x);
      contents.add(WidgetSpan(
        child: Image.network(
          badge.imageUrl1x
        )
      ));
    }

    contents.add(TextSpan(
      text: message.displayName + ": ",
      style: TextStyle(color: _hexToColor(message.color))
    ));
    contents.add(TextSpan(
      text: message.message,
      style: DefaultTextStyle.of(context).style
    ));

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: contents
      )
    );
    return Text(message.message);
  }
}

class TwitchChatView extends StatefulWidget {
  const TwitchChatView({Key? key})
      : super(key: key);

  @override
  _TwitchChatState createState() => _TwitchChatState();
}

class _TwitchChatState extends State<TwitchChatView> {
  late final TwitchChat _chat;
  late final List<ChatMessage> _history = [];
  StreamController _msgStreamController = StreamController.broadcast();

  @override
  void initState() {
    _chat = TwitchChat.anonymous('tdfischer');
    _chat.chatStream.listen(
      (evt) => msgHandler(evt),
      onDone: () => print("Stream done"),
      onError: (error) => print(error),
    );
    _chat.isConnected.addListener(() {
      if (_chat.isConnected.value) {
        print("Connected");
        _history.add(ChatMessage(
          id: "",
          badges: [],
          color: "#000000",
          displayName: "",
          username: "",
          authorId: "",
          emotes: {},
          message: "Connected to chat",
          timestamp: 0,
          highlightType: null,
          isAction: false,
          isDeleted: false,
          rawData: ""
        ));
        _msgStreamController.add(_history);
      } else {
        print("Disconnected");
        _history.add(ChatMessage(
          id: "",
          badges: [],
          color: "#000000",
          displayName: "",
          username: "",
          authorId: "",
          emotes: {},
          message: "Disconnected from chat",
          timestamp: 0,
          highlightType: null,
          isAction: false,
          isDeleted: false,
          rawData: ""
        ));
        _msgStreamController.add(_history);
        _chat.connect();
      }
    });
    _chat.connect();
    super.initState();
  }

  void msgHandler(ChatMessage msg) {
    _history.add(msg);
    _msgStreamController.add(_history);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _msgStreamController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final List<ChatMessage> messages = snapshot.data;
          return Column(
            children: [
              Flexible(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: messages!.isEmpty
                    ? const Center(
                        child: Text("Chat is quiet...")
                      )
                    : ListView.builder(
                    reverse: true,
                    shrinkWrap: true,
                    itemCount: messages!.length,
                    itemBuilder: (context, index) {
                      final msg = messages![index];
                      return _ChatLine(
                        message: msg,
                      );
                    }
                  )
                )
              )
            ]
          );
        } else {
          return const Center(
            child: Text("Connecting to chat...")
          );
        }
      }
    );
  }
}

class WebChatView extends StatefulWidget {
  final ChatType chatType;
  final String? username;
  const WebChatView({Key? key, required this.chatType, required this.username})
      : super(key: key);

  @override
  _WebChatState createState() => _WebChatState(chatType: chatType, username:
  username);
}

class _WebChatState extends State<WebChatView>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _webController;

  final ChatType chatType;
  final String? username;

  _WebChatState({required this.chatType, required this.username});

  void _initializeWebController() {
    _webController = WebViewController()
      ..loadRequest(
        Uri.parse(_urlForChatType()),
      )
      ..enableZoom(false)
      ..setUserAgent(
          'Mozilla/5.0 (iPhone; CPU iPhone OS 15_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Mobile/15E148 Safari/604.1')
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    _webController.setNavigationDelegate(
      NavigationDelegate.fromPlatformCreationParams(
        const PlatformNavigationDelegateCreationParams(),
        onProgress: (progress) {
          _webController.runJavaScript('''
            if (document.body !== undefined) {
              let observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                  if(document.getElementsByClassName('consent-banner').length > 0) {
                    [...document.getElementsByClassName('consent-banner')].forEach((element) => element.remove());
                    observer.disconnect();
                  }
                });
              });

              observer.observe(document.body, {
                characterDataOldValue: true, 
                subtree: true, 
                childList: true, 
                characterData: true
              });
            }
          ''');
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  String _urlForChatType() {
    if (chatType == ChatType.YouTube && username != null) {
      return 'https://www.youtube.com/live_chat?&v=${username}';
    }
    if (chatType == ChatType.Owncast && username != null) {
      return '${username}/embed/chat/readwrite';
    }
    return 'about:blank';
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    _initializeWebController();

    super.build(context);
    /// To enable scrolling in the Twitch chat, we need to disabe scrolling for
    /// the main Scroll (the [CustomScrollView] of this view) while trying to scroll
    /// in the region where the Twitch chat is. The Listener is used to determine
    /// where the user is trying to scroll and if it's where the Twitch chat is,
    /// we change to [NeverScrollableScrollPhysics] so the WebView can consume
    /// the scroll
    return Listener(
      onPointerDown: (onPointerDown) =>
          dashboardStore.setPointerOnChat(
              onPointerDown.localPosition.dy > 150.0 &&
                  onPointerDown.localPosition.dy < 450.0),
      onPointerUp: (_) =>
          dashboardStore.setPointerOnChat(false),
      onPointerCancel: (_) =>
          dashboardStore.setPointerOnChat(false),
      child: WebViewWidget(
          controller: _webController
      )
    );
  }
}
