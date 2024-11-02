import 'dart:async';
import 'package:flutter/material.dart';
import 'package:matchup/screens/exercise/score_modal.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:camera/camera.dart';
import 'screens/bottom_navigation_bar.dart';
import 'models/UserProvider.dart';

import 'screens/login/login_screen.dart';

// 테스트 용도
import 'screens/camera/camera_screen.dart';


// 테스트용 링크
//import 'screens/calendar/calendar_screen.dart';
import 'screens/exercise/exercise_screen.dart';
//import 'screens/grade/grade_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting('ko_KR', null);
  cameras = await availableCameras();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobiMove!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          return userProvider.isLoggedIn
              ? BottomNavBar(accessToken: userProvider.accessToken ?? '')
              : CameraScreen();
        },
      ),
    );
  }
}

// 목록 확인용
// 기본(로그인 화면) :  LoginScreen
// 캘린더           : CalendarScreen
// 운동 목록        : ExerciseScreen
// 랭킹             : GradeScreen
// 메인 화면        : CameraScreen
