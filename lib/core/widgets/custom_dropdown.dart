import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatefulWidget {
  const CustomDropdown({
    super.key,
    required this.items,
    required this.hintText,
    required this.icon,
    this.selectedValue,
    this.onChanged,
  });

  final List<CustomDropdownItem<T>> items;
  final String hintText;
  final IconData icon;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late TextEditingController _controller;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _selectedLabel);
  }

  @override
  void didUpdateWidget(CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      _controller.text = _selectedLabel;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  String get _selectedLabel => widget.items
      .where((item) => item.value == widget.selectedValue)
      .firstOrNull
      ?.label ??
      '';

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;
    _overlayEntry = _buildOverlay(width);
    Overlay.of(context).insert(_overlayEntry!);
    if (!_disposed) setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_disposed && mounted) setState(() => _isOpen = false);
  }

  void _selectItem(T? value) {
    _removeOverlay();
    widget.onChanged?.call(value);
  }

  OverlayEntry _buildOverlay(double width) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayBg = isDark ? const Color(0xFF1A2930) : Colors.white;
    final overlayBorder = primary;
    final selectedBg = primary.withValues(alpha: 0.1);
    final selectedText = primary;
    final normalText = isDark ? const Color(0xFFE8F0F2) : const Color(0xFF0F2C3F);

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: SizedBox(
              width: width,
              child: Container(
                decoration: BoxDecoration(
                  color: overlayBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: overlayBorder,
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    children: widget.items.map((item) {
                      final selected = widget.selectedValue == item.value;
                      return Material(
                        color: selected
                            ? selectedBg
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectItem(item.value),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                if (selected)
                                  Icon(
                                    Icons.check,
                                    color: selectedText,
                                    size: 20,
                                  )
                                else
                                  const SizedBox(width: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: selected
                                          ? selectedText
                                          : normalText,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final suffixBg = isDark ? Colors.white24 : Colors.black26;
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        readOnly: true,
        onTap: _toggleDropdown,
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.hintText,
          prefixIcon: Icon(widget.icon, color: primary),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: suffixBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDropdownItem<T> {
  const CustomDropdownItem({
    required this.label,
    required this.value,
  });

  final String label;
  final T value;
}
