import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hatgame/util/assertion.dart';
import 'package:hatgame/util/invalid_operation.dart';

bool checkTextFields(List<CheckedTextFieldController> controllers) {
  for (final c in controllers) {
    c.forceShowErrorOnEmpty();
  }
  // Focus the first text field with an error (if any).
  bool hasError = false;
  for (final c in controllers) {
    if (c.error != null) {
      c.focusNode.requestFocus();
      hasError = true;
      break;
    }
  }
  return !hasError;
}

// TODO: Trim name before using or checking.
class CheckedTextFieldController {
  final InvalidOperation? Function(String)? checker;
  final textController = TextEditingController();
  final focusNode = FocusNode();
  void Function()? _displayErrorListener;
  InvalidOperation? _error;
  bool _showErrorOnEmpty = false;

  CheckedTextFieldController({this.checker}) {
    if (checker != null) {
      textController.addListener(() {
        if (textController.text.isNotEmpty) {
          _showErrorOnEmpty = false;
        }
        _setError(checker!(textController.text));
        _notifyDisplayErrorChanged();
      });
      _setError(checker!(textController.text));
    }
  }

  bool get _shouldDisplayError =>
      _showErrorOnEmpty || textController.text.isNotEmpty;

  InvalidOperation? get error => _error;
  InvalidOperation? get displayError => _shouldDisplayError ? error : null;

  void setDisplayErrorListener(void Function() newListener) {
    _displayErrorListener = newListener;
  }

  void forceShowErrorOnEmpty() {
    _showErrorOnEmpty = true;
    _notifyDisplayErrorChanged();
  }

  void _setError(InvalidOperation? value) {
    _error = value;
    _notifyDisplayErrorChanged();
  }

  void _notifyDisplayErrorChanged() {
    if (_displayErrorListener != null) {
      _displayErrorListener!();
    }
  }

  void dispose() {
    textController.dispose();
    focusNode.dispose();
  }
}

class CheckedTextField extends StatefulWidget {
  final CheckedTextFieldController controller;
  final String? labelText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;

  const CheckedTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
    this.onSubmitted,
    this.onEditingComplete,
  });

  @override
  State<StatefulWidget> createState() => CheckedTextFieldState();
}

class CheckedTextFieldState extends State<CheckedTextField> {
  CheckedTextFieldController get controller => widget.controller;

  @override
  void initState() {
    controller.setDisplayErrorListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.labelText,
        errorText: controller.displayError?.message,
      ),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      controller: controller.textController,
      focusNode: controller.focusNode,
    );
  }
}
