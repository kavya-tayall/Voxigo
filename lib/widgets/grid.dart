import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
  Directory? appDirectory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateVisibleButtons();
    loadAppDirectory();
  }

  Future<void> loadAppDirectory() async {
    appDirectory = await getApplicationDocumentsDirectory();
    setState(() {});
  }

  void updateVisibleButtons() {
    final pathWidget = PathWidget.of(context);
    final dataWidget = DataWidget.of(context);

    setState(() {
      dynamic buttons = dataWidget?.data;

      for (var folder in pathWidget!.pathOfBoard) {
        buttons = buttons[folder];
      }

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

      pathWidget.onPathChange(updatedPath);
      updateVisibleButtons();
    });
  }

  Future<void> reorderGrid(int oldIndex, int newIndex) async {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    setState(() {
      final item = visibleButtons.removeAt(oldIndex);
      visibleButtons.insert(newIndex, item);

      dynamic nestedData = dataWidget!.data;
      for (var folder in pathWidget!.pathOfBoard) {
        nestedData = nestedData[folder];
      }

      nestedData.clear();
      nestedData.addAll(visibleButtons);
    });

    await dataWidget?.onDataChange(dataWidget.data);
    context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget!.data.cast<String, dynamic>());
    context.findAncestorStateOfType<HomePageState>()?.updateGrid();
  }


  @override
  Widget build(BuildContext context) {
    if (visibleButtons.isEmpty || appDirectory == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 10;
        int fixedRows = 5;

        double availableHeight = constraints.maxHeight;

        int maxItems = 50;
        double buttonSize = ((availableHeight - 50) / fixedRows) + 40;
        print("Button size: $buttonSize");

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
          key: UniqueKey(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: visibleItemCount,
          onReorder: (oldIndex, newIndex) async {

            await reorderGrid(oldIndex, newIndex);
            setState(() {
            });
          },
          itemBuilder: (BuildContext context, int index) {
            final item = visibleButtons[index];

            if (appDirectory == null) {
              return CircularProgressIndicator();
            }

            final imagePath = '${appDirectory?.path}\\board_images\\${item["image_url"]}';
            final label = item["label"] ?? 'No Label';

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
                key: itemKey,
                onWillAcceptWithDetails: (receivedItem) {
                  return true;
                },
                onAcceptWithDetails: (receivedItem) {
                  final dataWidget = DataWidget.of(context);
                  final pathWidget = PathWidget.of(context);

                  setState(() {
                    dynamic nestedData = dataWidget!.data;
                    for (var folder in pathWidget!.pathOfBoard) {
                      nestedData = nestedData[folder];
                    }

                    dynamic targetFolder = nestedData[index];

                    if (targetFolder["folder"] == true) {
                      targetFolder["buttons"].add(receivedItem);

                      nestedData.remove(receivedItem);


                      dataWidget.onDataChange(dataWidget.data);

                      context.findAncestorStateOfType<HomePageState>()?.saveUpdatedData(dataWidget.data);

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
                        homePageState?.removeFolder(index);
                      } else {
                        updateGridPath(index, "buttons");
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