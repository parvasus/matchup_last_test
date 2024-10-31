import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_commons/google_mlkit_commons.dart';

double translateX(
    double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return size.width - (x * size.width / absoluteImageSize.height);
    case InputImageRotation.rotation270deg:
      return x * size.width / absoluteImageSize.height;
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
}*/

//  상하 반전 때문에 추가함
double translateY(
    double y, InputImageRotation rotation, Size size, Size absoluteImageSize, {bool isFlippedVertically = false}) {
  double translatedY;
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      translatedY = y * size.height / absoluteImageSize.width;
      break;
    case InputImageRotation.rotation270deg:
      translatedY = size.height - (y * size.height / absoluteImageSize.width);
      break;
    case InputImageRotation.rotation180deg:
      translatedY = size.height - (y * size.height / absoluteImageSize.height);
      break;
    default:
      translatedY = y * size.height / absoluteImageSize.height;
  }

  // 상하 반전 적용
  if (isFlippedVertically) {
    translatedY = size.height - translatedY;
  }

  return translatedY;
}

