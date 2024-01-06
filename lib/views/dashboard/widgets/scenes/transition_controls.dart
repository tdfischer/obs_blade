import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/cupertino_number_text_field.dart';

import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class TransitionControls extends StatelessWidget {
  const TransitionControls({Key? key}) : super(key: key);

  void _handleSubmit(TextEditingController controller) {
    if (controller.text.isEmpty) {
      controller.text = '0';
      controller.selection =
          TextSelection.fromPosition(const TextPosition(offset: 1));
    }
    NetworkHelper.makeRequest(
      GetIt.instance<NetworkStore>().activeSession!.socket,
      RequestType.SetCurrentSceneTransitionDuration,
      {'transitionDuration': int.tryParse(controller.text) ?? 0},
    );
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(builder: (context) {
      TextEditingController controller = TextEditingController(
          text: dashboardStore.currentTransition?.transitionDuration
                  ?.toString() ??
              '-');

      return Row(
          children: [
            DropdownButton<String?>(
              value: dashboardStore.currentTransition?.transitionName,
              disabledHint: const Text('Empty...'),
              isDense: true,
              items: dashboardStore.availableTransitions
                  ?.map(
                    (transition) => DropdownMenuItem<String>(
                      value: transition.transitionName,
                      child: Text(
                        transition.transitionName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (selectedTransition) => NetworkHelper.makeRequest(
                GetIt.instance<NetworkStore>().activeSession!.socket,
                RequestType.SetCurrentSceneTransition,
                {'transitionName': selectedTransition},
              ),
            ),
            CupertinoNumberTextField(
              width: 112.0,
              minValue: 50,
              maxValue: 20000,
              enabled:
                  dashboardStore.currentTransition?.transitionDuration != null,
              controller: controller,
              suffix: 'ms',
              onDone: () => _handleSubmit(controller),
            ),
          ],
        );
    });
  }
}
