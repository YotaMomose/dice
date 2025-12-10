import 'dart:math';
import 'face_count.dart';
import 'face_value.dart';

/// サイコロ本体クラス。
/// コンストラクタで与えられた FaceCount に従って
/// FaceValue(1)〜FaceValue(n) のリストを生成して保持する（ファクトリ方式）。
/// roll() でランダムに出目を選び、current を更新して返す。
/// 出目は effectiveValue（baseValue + bonusValue）で計算される。
class Dice {
  final FaceCount faceCount;
  final List<FaceValue> faces;
  final Random _random;

  /// 現在の出目。初期化時にランダムで選ばれる。
  late FaceValue current;

  /// コンストラクタ。内部で全ての FaceValue を生成する。
  Dice(this.faceCount, {Random? random})
      : faces = List<FaceValue>.generate(
            faceCount.value, (i) => FaceValue(i + 1, faceCount)),
        _random = random ?? Random() {
    // 初期状態をランダムに決める
    current = faces[_random.nextInt(faces.length)];
  }

  /// サイコロを振ってランダムな FaceValue を current に設定して返す。
  /// 返される値は effectiveValue（baseValue + bonusValue）。
  int roll() {
    current = faces[_random.nextInt(faces.length)];
    return current.effectiveValue;
  }

  /// 指定された面番号（1〜faceCount）のボーナス値を加算する。
  /// faceNumber: 1 から faceCount.value までの値
  void addBonus(int faceNumber, int bonusAmount) {
    if (faceNumber < 1 || faceNumber > faceCount.value) {
      throw RangeError.range(faceNumber, 1, faceCount.value, 'faceNumber');
    }
    if (bonusAmount < 0) {
      throw ArgumentError.value(bonusAmount, 'bonusAmount', 'must be non-negative');
    }
    faces[faceNumber - 1].bonusValue += bonusAmount;
  }

  /// 指定された面番号のボーナス値を取得する。
  int getBonus(int faceNumber) {
    if (faceNumber < 1 || faceNumber > faceCount.value) {
      throw RangeError.range(faceNumber, 1, faceCount.value, 'faceNumber');
    }
    return faces[faceNumber - 1].bonusValue;
  }
}