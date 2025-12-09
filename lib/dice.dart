import 'dart:math';
import 'face_count.dart';
import 'face_value.dart';

/// サイコロ本体クラス。
/// コンストラクタで与えられた FaceCount に従って
/// FaceValue(1)〜FaceValue(n) のリストを生成して保持する（ファクトリ方式）。
/// roll() でランダムに出目を選び、current を更新して返す。
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
  FaceValue roll() {
    current = faces[_random.nextInt(faces.length)];
    return current;
  }
}