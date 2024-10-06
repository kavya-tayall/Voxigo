import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ButtonDetailsScreen extends StatelessWidget {
  final String buttonText;
  final List<dynamic> buttonInstances;

  ButtonDetailsScreen({required this.buttonText, required this.buttonInstances});

  @override
  Widget build(BuildContext context) {
    // Group button instances by day (using original timestamp for sorting)
    Map<DateTime, List<dynamic>> groupedByDay = {};
    for (var instance in buttonInstances) {
      DateTime timestamp = instance['timestamp'].toDate();
      String date = DateFormat('MMMM d, y').format(timestamp);

      // Create a map with the original DateTime object for sorting
      DateTime dateOnly = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (groupedByDay.containsKey(dateOnly)) {
        groupedByDay[dateOnly]!.add(instance);
      } else {
        groupedByDay[dateOnly] = [instance];
      }
    }

    // Sort the keys (DateTime) in chronological order
    List<DateTime> sortedDays = groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

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
                // Date separator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    DateFormat('MMMM d, y').format(day),
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Events for that day
                ListView.builder(
                  shrinkWrap: true, // Important for nested ListView
                  physics: NeverScrollableScrollPhysics(), // Prevent nested scrolling
                  itemCount: instancesForDay.length,
                  itemBuilder: (context, instanceIndex) {
                    var instance = instancesForDay[instanceIndex];
                    String time = DateFormat('h:mm a').format(instance['timestamp'].toDate());

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline line and bullet
                        Column(
                          children: [
                            if (instanceIndex != 0)
                              Container(
                                width: 2.0,
                                height: 30.0,
                                color: Colors.grey[300],
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              width: 12.0,
                              height: 12.0,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (instanceIndex != instancesForDay.length - 1)
                              Container(
                                width: 2.0,
                                height: 30.0,
                                color: Colors.grey[300],
                              ),
                          ],
                        ),
                        SizedBox(width: 16.0), // Space between the bullet and the text

                        // Event details (timestamp)
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Time: $time',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
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
