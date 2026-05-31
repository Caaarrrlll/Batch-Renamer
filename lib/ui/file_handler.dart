import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';

class FileHandler extends StatefulWidget {
  const FileHandler({super.key});

  @override
  State<FileHandler> createState() => _FileHandlerState();
}

class _FileHandlerState extends State<FileHandler> {
  final List<DropItem> _list = [];

  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        setState(() {
          _list.addAll(detail.files);
        });
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Container(
        height: 200,
        width: 200,
        color: _dragging ? Colors.blue.withValues(alpha: 0.4) : Colors.black26,
        child: _list.isEmpty
            ? const Center(child: Text("Drop here"))
            : Text(_list.join("\n")),
      ),
    );
  }
}