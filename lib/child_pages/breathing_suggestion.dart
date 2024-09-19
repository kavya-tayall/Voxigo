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
  int _countdown = 3;

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

  Future<void> _startBreathingCycle() async {
    await Future.delayed(const Duration(seconds: 1));
    _controller.repeat(reverse: true);
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      setState(() {
        if (_breathingText == 'Inhale') {
          _breathingText = 'Exhale';
        } else {
          this._count += 1;
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
      appBar: AppBar(),
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
        ),
        Visibility(
          visible: (this._count < 4),
          replacement: AnimatedOpacity(
            opacity: (this._count > 4) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: Center(child: Text("All Done!", style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold), textAlign: TextAlign.center,))),
          child: Center(
            child: Container(
              width: 200 * _breathingAnimation.value,
              height: 200 * _breathingAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(child: Text((this._count+1).toString(), style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
            ),
          ),
        ),
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
        Visibility(
          visible: (this._count < 4),
          child: Positioned(
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
          ),
        )
      ]),
    );
  }
}
