import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ButtonDetailsScreen extends StatelessWidget {
  final String buttonText;
  final List<dynamic> buttonInstances;

  ButtonDetailsScreen({
    required this.buttonText,
    required this.buttonInstances,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Map<DateTime, List<dynamic>> groupedByDay = {};
    for (var instance in buttonInstances) {
      DateTime timestamp = instance['timestamp'].toDate();
      DateTime dateOnly =
          DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (groupedByDay.containsKey(dateOnly)) {
        groupedByDay[dateOnly]!.add(instance);
      } else {
        groupedByDay[dateOnly] = [instance];
      }
    }

    List<DateTime> sortedDays = groupedByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text('$buttonText Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: sortedDays.length,
          itemBuilder: (context, index) {
            DateTime day = sortedDays[index];
            List<dynamic> instancesForDay = groupedByDay[day]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    DateFormat('MMMM d, y').format(day),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: instancesForDay.length,
                  itemBuilder: (context, instanceIndex) {
                    var instance = instancesForDay[instanceIndex];
                    String time = DateFormat('h:mm a')
                        .format(instance['timestamp'].toDate());

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            if (instanceIndex != 0)
                              Container(
                                width: 2.0,
                                height: 30.0,
                                color: theme.dividerColor,
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              width: 12.0,
                              height: 12.0,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (instanceIndex != instancesForDay.length - 1)
                              Container(
                                width: 2.0,
                                height: 30.0,
                                color: theme.dividerColor,
                              ),
                          ],
                        ),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: theme.cardTheme.shadowColor != null
                                  ? [
                                      BoxShadow(
                                        color: theme.cardTheme.shadowColor!
                                            .withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              'Time: $time',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
