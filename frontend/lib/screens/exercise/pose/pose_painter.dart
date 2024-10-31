import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

// 좌표 변환 담당. 좌표를 계산 후 매핑하여 관절 연결하는데 씀
// translateX, translateY
import 'coordinates_translator.dart';

// 좌표를 기반으로 관절 연결을 포함할 수 있는 렌더링이나 그리기를 처리
class PosePainter extends CustomPainter {
  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    // 초록: 33개의 관절 포인트(랜드마크) 색깔
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = Colors.white;

    // 파랑: 왼쪽 선 색깔(왼팔~왼다리)
    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    // 파랑: 오른쪽 선 색깔(오른팔~오른다리)
    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    // 추출된 관절 포인트 갯수만큼 점 그리기
    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
            Offset(
              translateX(landmark.x, rotation, size, absoluteImageSize),
              translateY(landmark.y, rotation, size, absoluteImageSize),
            ),
            1,
            paint);
      });

      // 점1과 점2를 선으로 이어주는 함수(랜드마크 타입1, 랜드마크 타입2, 선 색깔 타입)
      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
            Offset(translateX(joint1.x, rotation, size, absoluteImageSize),
                translateY(joint1.y, rotation, size, absoluteImageSize)),
            Offset(translateX(joint2.x, rotation, size, absoluteImageSize),
                translateY(joint2.y, rotation, size, absoluteImageSize)),
            paintType);
      }

      // 팔 연결(어깨, 팔꿈치 | 팔꿈치, 손목 | 좌/우)
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      // 몸 연결(어깨, 골반 | 좌/우)
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);

      // 다리 연결(골반, 무릎 | 무릎 발목 | 좌/우)
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);
    }
  }

  // 허리 좌표를 반환하는 함수 : getWaistCoordinates
  static List<Offset> getWaistCoordinates(List<Pose> poses) {
    final List<Offset> coordinates = [];
    for (final pose in poses) {
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftShoulder]!.x,
          pose.landmarks[PoseLandmarkType.leftShoulder]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightShoulder]!.x,
          pose.landmarks[PoseLandmarkType.rightShoulder]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftElbow]!.x,
          pose.landmarks[PoseLandmarkType.leftElbow]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightElbow]!.x,
          pose.landmarks[PoseLandmarkType.rightElbow]!.y,
        ),
      );
    }
    return coordinates;
  }

  // 스쿼트 운동(골반 운동)을 위한 좌표 반환 함수 : getSquatCoordinates
  static List<Offset> getSquatCoordinates(List<Pose> poses) {
    final List<Offset> coordinates = [];
    for (final pose in poses) {
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftHip]!.x,
          pose.landmarks[PoseLandmarkType.leftHip]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightHip]!.x,
          pose.landmarks[PoseLandmarkType.rightHip]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftKnee]!.x,
          pose.landmarks[PoseLandmarkType.leftKnee]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightKnee]!.x,
          pose.landmarks[PoseLandmarkType.rightKnee]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftAnkle]!.x,
          pose.landmarks[PoseLandmarkType.leftAnkle]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightAnkle]!.x,
          pose.landmarks[PoseLandmarkType.rightAnkle]!.y,
        ),
      );
    }
    return coordinates;
  }

   // 목 운동을 위한 좌표 반환 함수 : getNeckCoordinates
  static List<Offset> getNeckCoordinates(List<Pose> poses) {
    final List<Offset> coordinates = [];
    for (final pose in poses) {
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.nose]!.x,
          pose.landmarks[PoseLandmarkType.nose]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftEye]!.x,
          pose.landmarks[PoseLandmarkType.leftEye]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftShoulder]!.x,
          pose.landmarks[PoseLandmarkType.leftShoulder]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightShoulder]!.x,
          pose.landmarks[PoseLandmarkType.rightShoulder]!.y,
        ),
      );
    }
    return coordinates;
  }

  // 런지 운동을 위한 좌표 반환 함수 : getLegCoordinates
  static List<Offset> getLegCoordinates(List<Pose> poses) {
    final List<Offset> coordinates = [];
    for (final pose in poses) {
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftHip]!.x,
          pose.landmarks[PoseLandmarkType.leftHip]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightHip]!.x,
          pose.landmarks[PoseLandmarkType.rightHip]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftKnee]!.x,
          pose.landmarks[PoseLandmarkType.leftKnee]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightKnee]!.x,
          pose.landmarks[PoseLandmarkType.rightKnee]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.leftAnkle]!.x,
          pose.landmarks[PoseLandmarkType.leftAnkle]!.y,
        ),
      );
      coordinates.add(
        Offset(
          pose.landmarks[PoseLandmarkType.rightAnkle]!.x,
          pose.landmarks[PoseLandmarkType.rightAnkle]!.y,
        ),
      );
    }
    return coordinates;
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }
}



