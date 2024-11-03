import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'body_scan.dart';
import 'gallery_screen.dart';
import 'package:matchup/models/UserProvider.dart';

final String baseUrl = 'http://192.168.35.91:8000/api/v1';
// final String baseUrl = 'http://10.254.3.138:8000/api/v1';

class CameraScreen extends StatelessWidget {
  Future<void> sendGetRequest(BuildContext context) async {
    final uri = Uri.parse("$baseUrl/health/init/");
    var request = http.MultipartRequest('GET', uri);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.accessToken;

    if (token != null) {
      print('Token: $token');
      request.headers['Authorization'] = 'Bearer $token';

      try {
        final response = await request.send();
        if (response.statusCode == 200) {
          print('Request successful');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BodyScanScreen()),
          );
        } else {
          print('Request failed with status: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Request failed with status: ${response.statusCode}')),
          );
        }
      } catch (e) {
        print('Request failed with error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request failed with error: $e')),
        );
      }
    } else {
      print('Token is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token is missing')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // 배경색 설정
      appBar: AppBar(
        backgroundColor: Color(0xFFD4C6F0), // AppBar 색상 설정
        elevation: 0,
        toolbarHeight: screenHeight * 0.1, // AppBar 높이 설정
        leading: Padding(
          padding: EdgeInsets.only(left: 16.0), // 여백 조정
          child: IconButton(
            icon: Icon(Icons.account_circle, size: screenWidth * 0.08), // 아이콘 크기 조정
            onPressed: () {
              // 필요한 경우 여기에 추가 작업 작성
            },
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04), // 화면 여백 설정
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
          crossAxisAlignment: CrossAxisAlignment.stretch, // 가로로 최대 공간 사용
          children: <Widget>[
            //SizedBox(height: screenHeight * 0.1), // 상단 여백
            Flexible(
              child: Image.asset(
                'lib/assets/images/logo.png',
                fit: BoxFit.contain, // Keeps image contained within widget
                width: screenWidth * 0.1, // Adjust width as needed
              ),
            ),
            // SizedBox(height: screenHeight * 0.03), // 이미지와 텍스트 간격
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Self-',
                    style: TextStyle(
                      fontSize: screenWidth * 0.2,
                      fontFamily: "Timmana",
                      fontWeight: FontWeight.w300,
                      color: Colors.black, // Color for "Mobi"
                    ),
                  ),
                  TextSpan(
                    text: 'PT!',
                    style: TextStyle(
                      fontSize: screenWidth * 0.2,
                      fontFamily: "Timmana",
                      fontWeight: FontWeight.w300,
                      color: Colors.red, // Color for "Move"
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton( // 체형 측정 버튼
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4C6F0), // 버튼 배경색
                foregroundColor: Colors.black, // 버튼 텍스트 색상
                padding: EdgeInsets.symmetric(vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0), // 둥근 버튼 모양
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BodyScanScreen()), // 버튼 클릭 시 BodyScanScreen으로 이동
                );
              },
              child: SizedBox(
                width: screenWidth * 0.6, // 버튼 너비
                child: Center(
                  child: Text(
                    '체형 측정하기',
                    style: TextStyle(fontSize: screenHeight * 0.025),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.015), // 버튼 간격
            ElevatedButton( // 측정 비교 갤러리 버튼
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4C6F0), // 버튼 배경색
                foregroundColor: Colors.black, // 버튼 텍스트 색상
                padding: EdgeInsets.symmetric(vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0), // 둥근 버튼 모양
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GalleryScreen()), // 버튼 클릭 시 PictureGallery 이동
                );
              },
              child: SizedBox(
                width: screenWidth * 0.6, // 버튼 너비
                child: Center(
                  child: Text(
                    '측정 비교 갤러리',
                    style: TextStyle(fontSize: screenHeight * 0.025),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
