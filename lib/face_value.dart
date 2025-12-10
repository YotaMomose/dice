import 'face_count.dart';

/// サイコロの出目を表すクラス。強化システム対応。
/// baseValue: 元の値（1〜面数）
/// bonusValue: 強化値（初期値 0）
/// effectiveValue: 最終的な出目（baseValue + bonusValue）
class FaceValue {
  /// 元の出目値（不変）
  final int baseValue;

  /// 強化値。加算可能（初期値 0）
  int bonusValue;

  /// 最終的な出目値を計算して返す
  int get effectiveValue => baseValue + bonusValue;

  /// コンストラクタ。baseValue は範囲外なら RangeError を投げる。
  FaceValue(int baseValue, FaceCount faceCount, {int bonusValue = 0})
      : baseValue = baseValue,
        bonusValue = bonusValue {
    if (baseValue < 1 || baseValue > faceCount.value) {
      throw RangeError.range(baseValue, 1, faceCount.value, 'baseValue',
          'FaceValue baseValue must be in range 1..${faceCount.value}');
    }
    if (bonusValue < 0) {
      throw ArgumentError.value(
          bonusValue, 'bonusValue', 'bonusValue must be non-negative');
    }
  }

  @override
  String toString() => 'FaceValue(base: $baseValue, bonus: $bonusValue, effective: $effectiveValue)';
}