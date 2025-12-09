import 'face_count.dart';

/// サイコロの出目を表す不変クラス。
/// 値は 1 〜 faceCount.value の範囲でなければならない。
class FaceValue {
  /// 出目の値（不変）
  final int value;

  /// コンストラクタ。範囲外なら RangeError を投げる。
  FaceValue(this.value, FaceCount faceCount) {
    if (value < 1 || value > faceCount.value) {
      throw RangeError.range(value, 1, faceCount.value, 'value',
          'FaceValue must be in range 1..${faceCount.value}');
    }
  }

  @override
  String toString() => 'FaceValue($value)';
}