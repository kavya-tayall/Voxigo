import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../child_pages/home_page.dart';
import 'buttons.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:path/path.dart' as p;

class Grid extends StatefulWidget {
  final Function(FirstButton) onButtonPressed;
  final String childId; // Add childId as a parameter

  Grid({
    required this.onButtonPressed,
    required this.childId, // Initialize childId
  });

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
    context
        .findAncestorStateOfType<HomePageState>()
        ?.saveUpdatedData(dataWidget!.data.cast<String, dynamic>());
    context.findAncestorStateOfType<HomePageState>()?.updateGrid();
  }

  void removeItem(String itemId) {
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    if (dataWidget == null || pathWidget == null) {
      print("DataWidget or PathWidget is null. Cannot remove item.");
      return;
    }

    setState(() {
      dynamic nestedData = dataWidget.data;
      for (var folder in pathWidget.pathOfBoard) {
        nestedData = nestedData[folder];
      }

      nestedData.removeWhere((item) => item['id'] == itemId);
      visibleButtons.removeWhere((item) => item['id'] == itemId);
    });

    dataWidget.onDataChange(dataWidget.data);
    print(
        "Item with ID $itemId removed for child ID ${widget.childId}."); // Log with childId
  }

  Future<void> removeFolder(String folderId) async {
    // Retrieve the data and path widgets
    final dataWidget = DataWidget.of(context);
    final pathWidget = PathWidget.of(context);

    // Ensure widgets are not null
    if (dataWidget == null || pathWidget == null) {
      print("DataWidget or PathWidget is null. Cannot proceed.");
      return;
    }

  // Show a confirmation dialog to the user
bool? confirmed = await showDialog(
  context: context,
  builder: (BuildContext dialogContext) {
    final theme = Theme.of(dialogContext);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface, // Use themed background
      title: Text(
        "Delete Folder",
        style: theme.textTheme.headlineSmall?.copyWith(color: theme.elevatedButtonTheme.style?.backgroundColor?.resolve({})),
        
         // Use themed title style
      ),
      content: Text(
        "Are you sure you want to delete this folder and all its contents?",
        style: theme.textTheme.bodyMedium, // Use themed content text style
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) , // Use themed primary color
          ),
          child: const Text("Cancel",),
          onPressed: () {
            Navigator.of(dialogContext).pop(false);
          },
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error, // Use themed error color
          ),
          child: const Text("Delete"),
          onPressed: () {
            Navigator.of(dialogContext).pop(true);
          },
        ),
      ],
    );
  },
);


    if (confirmed == true) {
      try {
        setState(() {
          // Traverse to the nested data structure based on the path
          dynamic nestedData = dataWidget.data;
          for (var folder in pathWidget.pathOfBoard) {
            nestedData = nestedData[folder];
          }

          // Remove the folder from both nested data and visible buttons
          nestedData.removeWhere((item) => item['id'] == folderId);
          visibleButtons.removeWhere((item) => item['id'] == folderId);
        });

        // Notify DataWidget of the change
        await dataWidget.onDataChange(dataWidget.data);
        print(
            "Folder with ID $folderId removed for child ID ${widget.childId}."); // Log with childId
      } catch (error) {
        print("Error while removing folder: $error");
      }
    } else {
      print("Folder deletion canceled by the user.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (visibleButtons.isEmpty || appDirectory == null) {
      print("visibleButtons is empty in grid or appDirectory is null");
      if (visibleButtons.length == 0) {
        return Center(
          child: Text("No buttons to display."),
        );
      } else {
        return Center(
          child: CircularProgressIndicator(),
        );
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        // Dynamically determine crossAxisCount and button size
        int crossAxisCount = screenWidth < 600
            ? 3 // For mobile: 3 items per row
            : (screenWidth / 120)
                .floor(); // Approx. 120px per icon for larger screens
        double buttonSize =
            (screenWidth / crossAxisCount) - 16; // Adjust for padding

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0), // Consistent padding
            child: ReorderableGridView.builder(
              key: UniqueKey(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              physics:
                  NeverScrollableScrollPhysics(), // Prevent internal scrolling
              shrinkWrap: true,
              itemCount: visibleButtons.length,
              onReorder: (oldIndex, newIndex) async {
                await reorderGrid(oldIndex, newIndex);
                setState(() {});
              },
              itemBuilder: (BuildContext context, int index) {
                final item = visibleButtons[index];

                final String childBoardDirectory = p.join(
                  appDirectory?.path ?? '',
                  widget.childId,
                  'board_images',
                );
                final String imagePath =
                    p.join(childBoardDirectory, item["image_url"]);

                final label = item["label"] ?? 'No Label';

                final itemKey = ValueKey('${item["id"]}_$index');

                if (item["folder"] == false) {
                  return LongPressDraggable<Map<String, dynamic>>(
                    key: itemKey,
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
                        final homePageState =
                            context.findAncestorStateOfType<HomePageState>();
                        if (homePageState?.inRemovalState == true) {
                          removeItem(item["id"]);
                          print("Item with ID ${item["id"]} removed.");
                        } else {
                          widget.onButtonPressed(FirstButton(
                            id: item["id"],
                            imagePath: imagePath,
                            text: label,
                            size: buttonSize,
                            onPressed: () {},
                          ));
                        }
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

                          context
                              .findAncestorStateOfType<HomePageState>()
                              ?.saveUpdatedData(dataWidget.data);

                          context
                              .findAncestorStateOfType<HomePageState>()
                              ?.updateGrid();
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
                          final homePageState =
                              context.findAncestorStateOfType<HomePageState>();
                          if (homePageState?.inRemovalState == true) {
                            removeFolder(item["id"]);
                          } else {
                            updateGridPath(index, "buttons");
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
