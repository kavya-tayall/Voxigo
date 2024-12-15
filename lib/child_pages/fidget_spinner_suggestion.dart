import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';


class FidgetSpinnerHome extends StatefulWidget {
  @override
  _FidgetSpinnerHomeState createState() => _FidgetSpinnerHomeState();
}


class _FidgetSpinnerHomeState extends State<FidgetSpinnerHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  AudioPlayer player = AudioPlayer();
  double _rotationSpeed = 0;
  double _currentAngle = 0;
  double _friction = 0.003;
  double _threshold = 0.00001;


  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(() {
      setState(() {

        if (_rotationSpeed.abs() > _threshold){
          if (_rotationSpeed > 0) {
            _rotationSpeed -= _friction;
            if (_rotationSpeed < 0) _rotationSpeed = 0;
          }
          if (_rotationSpeed < 0){
            _rotationSpeed += _friction;
            if (_rotationSpeed > 0){
              _rotationSpeed = 0;
            }
          }
        }
        print(_rotationSpeed);
        player.setPlaybackRate(_rotationSpeed);
        _currentAngle -= _rotationSpeed;
      });
    });
    _controller.repeat();
  }


  void playSound() {
    player.setPlaybackRate(_rotationSpeed);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void _spinFidgetSpinnerPointer(PointerMoveEvent event) {
    setState(() {

      _rotationSpeed += sqrt(event.delta.dx * event.delta.dx + event.delta.dy * event.delta.dy) * 0.005;
      sqrt(event.delta.dx * event.delta.dx + event.delta.dy * event.delta.dy);
      if (_rotationSpeed > 1) _rotationSpeed = 1;
    });
  }


  void _spinFidgetSpinnerTouch(DragUpdateDetails details) {
    setState(() {
      if (details.primaryDelta != null) {

        _rotationSpeed += sqrt(details.delta.dx * details.delta.dx + details.delta.dy * details.delta.dy) * 0.005;
        if (_rotationSpeed > 1) _rotationSpeed = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
            child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 5, style: BorderStyle.solid))),
              child: Padding(
                  padding: EdgeInsets.only(bottom: 10, top: 10), child: Text("Fidget Spinner Simulator", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold), textAlign: TextAlign.center,)),
            ),
          )),
      body: Center(
        child: GestureDetector(
          onPanUpdate: _spinFidgetSpinnerTouch,
          child: MouseRegion(
            onEnter: (_) {

            },
            child: Listener(
              onPointerMove: _spinFidgetSpinnerPointer,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _currentAngle,
                    child: child,
                  );
                },
                child: Container(
                  height: 350,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/imgs/final_spinner.png'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}