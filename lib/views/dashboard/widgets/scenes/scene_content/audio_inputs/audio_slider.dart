import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/cupertino_number_text_field.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../../../../stores/shared/network.dart';
import '../../../../../../types/classes/api/input.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../utils/network_helper.dart';

import 'package:syncfusion_flutter_gauges/gauges.dart';

class AudioSlider extends StatefulWidget {
  final Input input;

  const AudioSlider({
    Key? key,
    required this.input,
  }) : super(key: key);

  @override
  State<AudioSlider> createState() => _AudioSliderState();
}

class _AudioSliderState extends State<AudioSlider> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(text: this.widget.input.syncOffset.toString());
  }

  @override
  void didUpdateWidget(covariant AudioSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        this.widget.input.syncOffset.toString() != _controller.text) {
      _controller.text = this.widget.input.syncOffset.toString();
    }
  }

  double _transformMulToLevel(double mul) {
    double level = 0.33 * (log(mul) / log(10)) + 1;
    return level < 0
        ? 0
        : level > 1
            ? 1
            : level;
  }

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  this.widget.input.inputMuted
                      ? Icons.volume_off
                      : Icons.volume_up,
                  color: this.widget.input.inputMuted
                      ? CupertinoColors.destructiveRed
                      : Theme.of(context).buttonTheme.colorScheme!.primary,
                ),
                padding: const EdgeInsets.all(0.0),
                onPressed: () => NetworkHelper.makeRequest(
                  networkStore.activeSession!.socket,
                  RequestType.SetInputMute,
                  {
                    'inputName': this.widget.input.inputName,
                    'inputMuted': !this.widget.input.inputMuted
                  },
                ),
              ),
              Expanded(
                child: Text(
                  this.widget.input.inputName != null
                      ? this.widget.input.inputName!
                      : '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 64.0,
                padding: const EdgeInsets.only(right: 0.0),
                alignment: Alignment.center,
                child: Text(((((this.widget.input.inputVolumeMul ?? 0.0) * 100)
                            .toInt()) /
                        100)
                    .toString()
                    .padRight(4, '0')),
              ),
              HiveBuilder<dynamic>(
                hiveKey: HiveKeys.Settings,
                rebuildKeys: const [
                  SettingsKeys.ExposeInputAudioSyncOffset,
                ],
                builder: (context, settingsBox, child) => settingsBox.get(
                  SettingsKeys.ExposeInputAudioSyncOffset.name,
                  defaultValue: false,
                )
                    ? CupertinoNumberTextField(
                        width: 112.0,
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLength: 6,
                        negativeAllowed: true,
                        minValue: -950,
                        maxValue: 20000,
                        suffix: 'ms',
                        onDone: () => NetworkHelper.makeRequest(
                          GetIt.instance<NetworkStore>().activeSession!.socket,
                          RequestType.SetInputAudioSyncOffset,
                          {
                            'inputName': this.widget.input.inputName,
                            'inputAudioSyncOffset':
                                int.tryParse(_controller.text) ?? 0
                          },
                        ),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SfLinearGauge(
                  ranges: [
                    LinearGaugeRange(
                      startValue: 0,
                      endValue: 60,
                      color: Color.fromARGB(255, 0, 168, 0)
                    ),
                    LinearGaugeRange(
                      startValue: 60,
                      endValue: 80,
                      color: Color.fromARGB(255, 168, 154, 0)
                    ),
                    LinearGaugeRange(
                      startValue: 80,
                      endValue: 100,
                      color: Color.fromARGB(255, 168, 0, 0)
                    )
                  ],
                  barPointers: [
                    if (this.widget.input.inputLevelsMul != null &&
                        this.widget.input.inputLevelsMul!.isNotEmpty)
                    LinearBarPointer(value: _transformMulToLevel(this.widget.input.inputLevelsMul!.first.current!) * 100)
                  ],
                  markerPointers: [
                    LinearShapePointer(
                      value: this.widget.input.inputVolumeMul! * 100,
                      dragBehavior: LinearMarkerDragBehavior.free,
                      enableAnimation: false,
                      onChanged: (volume) => NetworkHelper.makeRequest(
                          networkStore.activeSession!.socket,
                          RequestType.SetInputVolume, {
                        'inputName': this.widget.input.inputName,
                        'inputVolumeMul': volume / 100,
                      }),
                    )
                  ]
                )
              )
            ]
          ),
        ],
      ),
    );
  }
}
