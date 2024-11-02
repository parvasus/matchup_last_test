import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:matchup/models/UserProvider.dart';
import 'image_viewer.dart';

// 갤러리 화면을 보여주는 StatefulWidget 정의
class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

// 갤러리 화면의 상태 클래스
class _GalleryScreenState extends State<GalleryScreen> {
  List<String> imageList = []; // 이미지 URL 리스트
  bool isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    fetchImages(); // 이미지를 가져오는 함수 호출
  }

  // 이미지 리스트를 서버에서 가져오는 함수
  Future<void> fetchImages() async {
    final String baseUrl = 'http://192.168.35.91:8000/api/v1';
    // final String baseUrl = 'http://10.254.3.138:8000/api/v1'; // 예시 URL

    // Provider를 이용하여 UserProvider에서 토큰 가져오기
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.accessToken;

    // 토큰이 없을 경우 처리
    if (token == null) {
      print('Token is null');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // 서버로부터 health 이미지 데이터를 가져오는 요청
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/health/image"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body); // JSON 데이터를 파싱
        List<String> images = [];
        for (var entry in data['images']) {
          String? frontUrl = entry['front_url'];
          String? sideUrl = entry['side_url'];
          if (frontUrl != null && frontUrl != "url") {
            images.add(frontUrl); // front_url 추가
          }
          if (sideUrl != null && sideUrl != "url") {
            images.add(sideUrl); // side_url 추가
          }
        }
        setState(() {
          imageList = images;
          isLoading = false; // 로딩 상태 종료
        });
      } else {
        throw Exception('Failed to load images'); // 오류 발생 시 예외 처리
      }
    } catch (e) {
      print('Error fetching images: $e');
      setState(() {
        isLoading = false; // 로딩 상태 종료
      });
    }
  }

  // 화면을 빌드하는 함수
  @override
  Widget build(BuildContext context) {
    final int crossAxisCount = 3; // 그리드 열 수
    final double gridSpacing = 4.0; // 그리드 간격
    final double borderSize = 1.0; // 이미지 테두리 두께

    return Scaffold(
      appBar: AppBar(
        title: Text('갤러리'), // AppBar 제목
        backgroundColor: Color(0xFFBBBBEE), // AppBar 배경색
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때 로딩 표시
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0), // 좌우 여백 추가
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
          ),
          itemCount: imageList.isEmpty ? 9 : imageList.length, // 이미지가 없을 경우 빈 칸 9개 생성
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              // 이미지를 클릭했을 때 전체 화면으로 보기
              onTap: () {
                if (imageList.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewer(
                        imageList: imageList,
                        initialIndex: index,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: borderSize,
                  ),
                ),
                // 이미지가 있을 경우 네트워크 이미지 표시, 없을 경우 아이콘 표시
                child: imageList.isNotEmpty && index < imageList.length
                    ? Image.network(
                  imageList[index],
                  fit: BoxFit.cover,
                )
                    : Center(
                  child: Icon(
                    Icons.image, // 자리 표시 아이콘
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
