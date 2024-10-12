import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:intl/intl.dart';

//feeligns
class FeelingsTable extends StatelessWidget {
  final String searchText;
  final List<dynamic> selectedFeelings;
  final bool isLoading;

  FeelingsTable({
    required this.searchText,
    required this.selectedFeelings,
    required this.isLoading,
  });


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (selectedFeelings.isEmpty) {
      return Center(child: Text('No feelings selected yet'));
    }

    List sortedFeelings = selectedFeelings;
    for (var feeling in sortedFeelings) {
      // Convert Timestamp to DateTime if necessary
      if (feeling['timestamp'] is Timestamp) {
        DateTime time = (feeling['timestamp'] as Timestamp).toDate();
        feeling['timestamp'] = time; // Now it's a DateTime
      }

      // Format the DateTime as a string after the conversion
      if (feeling['timestamp'] is DateTime) {
        feeling['formattedTimestamp'] = DateFormat('h:mm a, MMMM d').format(feeling['timestamp']);
      }
    }

    sortedFeelings.removeWhere((entry) => !entry['text'].toLowerCase().contains(searchText.toLowerCase()));



    return Timeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: 0,
        color: Color(0xff989898),
        indicatorTheme: IndicatorThemeData(
          position: 0,
          size: 20.0,
        ),
        connectorTheme: ConnectorThemeData(
          thickness: 2.5,
        ),
      ),
      physics: ScrollPhysics(),
      builder: TimelineTileBuilder(
        itemCount: sortedFeelings.length,
        contentsAlign: ContentsAlign.values[0],
        contentsBuilder: (context, index) {
          return TimelineTile(
            contents: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Ensure top-left alignment
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${sortedFeelings[index]['text']}",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                  ), // Adjust text styling as needed
                ),
                Text(
                  "${sortedFeelings[index]['formattedTimestamp']}",
                  style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF606060)
                  ), // Adjust text styling as needed
                ),
              ],
            ),
            node: TimelineNode(
              indicator: Image.asset(
                "assets/imgs/${sortedFeelings[index]['text'].toLowerCase()}.png",
                width: 40,
              ),
              startConnector: DashedLineConnector(
                space: 70,
                color: Color(0xFF91A4B1),
              ),
              endConnector: DashedLineConnector(
                space: 70,
                color: Color(0xFF91A4B1),
              ),
            ),
          );
        },
      ),
    );
  }
}
