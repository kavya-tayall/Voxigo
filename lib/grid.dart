import 'package:flutter/material.dart';
import 'package:test_app/homePage.dart';
import 'Buttons.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class Grid extends StatefulWidget {

  final Function(FirstButton) onButtonPressed;
  Grid({required this.onButtonPressed});

  @override
  State<Grid> createState() => _GridState();
}


class _GridState extends State<Grid> {
  dynamic visibleButtons = [];

  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    updateVisibleButtons();
  }

  void updateVisibleButtons() {
    final pathWidget = PathWidget.of(context);
    final dataWidget = DataWidget.of(context);

    setState(() {
      dynamic buttons = dataWidget!.data;
      for (var folder in pathWidget!.pathOfBoard) {
        buttons = buttons[folder];
      }
      visibleButtons = List.from(buttons);
    });
  }

  void updateGridPath(int folderPath, String folderPath2) {
    final pathWidget = PathWidget.of(context);
    List<dynamic> updatedPath = List.from(pathWidget!.pathOfBoard);

    setState(() {
      updatedPath.add(folderPath);
      updatedPath.add(folderPath2);

      pathWidget.onPathChange(updatedPath); // Notify that path has changed
      updateVisibleButtons();
    });
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 7; // Fixed number of columns
        int fixedRows = 5; // Fixed number of rows


        double availableHeight = constraints.maxHeight;

        // Calculate maximum number of items that can fit based on number of rows
        int maxItems = 35;
        double buttonSize = ((availableHeight - 50) / fixedRows);



        // Limit the number of items shown to the maximum number that fits in the grid
        int visibleItemCount = visibleButtons.length > maxItems ? maxItems : visibleButtons.length;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          physics: NeverScrollableScrollPhysics(), // Disable scrolling
          shrinkWrap: true,
          itemCount: visibleItemCount,
          itemBuilder: (BuildContext context, int index) {
            if (visibleButtons[index]["folder"] == false) {
              return FirstButton(
                key: ValueKey(visibleButtons[index]),
                imagePath: visibleButtons[index]["image_url"],
                text: visibleButtons[index]["label"],
                size: buttonSize,
                onPressed: () {
                  // Call the onButtonPressed callback with a new FirstButton
                  widget.onButtonPressed(
                      FirstButton(
                        imagePath: visibleButtons[index]["image_url"],
                        text: visibleButtons[index]["label"],
                        size: buttonSize,
                        onPressed: () {},
                      ));
                },
              );
            } else {
              return FolderButton(
                imagePath: visibleButtons[index]["image_url"],
                text: visibleButtons[index]["label"],
                ind: index,
                size: buttonSize,
                onPressed: () => updateGridPath(index, "buttons"),
                // Pass the size parameter
              );
            }
          },
        );
      },
    );
  }
}