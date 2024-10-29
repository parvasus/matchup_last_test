import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:matchup/models/UserProvider.dart';
import 'package:http/http.dart' as http;

// CalendarScreen 위젯은 캘린더와 해당 날짜에 해당하는 운동 리스트를 보여주는 화면
class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;                // 현재 포커스된 날짜 (기본값: 오늘 날짜)
  late DateTime _selectedDay;               // 선택된 날짜 (기본값: 오늘 날짜)
  List<String> _selectedDayExercises = [];  // 선택된 날짜에 해당하는 운동 목록

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();           // 초기 포커스 날짜를 현재 날짜로 설정
    _selectedDay = DateTime.now();          // 초기 선택 날짜를 현재 날짜로 설정
    _fetchExercisesForDay(_selectedDay);    // 선택된 날짜의 운동 데이터를 서버에서 가져옴
  }

  // 선택된 날짜에 해당하는 운동 데이터를 서버에서 가져오는 비동기 함수
  Future<void> _fetchExercisesForDay(DateTime day) async {
    // 현재 사용자의 액세스 토큰을 가져옴
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String? accessToken = userProvider.accessToken;

    // API 서버 URL 설정
    final String baseUrl = 'http://192.168.35.91:8000/api/v1'; //

    // 서버에 GET 요청을 보내서 특정 날짜의 운동 세션을 가져옴
    final response = await http.get(
      Uri.parse('$baseUrl/session?date=${day.toIso8601String().split('T')[0]}'),
      headers: {
        'Authorization': 'Bearer $accessToken', // 인증 헤더 추가
        'Content-Type': 'application/json; charset=utf-8',
      },
    );

    // 응답이 성공적일 경우 [운동] 목록을 파싱하여 상태를 업데이트
    if (response.statusCode == 200) {
      List<dynamic> exercises = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        _selectedDayExercises = exercises
            .where((exercise) =>
                DateTime.parse(exercise['date'])
                    .toLocal()
                    .toIso8601String()
                    .split('T')[0] ==
                day.toIso8601String().split('T')[0])
            .map((exercise) => exercise['exercise'].toString())
            .toList();
      });
    } else {
      // 실패한 경우 빈 리스트로 설정하고 예외 발생
      setState(() {
        _selectedDayExercises = [];
      });
      throw Exception('운동 데이터를 불러오는데 실패했습니다');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;    // 화면의 가로 길이
    final screenHeight = MediaQuery.of(context).size.height;  // 화면의 세로 길이 (사용하지 않음_왜안쓰지)

    return Scaffold(
      body: Column(
        children: <Widget>[
          // 캘린더를 보여주는 카드 위젯
          Card(
            margin: EdgeInsets.all(screenWidth * 0.02),
            child: TableCalendar(
              headerStyle: HeaderStyle(
                formatButtonVisible: false,           // 포맷 버튼을 숨김
                titleCentered: true,                  // 캘린더 제목을 가운데로 정렬
              ),
              locale: 'ko_KR', // 한국어 설정
              focusedDay: _focusedDay,                // 현재 포커스된 날짜 설정
              firstDay: DateTime.utc(2010, 10, 16),   // 캘린더의 시작 날짜
              lastDay: DateTime.utc(2030, 3, 14),     // 캘린더의 종료 날짜
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);  // 선택된 날짜와 동일한지 확인
              },
              onDaySelected: (selectedDay, focusedDay) {
                // 날짜 선택 시 호출되는 함수
                setState(() {
                  _selectedDay = selectedDay;         // 선택된 날짜를 업데이트
                  _focusedDay = focusedDay;           // 포커스 날짜를 업데이트
                });
                _fetchExercisesForDay(selectedDay);   // 선택된 날짜의 운동 데이터를 가져옴
              },
            ),
          ),
          // 선택된 날짜의 운동 목록을 보여주는 카드 위젯
          Expanded(
            child: Card(
              margin: EdgeInsets.all(screenWidth * 0.02),
              child: ListView.builder(
                itemCount: _selectedDayExercises.length,        // 운동 목록 개수
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_selectedDayExercises[index]),  // 운동 이름 출력
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}