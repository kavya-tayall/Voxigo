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
  int _remainingTime = 5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: 5)
    )..addListener(() {
      setState(() {});
    });

    _breathingAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startBreathingCycle();
  }

  Future<void> _startBreathingCycle() async {
    await Future.delayed(const Duration(seconds: 1));
    _controller.repeat(reverse: true);
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _remainingTime--;
        if (_remainingTime == 0) {
          if (_breathingText == 'Inhale') {
            _breathingText = 'Exhale';
          } else {
            _count += 1;
            _breathingText = 'Inhale';
          }
          _remainingTime = 5;
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
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Breathing Exercise",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
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
          ),
          Visibility(
            visible: (_count < 4),
            replacement: AnimatedOpacity(
              opacity: (_count > 4) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Center(
                  child: Text(
                    "All Done!",
                    style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )),
            ),
            child: Center(
              child: Container(
                width: 400 * _breathingAnimation.value,
                height: 400 * _breathingAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        (_remainingTime).toString(),
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Text(
                        _breathingText,
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "Deep Breathing",
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}