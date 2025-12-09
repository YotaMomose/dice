/// サイコロの面数を表す不変クラス。
/// 許可される面数は 6, 8, 10, 12, 14, 16, 20 のみ。
class FaceCount {
  /// 許可される面数の集合
  static const Set<int> allowed = {6, 8, 10, 12, 14, 16, 20};

  /// 面数（不変）
  final int value;

  /// コンストラクタ。許可されていない値なら ArgumentError を投げる。
  FaceCount(this.value) {
    if (!allowed.contains(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'FaceCount must be one of $allowed',
      );
    }
  }

  @override
  String toString() => 'FaceCount($value)';
}