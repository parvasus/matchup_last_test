import 'dart:io'; // Flutter 앱이 로컬 파일 시스템, 소켓 통신, HTTP 클라이언트 및 서버, 프로세스 관리 등 다양한 I/O 작업을 수행

import 'dart:ui';

import 'package:google_mlkit_commons/google_mlkit_commons.dart';
// 이 파일은 좌표 변환을 담당할 수 있으며 좌표를 계산하거나 매핑하여 관절을 연결할 수도 있습니다.
// 좌표, 회전 각도, 화면(캔버스) 크기, 원본 이미지의 실제 크기
// 이미지 높이에 실제 좌표 위치(x좌표 * size.width) 비율을 찾은 뒤 해당 비율만큼 다시 빼서 출력 = 90도

double translateX(double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    // 90도로 꺽이면
    case InputImageRotation.rotation90deg:  
      return size.width - (x * size.width / absoluteImageSize.height);
    // 270도(반대로 90도)로 꺽이면
    case InputImageRotation.rotation270deg: 
      return x * size.width / absoluteImageSize.height;
    // 반바퀴 돌면
    case InputImageRotation.rotation180deg:
      return size.width - (x * size.width / absoluteImageSize.width);
    default:
      return x * size.width / absoluteImageSize.width;
  }
}
/*
double translateY(
    double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return y * size.height / absoluteImageSize.width;
    case InputImageRotation.rotation270deg:
      return size.height - (y * size.height / absoluteImageSize.width);
    case InputImageRotation.rotation180deg:
      return size.height - (y * size.height / absoluteImageSize.height);
    default:
      return y * size.height / absoluteImageSize.height;
  }
}

*/
// 상하가 바뀐 탓에 y축 반전 해보려고
// Y 좌표 변환 함수 (Y축 반전 적용)
double translateY(
    double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return y * size.height / absoluteImageSize.width;
    case InputImageRotation.rotation270deg:
      return size.height - (y * size.height / absoluteImageSize.width);
    case InputImageRotation.rotation180deg:
      return size.height - (y * size.height / absoluteImageSize.height);
    default:
      // 기본 회전에서는 Y축을 반전하여 올바른 방향으로 출력
      return size.height - (y * size.height / absoluteImageSize.height);
  }
}