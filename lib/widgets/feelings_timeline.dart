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
        nodePosition: -1.0, // Align the node further to the left
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
        contentsAlign: ContentsAlign.basic, // Ensures basic alignment of the contents
        contentsBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: 10.0), // Reduced padding for tighter left alignment
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Aligns the content to the top-left
              mainAxisAlignment: MainAxisAlignment.start, // Aligns items to the left
              children: [
                Expanded( // Ensure content spans the full width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                    children: [
                      Text(
                        "${sortedFeelings[index]['text']}",
                        style: TextStyle(
                          fontSize: 18, // Smaller font size for feelings text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5), // Add some spacing between text and timestamp
                      Text(
                        "${sortedFeelings[index]['formattedTimestamp']}",
                        style: TextStyle(
                          fontSize: 14, // Smaller font size for timestamp
                          color: Color(0xFF606060),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        indicatorBuilder: (context, index) => Image.asset(
          "assets/imgs/${sortedFeelings[index]['text'].toLowerCase()}.png",
          width: 40,
        ),
        startConnectorBuilder: (context, index) => DashedLineConnector(
          space: 70,
          color: Color(0xFF91A4B1),
        ),
        endConnectorBuilder: (context, index) => DashedLineConnector(
          space: 70,
          color: Color(0xFF91A4B1),
        ),
      ),
    );



  }
}
