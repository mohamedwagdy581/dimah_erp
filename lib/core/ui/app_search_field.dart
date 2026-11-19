import 'package:material_ui/material_ui.dart';

/// Keeps the visible search text in sync when a page clears its filters.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.decoration,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration? decoration;
  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    decoration: widget.decoration,
  );
}
