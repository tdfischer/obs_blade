import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/profile_scene_collection/profile_scene_collection.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/studio_mode_checkbox.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/studio_mode_transition_button.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/transition_controls.dart';

import '../../../../shared/general/responsive_widget_wrapper.dart';
import 'exposed_controls/exposed_controls.dart';
import 'scene_buttons/scene_buttons.dart';
import 'scene_content/scene_content.dart';
import 'scene_content/scene_content_mobile.dart';
import 'scene_preview/scene_preview.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stats/stats.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_content/audio_inputs/audio_inputs.dart';
import 'package:obs_blade/shared/general/base/card.dart';

const double kSceneButtonSpace = 18.0;

class ChatBar extends StatelessWidget {
  const ChatBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: 'Chat',
      rightPadding: 12.0,
      paddingChild: EdgeInsets.all(0),
      child: SizedBox(
        height: 350.0,
        child: StreamChat(
          usernameRowPadding: true,
        ),
      ),
    );
  }
}

class AudioBar extends StatelessWidget {
  const AudioBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      title: 'Audio',
      rightPadding: 12.0,
      paddingChild: EdgeInsets.all(0),
      child: SizedBox(
        height: 350.0,
        child: AudioInputs()
      ),
    );
  }
}

class SceneSwitcher extends StatelessWidget {
  const SceneSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: 32.0,
              left: kSceneButtonSpace,
              right: kSceneButtonSpace,
            ),
            child: SceneButtons(),
          ),
        ),
        TransitionControls(),
      ]
    );
  }
}

class Scenes extends StatelessWidget {
  const Scenes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ResponsiveWidgetWrapper(
          mobileWidget: Column(
            children: [
              SceneSwitcher(),
              ChatBar(),
              AudioBar()
            ]
          ),
          tabletWidget: Column(
            children: [
              SceneSwitcher(),
              Row(
                children: [
                  ChatBar(),
                  AudioBar()
                ]
              )
            ]
          )
        ),
        SizedBox(height: 24.0),
        ScenePreview(),
        SizedBox(height: 24.0),
        ResponsiveWidgetWrapper(
          mobileWidget: SceneContentMobile(),
          tabletWidget: SceneContent(),
        ),
      ],
    );
  }
}
