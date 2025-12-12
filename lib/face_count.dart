/// サイコロの面数を表す不変クラス。
/// 許可される面数は 6, 8, 10, 12, 14, 16, 20 のみ。
class FaceCount {
  /// 許可される面数のリスト（順序が重要）
  static const List<int> allowedList = [6, 8, 10, 12, 14, 16, 20];

  /// 許可される面数の集合
  static const Set<int> allowed = {6, 8, 10, 12, 14, 16, 20};

  /// 面数（不変）
  final int _value;
  /// 面数の値を取得
  int get value => _value;

  /// コンストラクタ。許可されていない値なら ArgumentError を投げる。
  FaceCount(this._value) {
    if (!allowed.contains(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'FaceCount must be one of $allowed',
      );
    }
  }

  /// 次の面数を返す。20面の場合は null を返す（強化不可）。
  FaceCount getNext() {
    final currentIndex = allowedList.indexOf(value);
    
    // 20面（リストの最後）の場合はエラー
    if (currentIndex == allowedList.length - 1) {
      // エラー
      throw StateError('No next FaceCount available for $value');
    }
    
    // 次の面数を返す
    return FaceCount(allowedList[currentIndex + 1]);
  }

  /// 次の面数の値を取得（int型）。20面の場合は null を返す。
  int? getNextValue() {
    final next = getNext();
    return next?.value;
  }

  /// 最大面数に達しているかを判定
  /// 20面の場合に true を返す
  bool get isMax => value == allowedList.last;
  
  @override
  String toString() => 'FaceCount($value)';
}