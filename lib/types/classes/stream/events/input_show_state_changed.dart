import 'base.dart';

/// An input's mute state has changed.
class InputShowStateChangedEvent extends BaseEvent {
  InputShowStateChangedEvent(super.json);

  /// Name of the input
  String get inputName => this.json['inputName'];

  /// Whether the input is showing
  bool get visible => this.json['videoShowing'];
}

