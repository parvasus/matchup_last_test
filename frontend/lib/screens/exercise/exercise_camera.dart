import 'package:flutter/material.dart';
import 'package:matchup/screens/exercise/pose/pose_painter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'pose/pose_detector_view.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:matchup/models/UserProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:collection'; // 큐 사용을 위해 추가
import 'score_modal.dart';

class ExerciseCameraScreen extends StatefulWidget {
  final int exerciseId; // 운동 ID
  final String exerciseName; // 운동 이름

  ExerciseCameraScreen({required this.exerciseId, required this.exerciseName});

  @override
  _ExerciseCameraScreenState createState() => _ExerciseCameraScreenState();
}

// 운동을 할 때, 실시간으로 자세를 분석하고 피드백을 제공하는 역할을 하는 클래스
// 웹소켓을 열어두고 운동이 진행되는 동안 데이터를 주고받는 기능을 포함
class _ExerciseCameraScreenState extends State<ExerciseCameraScreen> {
  late Timer _timer; // 운동 시작 전 카운트다운을 위한 타이머
  late Timer _coordinateTimer; // 실시간 좌표 전송을 위한 타이머
  int _remainingTime = 3; // 10초 후에 운동 시작되도록 타이머 설정
  bool _isExercising = false; // 운동 상태 여부
  late WebSocketChannel _channel; // 웹소켓 채널
  List<Pose> _detectedPoses = []; // 감지된 자세 목록
  String feedback = ""; // 피드백 메시지
  int realCount = 0; // 실시간 카운트
  int sets = 0; // 세트 수
  bool _isWebSocketConnected = false; // 웹소켓 연결 상태

  FlutterTts flutterTts = FlutterTts(); // TTS 객체
  Queue<String> ttsQueue = Queue<String>(); // TTS 큐
  String lastSpokenFeedback = ""; // 마지막으로 발화된 피드백
  bool isSpeaking = false; // 현재 TTS 발화 중 여부

  // initState: TTS, 웹소켓 연결, 타이머 시작
  @override
  void initState() {
    super.initState();
    _initializeTTS(); // TTS 초기화
    _connectWebSocket(); // 웹소켓 연결
    _startTimer(); // 카운트다운 타이머 시작
  }

  // TTS 초기화 함수: 실시간 피드백을 음성 피드백으로 제공
  void _initializeTTS() {
    flutterTts.setLanguage('ko-KR').catchError((error) {
      print("Error setting language: $error");
    }); // TTS 언어 설정
    flutterTts.setSpeechRate(0.5); // 말하는 속도 설정

    // TTS가 끝나면 큐에서 다음 피드백을 발화
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
        if (ttsQueue.isNotEmpty) {
          _speak();
        }
      });
    });
  }

  // 웹소켓을 통해 서버에 연결하는 함수
  // 운동 ID와 인증 토큰을 초기 메시지로 전송하여 서버와 통신을 시작함
  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:8000/api/v1/exercise/ws'),
      );

      // 사용자 인증을 위해 Provider에서 액세스 토큰을 가져옴
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String? accessToken = userProvider.accessToken;
      _channel.sink.add(jsonEncode({
        "exercise_id": widget.exerciseId, // 운동 종류(목, 스쿼트, 다리, 허리)
        "access_token": accessToken,
      })); // 웹소켓에 초기 메시지를 전송

      // 서버에서 보내는 데이터 수신
      _channel.stream.listen(
            (event) {
          print('WebSocket event: $event');
          try {
            final data = jsonDecode(event);

            // 최종 점수와 총 카운트를 받았을 경우 모달 창으로 결과를 보여줌
            if (data.containsKey('final_score') && data.containsKey('total_count')) {
              int? totalCount = data['total_count'] ?? 0;
              double? finalScore = data['final_score'] ?? 0.0;

              if (totalCount != null && finalScore != null && totalCount >= 4) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return ScoreModal(
                      score: finalScore,
                      exerciseName: widget.exerciseName,
                    );
                  },
                );
              }
            } else {
              // 피드백, 카운트, 세트 정보를 UI에 업데이트
              setState(() {
                feedback = data['feedback'] ?? '';
                realCount = data['counter'] ?? 0;
                sets = data['sets'] ?? 0;
                print('Updated realCount: $realCount, sets: $sets');

                // 새로운 피드백만 TTS로 발화
                if (feedback.isNotEmpty && feedback != lastSpokenFeedback && !ttsQueue.contains(feedback)) {
                  ttsQueue.add(feedback);
                  if (!isSpeaking) {
                    _speak();
                  }
                }
              });
            }
          } catch (e) {
            print('Error parsing JSON: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          setState(() {
            _isWebSocketConnected = false; // 오류 발생 시 웹소켓 연결 상태를 false로 설정
          });
        },
        onDone: () {
          print('WebSocket connection closed.');
          setState(() {
            _isWebSocketConnected = false; // 연결 종료 시 상태 변경
          });
        },
      );

      setState(() {
        _isWebSocketConnected = true; // 웹소켓 연결 성공 시 true로 설정
      });
    } catch (e) {
      print('WebSocket connection failed: $e');
    }
  }

  // 운동 시작 전 10초 동안 카운트다운을 실행하는 함수
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _isExercising = true; // 운동 시작
          _timer.cancel(); // 타이머 종료
          _sendCoordinatesPeriodically(); // 주기적으로 좌표를 전송
        });
      }
    });
  }

  // TTS 발화를 수행하는 함수
  Future<void> _speak() async {
    if (ttsQueue.isNotEmpty) {
      String message = ttsQueue.removeFirst();
      setState(() {
        isSpeaking = true;
        lastSpokenFeedback = message; // 마지막으로 발화한 피드백 저장
      });
      await flutterTts.speak(message); // TTS 발화
    }
  }

  // 위젯 삭제 시 호출: 리소스 확보를 위해 타이머 및 웹소켓 연결 해제
  @override
  void dispose() {
    _timer.cancel(); // 타이머 해제
    if (_coordinateTimer.isActive) {
      _coordinateTimer.cancel(); // 좌표 전송 타이머 해제
    }
    _channel.sink.close(); // 웹소켓 연결 종료
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('운동 시작하기'),
      ),
      body: _isExercising
          ? Stack(
        children: [
          Positioned.fill(
            child: PoseDetectorView(
              onPosesDetected: (poses) {
                setState(() {
                  _detectedPoses = poses; // 감지된 자세 업데이트
                });
              },
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              'Count: $realCount', // 현재 카운트
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Text(
              'Sets: $sets', // 현재 세트
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Text(
              'Feedback: $feedback', // 피드백 메시지
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
      )
          : Center(
        child: Text(
          '$_remainingTime 초 후에 운동이 시작됩니다.', // 운동 시작 전 카운트다운 메시지
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 주기적으로 좌표를 웹소켓으로 전송하는 함수
  void _sendCoordinatesPeriodically() {
    _coordinateTimer = Timer.periodic(Duration(milliseconds: 300), (Timer timer) {
      if (_isExercising && _isWebSocketConnected) {
        List<Offset> coordinates = [];
        switch (widget.exerciseId) {
          case 1:
          // 목 운동 좌표, 현재는 코드에 없음
            break;
          case 2:
            coordinates = PosePainter.getSquatCoordinates(_detectedPoses); // 스쿼트 운동 좌표
            break;
          case 3:
            coordinates = PosePainter.getLegCoordinates(_detectedPoses); // 다리 운동 좌표
            break;
          case 4:
            coordinates = PosePainter.getWaistCoordinates(_detectedPoses); // 허리 운동 좌표
            break;
          default:
            coordinates = [];
        }
        _channel.sink.add(jsonEncode({
          "coordinates": coordinates.map((offset) => customEncode(offset)).toList(),
        })); // 좌표를 JSON 형식으로 웹소켓에 전송
        print('Coordinates: $coordinates');
      } else {
        timer.cancel(); // 운동 중지 시 타이머 해제
      }
    });
  }

  // Offset 객체를 JSON으로 인코딩하는 함수
  dynamic customEncode(dynamic item) {
    if (item is Offset) {
      return {'dx': item.dx, 'dy': item.dy}; // Offset을 JSON 형식으로 변환
    }
    return item;
  }
}
