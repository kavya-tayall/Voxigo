import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:intl/intl.dart';


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
      if (feeling['timestamp'] is Timestamp) {
        DateTime time = (feeling['timestamp'] as Timestamp).toDate();
        feeling['timestamp'] = time;
      }

      if (feeling['timestamp'] is DateTime) {
        feeling['formattedTimestamp'] = DateFormat('h:mm a, MMMM d').format(feeling['timestamp']);
      }
    }

    sortedFeelings.removeWhere((entry) => !entry['text'].toLowerCase().contains(searchText.toLowerCase()));



    return Timeline.tileBuilder(
      theme: TimelineThemeData(
        nodePosition: -1.0,
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
        contentsAlign: ContentsAlign.basic,
        contentsBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${sortedFeelings[index]['text']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "${sortedFeelings[index]['formattedTimestamp']}",
                        style: TextStyle(
                          fontSize: 14,
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