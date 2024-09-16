import 'package:flutter/material.dart';
import '../child_pages/home_page.dart';
import 'buttons.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

class Grid extends StatefulWidget {
  final Function(FirstButton) onButtonPressed;

  Grid({required this.onButtonPressed});

  @override
  State<Grid> createState() => GridState();
}

class GridState extends State<Grid> {
  dynamic visibleButtons = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateVisibleButtons();
  }

  void updateVisibleButtons() {
    final pathWidget = PathWidget.of(context);
    final dataWidget = DataWidget.of(context);

    setState(() {
      dynamic buttons = dataWidget?.data;

      for (var folder in pathWidget!.pathOfBoard) {
        buttons = buttons[folder];
      }

      // Ensure buttons is a list
      if (buttons is List) {
        visibleButtons = List.from(buttons);
      } else {
        visibleButtons = [];
      }

      print("Updated visible buttons");
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

  void reorderGrid(int oldIndex, int newIndex) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    setState(() {
      dynamic nestedData = dataWidget!.data;

      for (var folder in pathWidget!.pathOfBoard) {
        nestedData = nestedData[folder];
      }

      // Ensure the new index is valid
      if (newIndex > oldIndex) {
        newIndex -= 1; // Adjust for index change when moving forward
      }

      // Move the item in the nestedData
      Map<String, dynamic> btnVar = nestedData.removeAt(oldIndex);
      nestedData.insert(newIndex, btnVar);

      // Also update visibleButtons to reflect the new order
      visibleButtons = List.from(nestedData);

      // Notify data change
      dataWidget.onDataChange(dataWidget.data);

      // Save the updated data to file and refresh the UI
      context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);
      context.findAncestorStateOfType<HomePageState>()?.updateGrid();
    });
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 10; // Fixed number of columns
        int fixedRows = 5; // Fixed number of rows

        double availableHeight = constraints.maxHeight;

        // Calculate maximum number of items that can fit based on number of rows
        int maxItems = 50;
        double buttonSize = ((availableHeight - 50) / fixedRows) + 40;

        // Limit the number of items shown to the maximum number that fits in the grid
        int visibleItemCount = visibleButtons.length > maxItems ? maxItems : visibleButtons.length;

        if (visibleButtons.isEmpty) {
          return Center(
            child: Text(
              "No items to display",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ReorderableGridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          physics: NeverScrollableScrollPhysics(), // Disable scrolling
          shrinkWrap: true,
          itemCount: visibleItemCount,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              reorderGrid(oldIndex, newIndex);
            });
          },
          itemBuilder: (BuildContext context, int index) {
            final item = visibleButtons[index];
            final imagePath = item["image_url"] ?? '';
            final label = item["label"] ?? 'No Label';

            // Combine 'id' with 'index' to ensure uniqueness, in case 'id' alone isn't unique
            final itemKey = ValueKey('${item["id"]}_$index');

            if (item["folder"] == false) {
              return LongPressDraggable<Map<String, dynamic>>(
                key: itemKey, // Ensure the item has a unique key
                data: item,
                feedback: Material(
                  child: FirstButton(
                    id: item["id"],
                    imagePath: imagePath,
                    text: label,
                    size: buttonSize,
                    onPressed: () {},
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: FirstButton(
                    id: item["id"],
                    imagePath: imagePath,
                    text: label,
                    size: buttonSize,
                    onPressed: () {},
                  ),
                ),
                child: FirstButton(
                  id: item["id"],
                  imagePath: imagePath,
                  text: label,
                  size: buttonSize,
                  onPressed: () {
                    widget.onButtonPressed(
                      FirstButton(
                        id: item["id"],
                        imagePath: imagePath,
                        text: label,
                        size: buttonSize,
                        onPressed: () {},
                      ),
                    );
                  },
                ),
              );
            } else {
              return DragTarget<Map<String, dynamic>>(
                key: itemKey, // Ensure the FolderButton also has a unique key
                onWillAcceptWithDetails: (receivedItem) {
                  // Allow dragging over folder to drop
                  return true;
                },
                onAcceptWithDetails: (receivedItem) {
                  final dataWidget = DataWidget.of(context);
                  final pathWidget = PathWidget.of(context);

                  setState(() {
                    // Get the current path to where the grid is pointing
                    dynamic nestedData = dataWidget!.data;
                    for (var folder in pathWidget!.pathOfBoard) {
                      nestedData = nestedData[folder];
                    }

                    // Find the folder where the item will be moved
                    dynamic targetFolder = nestedData[index]; // Use the correct index here

                    if (targetFolder["folder"] == true) {
                      // Move the item into the folder's buttons list
                      targetFolder["buttons"].add(receivedItem);

                      // Remove the item from its original location
                      nestedData.remove(receivedItem);

                      // Notify the widget that the data has changed
                      dataWidget.onDataChange(dataWidget.data);

                      // Save the updated data to file
                      context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);

                      // Update the UI
                      context.findAncestorStateOfType<HomePageState>()?.updateGrid();
                    } else {
                      print("Target index is not a folder.");
                    }
                  });
                },
                builder: (context, acceptedItems, rejectedItems) {
                  return FolderButton(
                    key: itemKey,
                    imagePath: imagePath,
                    text: label,
                    ind: index,
                    size: buttonSize,
                    onPressed: () {
                      final homePageState = context.findAncestorStateOfType<HomePageState>();
                      if (homePageState == null) print("null");

                      if (homePageState?.inRemovalState == true) {
                        homePageState?.removeFolder(index); // Call removeFolder if in removal mode
                      } else {
                        updateGridPath(index, "buttons"); // Navigate into the folder
                      }
                    },
                  );
                },
              );
            }
          },
        );
      },
    );
  }
} 