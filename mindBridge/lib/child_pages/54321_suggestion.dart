import 'package:flutter/material.dart';

class FiveCalmDownHome extends StatefulWidget {
  FiveCalmDownHome({super.key});

  @override
  State<FiveCalmDownHome> createState() => _FiveCalmDownHomeState();
}

class _FiveCalmDownHomeState extends State<FiveCalmDownHome> {
  bool _isChecked1 = false;
  bool _isChecked2 = false;
  bool _isChecked3 = false;
  bool _isChecked4 = false;
  bool _isChecked5 = false;
  bool _isVisible = true;
  bool _animate = false;

  void _calmingCheck() {
    if (_isChecked1 &&
        _isChecked2 &&
        _isChecked3 &&
        _isChecked4 &&
        _isChecked5) {
      _isVisible = false;
      _animate = true;
    }
    print(_isVisible);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final isTablet =
        mediaQuery.size.width >= 600 && mediaQuery.size.width < 1200;
    final isDesktop = mediaQuery.size.width >= 1200;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Calm down with 54321",
                style: TextStyle(
                  fontSize: isMobile
                      ? 20
                      : isTablet
                          ? 24
                          : 30,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(15),
        child: Visibility(
          visible: _isVisible,
          replacement: AnimatedOpacity(
            opacity: _animate ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1800),
            child: Center(
              child: Text(
                "All Done!",
                style: TextStyle(
                  fontSize: isMobile ? 60 : 100,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ..._buildCheckBoxes(context, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCheckBoxes(BuildContext context, bool isMobile) {
    final List<Map<String, dynamic>> activities = [
      {
        "title": "5 things I can see",
        "color": Colors.redAccent,
        "borderColor": Colors.red,
        "isChecked": _isChecked1,
        "onChanged": _toggleChecked1
      },
      {
        "title": "4 things I can touch",
        "color": Colors.orangeAccent,
        "borderColor": Colors.orange,
        "isChecked": _isChecked2,
        "onChanged": _toggleChecked2
      },
      {
        "title": "3 things I can hear",
        "color": Colors.lightGreen,
        "borderColor": Colors.green,
        "isChecked": _isChecked3,
        "onChanged": _toggleChecked3
      },
      {
        "title": "2 things I can smell",
        "color": Colors.lightBlue,
        "borderColor": Colors.blue,
        "isChecked": _isChecked4,
        "onChanged": _toggleChecked4
      },
      {
        "title": "1 thing I can taste",
        "color": Colors.pinkAccent,
        "borderColor": Colors.pink,
        "isChecked": _isChecked5,
        "onChanged": _toggleChecked5
      },
    ];

    return activities.map((activity) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          height: 125,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: activity["color"],
            border: Border.all(color: activity["borderColor"], width: 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(
                flex: 3,
                child: Text(
                  activity["title"],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 25 : 45,
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        "Done?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: isMobile ? 14 : 20,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: activity["isChecked"],
                      onChanged: (value) {
                        setState(() {
                          activity["onChanged"](value);
                          _calmingCheck();
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
    }).toList();
  }

  void _toggleChecked1(bool? value) {
    setState(() {
      _isChecked1 = value ?? false;
    });
  }

  void _toggleChecked2(bool? value) {
    setState(() {
      _isChecked2 = value ?? false;
    });
  }

  void _toggleChecked3(bool? value) {
    setState(() {
      _isChecked3 = value ?? false;
    });
  }

  void _toggleChecked4(bool? value) {
    setState(() {
      _isChecked4 = value ?? false;
    });
  }

  void _toggleChecked5(bool? value) {
    setState(() {
      _isChecked5 = value ?? false;
    });
  }
}
