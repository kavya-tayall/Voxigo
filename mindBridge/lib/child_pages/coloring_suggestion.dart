import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

class ColoringHome extends StatefulWidget {
  const ColoringHome({super.key});

  @override
  State<ColoringHome> createState() => _ColoringHomeState();
}

class _ColoringHomeState extends State<ColoringHome> {
  late ScribbleNotifier notifier;

  @override
  void initState() {
    notifier = ScribbleNotifier();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "Coloring",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      body: isWideScreen
          ? Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(10),
                    child: Scribble(notifier: notifier),
                  ),
                ),
                _buildHorizontalPalette(),
              ],
            )
          : Row(
              children: [
                _buildVerticalPalette(),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(10),
                    child: Scribble(notifier: notifier),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHorizontalPalette() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.clear,
                onPressed: () => notifier.clear(),
              ),
            ),
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.undo,
                onPressed: () => notifier.undo(),
              ),
            ),
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.redo,
                onPressed: () => notifier.redo(),
              ),
            ),
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.cleaning_services,
                onPressed: () => notifier.setEraser(),
              ),
            ),
            ..._buildColorButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalPalette() {
    return Container(
      width: 80,
      color: Colors.grey[200],
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.clear,
                onPressed: () => notifier.clear(),
              ),
            ),
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.undo,
                onPressed: () => notifier.undo(),
              ),
            ),
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.redo,
                onPressed: () => notifier.redo(),
              ),
            ),
            _buildPaletteSlot(
              child: _buildToolButton(
                icon: Icons.cleaning_services,
                onPressed: () => notifier.setEraser(),
              ),
            ),
            ..._buildColorButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  List<Widget> _buildColorButtons() {
    final colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    return colors.map((color) {
      return _buildPaletteSlot(
        child: TextButton(
          onPressed: () => notifier.setColor(color),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
          ),
          child: Icon(
            Icons.square,
            color: color,
          ),
        ),
        borderColor: color == Colors.white
            ? Colors.black
            : null, // Border for white color
      );
    }).toList();
  }

  Widget _buildPaletteSlot({
    required Widget child,
    Color? borderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}
