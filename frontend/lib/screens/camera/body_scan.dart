import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '/models/UserProvider.dart'; // 수정된 경로
import 'camera_screen.dart';

// 35.3 | 35.91
final String baseUrl = 'http://192.168.35.91:8000/api/v1';
// final String baseUrl = 'http://10.254.3.138:8000/api/v1';

class BodyScanScreen extends StatefulWidget {
  const BodyScanScreen({Key? key}) : super(key: key);

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanScreenState extends State<BodyScanScreen> {
  late Future<void> _initializeControllerFuture;
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  int _photoCount = 0; // 현재 촬영된 사진 수
  int _remainingTime = 5; // 타이머 카운트다운 시간
  late Timer _timer; // 타이머 객체

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = initializeCamera();
  }

  // 카메라 초기화 함수
  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _controller.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  // 사진을 캡처하고 저장하는 함수
  Future<void> takePicture() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    try {
      final XFile file = await _controller.takePicture();
      final Directory directory = await getApplicationDocumentsDirectory();
      final String imagePath =
      join(directory.path, 'Photo_${DateTime.now()}.jpg');
      await File(file.path).copy(imagePath); // 캡처된 사진을 지정된 경로에 저장

      setState(() {
        _photoCount++; // 촬영된 사진 수 업데이트
      });

      print('$imagePath : Capture Success!!!'); // 캡처 성공 시 메시지 출력

      await _uploadImage(File(imagePath)); // 저장한 이미지를 서버로 업로드
    } catch (e) {
      print('Error taking picture: $e'); // 오류 발생 시 에러 메시지 출력
      showErrorDialog("사진 저장 중 오류가 발생했습니다. 다시 시도해 주세요."); // 오류 시 경고 표시
    }
  }

  // 서버에 이미지를 업로드하는 함수
  Future<void> _uploadImage(File imageFile) async {
    final uri = Uri.parse("$baseUrl/health/upload/");
    var request = http.MultipartRequest('POST', uri);
    try {
      var pic = await http.MultipartFile.fromPath(
        "file",
        imageFile.path,
        // jpeg 저장
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(pic);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.accessToken;
      if (token != null) {
        print('Token: $token');
        request.headers['Authorization'] = 'Bearer $token';

        var response = await request.send();
        final respStr = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          print('Image uploaded successfully');
          print('Response body: $respStr');
        } else {
          print('Failed to upload image. Status code: ${response.statusCode}');
          print('Response body: $respStr');
          showErrorDialog("이미지 업로드 실패: 서버 연결을 확인해 주세요.");
        }
      } else {
        print('Token is null');
        showErrorDialog("인증 토큰이 없습니다. 다시 로그인해 주세요.");
      }
    } catch (e) {
      print('Error occurred: $e');
      showErrorDialog("서버 연결 실패: 다시 시도해 주세요.");
    }
  }

  // 서버 연결 실패 경고를 표시하는 함수
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("연결 오류"),
        content: Text(message),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // 버튼을 좌우로 분리
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CameraScreen()),
                  ); // CameraScreen으로 이동 (나가기 버튼)
                },
                child: Text("나가기"), // 왼쪽에 위치한 나가기 버튼
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _remainingTime = 5; // 카운트다운 시간을 5초로 리셋
                  });
                  startCountdown(); // 새로운 촬영을 위한 카운트다운 시작
                },
                child: Text("재촬영"), // 오른쪽에 위치한 재촬영 버튼
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 카운트다운을 시작하는 함수 (3초 남았을 때 캡처 실행)
  void startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else { // 0초에 시간 끄고, 사진 찍고
            _timer.cancel();
            takePicture();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();  // 카메라 컨트롤러 해제
    _timer.cancel();        // 타이머 취소
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (!_controller.value.isInitialized) {
              return Center(child: Text('Error: Failed to initialize camera.'));
            }
            return buildCameraPreview();      // 카메라 미리보기 화면
          } else {
            return Center(child: CircularProgressIndicator()); // 로딩 스피너
          }
        },
      ),
    );
  }

  // 카메라 미리보기(buildCameraPreview)를 렌더링하는 위젯
  Widget buildCameraPreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(_controller), // 카메라 미리보기 출력
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              width: 500,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _photoCount < 1 ? startCountdown : null, // 1장만 촬영 가능
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20),
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.black,
                      ),
                      child: Icon(
                        Icons.photo_camera,
                        size: 36,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: '$_remainingTime 초 후에 ',    // 남은 시간 표시
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold),
                        children: <TextSpan>[
                          TextSpan(
                            text: '정면 촬영', // 촬영 대상 (정면)
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '을 시작합니다.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// 캡처된 이미지를 표시하는 화면
class CapturedImageScreen extends StatelessWidget {
  final String imagePath;

  const CapturedImageScreen({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("측정 결과")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.file(File(imagePath)), // 캡처된 이미지 표시
          SizedBox(height: 20),
          Text(
            "추천 운동을 곧 소개합니다.",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ), // 추천 운동 소개 섹션 (현재는 텍스트로 표시)
          SizedBox(height: 20),
          // 여기에 추천 운동 목록 또는 관련 콘텐츠 추가 가능
        ],
      ),
    );
  }
}
