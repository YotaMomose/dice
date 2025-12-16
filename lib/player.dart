import 'dart:math';
import 'face_count.dart';
import 'dice.dart';

/// プレイヤーの状態と操作を管理するクラス。
/// サイコロの面数、強化値、出目などを一元管理する。
class Player {

  /// プレイヤーのID（1または2）
  final int id;

  /// サイコロインスタンス
  late Dice dice;

  /// 表示用の出目値（アニメーション中の表示用）
  int? displayValue;

  /// サイコロ振り中のフラグ
  bool isRolling = false;

  /// ランダム生成用
  final Random random = Random();

  /// コンストラクタ。初期状態で6面ダイスを生成。
  Player(this.id) {
    dice = Dice(FaceCount(6));
    displayValue = dice.current.effectiveValue;
  }

  /// 現在の面数を取得
  int get currentFaces => dice.faceCount.value;

  /// 最大面数に達しているかを判定
  bool get isMaxFaces => dice.faceCount.isMax;


  /// 面数を増やす（最大面数なら何もしない）
  void increaseFaces() {
    dice = dice.increaseFaceCount();
    displayValue = null;
  }

  /// サイコロを振ってランダムな出目を返す
  int roll() {
    displayValue = dice.roll();
    return displayValue!;
  }

  /// 指定された面にボーナスを追加
  void addBonus(int faceNumber, int bonusAmount) {
    dice.addBonus(faceNumber, bonusAmount);
  }

  /// 指定された面のボーナスを減らす
  void removeBonus(int faceNumber, int bonusAmount) {
    dice.removeBonus(faceNumber, bonusAmount);
  }

  /// 指定された面のボーナス値を取得
  int getBonus(int faceNumber) {
    return dice.getBonus(faceNumber);
  }

  /// 次の面数値を取得
  int getNextFaces() {
    return dice.faceCount.getNext().value;
  }
}