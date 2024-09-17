import 'package:flutter/material.dart';
import 'package:animate_gradient/animate_gradient.dart';
import 'dart:async';


class BreathingHome extends StatefulWidget {
  @override
  _BreathingHomeState createState() => _BreathingHomeState();
}

class _BreathingHomeState extends State<BreathingHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathingAnimation;
  Timer? _timer;
  String _breathingText = 'Inhale';
  int _count = 0;
  bool _visibleCircle = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5), // Total duration of one breathing cycle
    )..addListener(() {
      setState(() {});
    });

    _breathingAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startBreathingCycle();
  }

  void _startBreathingCycle() {
    _controller.repeat(reverse: true); // Loops the animation
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      setState(() {;
        if (_breathingText == 'Inhale') {
          _breathingText = 'Exhale';
        } else {
          _breathingText = 'Inhale';
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        AnimateGradient(
            duration: Duration(seconds: 10),
            primaryColors: const [
              Color(0xFFB5B9FF),
              Color(0xFFBD8EF8),
              Color(0xFFA598F8),
            ],
            secondaryColors: const [
              Color(0xFF97A2FF),
              Color(0xFF6EB5FF),
              Color.fromRGBO(173, 216, 230, 1),
            ],
            child: Visibility(
              visible: _visibleCircle,
              child: Center(
                child: Container(
                  width: 200 * _breathingAnimation.value,
                  height: 200 * _breathingAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            )),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child:  Center(
            child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              child: Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 10), child: Text("Deep Breathing", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
            ),
          )
        ),
        Positioned(
            bottom: MediaQuery.of(context).size.height*0.15,
            left: 0,
            right: 0,
            child:  Center(
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                child: Padding(
                    padding: EdgeInsets.only(bottom: 10, top: 10),
                    child: Text(_breathingText, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
              ),
            )
        )
      ]),
    );
  }
}
