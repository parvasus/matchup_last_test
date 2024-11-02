// 영상 재생 구현 코드
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'exercise_camera.dart';

class HipStretchScreen extends StatefulWidget {
  @override
  _HipStretchScreenState createState() => _HipStretchScreenState();
}

class _HipStretchScreenState extends State<HipStretchScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('lib/assets/video/squat.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();  // 비디오 자동 재생
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('스쿼트'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(  // Center 위젯 추가
              child: _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Center(child: CircularProgressIndicator()),
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                // 비디오 정지
                _controller.pause(); // 비디오를 즉시 일시 정지
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExerciseCameraScreen(exerciseId: 2, exerciseName: "스쿼트")),
                );
              },
              child: Text('운동하기 가기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFBBBBEE),
                foregroundColor: Color(0xFF000000),
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
