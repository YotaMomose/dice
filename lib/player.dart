import 'dart:math';
import 'face_count.dart';
import 'dice.dart';

/// プレイヤーの状態と操作を管理するクラス。
/// サイコロの面数、強化値、出目などを一元管理する。
class Player {
  /// 許可されている面数の一覧
  static const List<int> allowedFaces = [6, 8, 10, 12, 14, 16, 20];

  /// 現在の面数インデックス
  int faceIndex = 0;

  /// サイコロインスタンス
  late Dice dice;

  /// 各面番号ごとの強化値履歴（面数変更後も引き継ぐため）
  final Map<int, int> bonusHistory = {};

  /// 表示用の出目値（アニメーション中の表示用）
  int? displayValue;

  /// サイコロ振り中のフラグ
  bool isRolling = false;

  /// ランダム生成用
  final Random random = Random();

  /// コンストラクタ。初期状態で6面ダイスを生成。
  Player() {
    _initializeDice();
  }

  /// 現在の面数を取得
  int get currentFaces => allowedFaces[faceIndex];

  /// 最大面数に達しているかを判定
  bool get isMaxFaces => faceIndex >= allowedFaces.length - 1;

  /// サイコロを初期化。強化値履歴から復元。
  void _initializeDice() {
    dice = Dice(FaceCount(allowedFaces[faceIndex]));

    // 強化値履歴から該当する面のボーナスを復元
    for (int faceNumber = 1; faceNumber <= currentFaces; faceNumber++) {
      final bonus = bonusHistory[faceNumber] ?? 0;
      if (bonus > 0) {
        dice.addBonus(faceNumber, bonus);
      }
    }

    displayValue = dice.current.effectiveValue;
  }

  /// 面数を増やす（最大面数なら何もしない）
  void increaseFaces() {
    if (isMaxFaces) {
      return;
    }

    faceIndex = (faceIndex + 1) % allowedFaces.length;
    _initializeDice();
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
    bonusHistory[faceNumber] = (bonusHistory[faceNumber] ?? 0) + bonusAmount;
  }

  /// 指定された面のボーナス値を取得
  int getBonus(int faceNumber) {
    return dice.getBonus(faceNumber);
  }

  /// 次の面数値を取得
  int getNextFaces() {
    return allowedFaces[(faceIndex + 1) % allowedFaces.length];
  }
}