import 'package:flutter/material.dart';

class FourTouchActivity extends StatefulWidget {
  final List<ActivityItem> activities;

  const FourTouchActivity({Key? key, required this.activities})
      : super(key: key);

  @override
  _FourTouchActivityState createState() => _FourTouchActivityState();
}

class _FourTouchActivityState extends State<FourTouchActivity>
    with SingleTickerProviderStateMixin {
  late List<bool> _isCheckedList;
  late AnimationController _animationController;
  bool _isVisible = true;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _isCheckedList = List.filled(widget.activities.length, false);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  void _checkCompletion() {
    if (_isCheckedList.every((isChecked) => isChecked)) {
      setState(() {
        _isVisible = false;
        _animate = true;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "4 Things I Can Touch",
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Visibility(
          visible: _isVisible,
          replacement: AnimatedOpacity(
            opacity: _animate ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1800),
            child: Center(
              child: ScaleTransition(
                scale: _animationController.drive(
                  CurveTween(curve: Curves.elasticOut),
                ),
                child: const Text(
                  "Great Job!",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _buildActivityList(context, isMobile),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActivityList(BuildContext context, bool isMobile) {
    return List.generate(widget.activities.length, (index) {
      final activity = widget.activities[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: 125,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: activity.color,
            border: Border.all(color: activity.borderColor, width: 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  activity.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 20 : 30,
                    overflow: TextOverflow.ellipsis,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text(
                        "Done?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: _isCheckedList[index],
                      onChanged: (value) {
                        setState(() {
                          _isCheckedList[index] = value ?? false;
                          _checkCompletion();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class ActivityItem {
  final String title;
  final Color color;
  final Color borderColor;

  ActivityItem({
    required this.title,
    required this.color,
    required this.borderColor,
  });
}
/*import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: FourTouchActivity(
      activities: [
        ActivityItem(
          title: "Feel a fluffy blanket",
          color: Colors.lightBlueAccent,
          borderColor: Colors.blue,
        ),
        ActivityItem(
          title: "Press a cool metal spoon",
          color: Colors.lightGreenAccent,
          borderColor: Colors.green,
        ),
        ActivityItem(
          title: "Squish a stress ball",
          color: Colors.orangeAccent,
          borderColor: Colors.deepOrange,
        ),
        ActivityItem(
          title: "Run fingers over textured paper",
          color: Colors.pinkAccent,
          borderColor: Colors.pink,
        ),
      ],
    ),
  ));
}
*/

/*If you're receiving data from a chatbot or external source, you can create the activities list dynamically. For example:

List<ActivityItem> activitiesFromChatbot = chatbotResponse.map((activity) {
  return ActivityItem(
    title: activity['title'],
    color: Color(activity['colorHex']),
    borderColor: Color(activity['borderColorHex']),
  );
}).toList();

runApp(FourTouchActivity(activities: activitiesFromChatbot));
*/

/*Activities List
Feel a fluffy blanket
Press a cool metal spoon
Squish a stress ball
Run fingers over textured paper
Touch a smooth pebble
Hold a soft stuffed animal
Press your hand on a cold glass of water
Run your fingers through sand
Tap on a wooden block
Stroke a silky ribbon
Press on a foam cushion
Hold an ice cube briefly
Feel the bark of a tree
Touch the soft leaves of a plant
Run your fingers over a patterned cloth
Tap gently on a glass surface
Play with a squishy toy
Touch a warm mug of tea (not too hot)
Feel the smooth surface of a polished stone
Rub a piece of velvet cloth*/