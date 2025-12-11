import 'dart:math';
import 'package:flutter/material.dart';
import 'face_count.dart';
import 'dice.dart';

void main() {
  runApp(const MyApp());
}

/// シンプルなアプリ。StatefulWidget で Dice の状態を管理する。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dice App',
      theme: ThemeData.from(
        colorScheme: const ColorScheme.light(),
      ),
      home: const DicePage(),
    );
  }
}

/// 画面中央にサイコロ（四角＋数字）を表示する StatefulWidget。
/// タップ時に高速で数字を切り替える演出を行い、最後に確定値を表示する。
/// ボタンで面数を切り替え可能。
/// 強化ボタンで各面にボーナス値を追加可能。
class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  // 許可されている面数の一覧
  static const List<int> allowedFaces = [6, 8, 10, 12, 14, 16, 20];

  // 現在の面数インデックス。初期は 6 面（インデックス 0）
  int _faceIndex = 0;

  // サイコロインスタンス
  late Dice _dice;

  // 各面番号ごとの強化値を保持するマップ。面数変更後も値を引き継ぐ。
  // キー: 面番号（1～20）、値: ボーナス値
  final Map<int, int> _bonusHistory = {};

  // 表示用の一時的な値。initState で初期化するが、念のため nullable にして
  // ビルド時には _dice.current.value をフォールバックとして使う（LateError 回避）。
  int? _displayValue;

  // アニメーション中は連続タップを抑止するフラグ
  bool _isRolling = false;

  // ランダム生成に使用（アニメーション中の表示切替で利用）
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeDice();
  }

  /// サイコロを初期化する。強化値履歴から該当する面のボーナスを復元する。
  void _initializeDice() {
    _dice = Dice(FaceCount(allowedFaces[_faceIndex]));

    // 現在の面数に対応する面の強化値を履歴から復元
    for (int faceNumber = 1; faceNumber <= allowedFaces[_faceIndex]; faceNumber++) {
      final bonus = _bonusHistory[faceNumber] ?? 0;
      if (bonus > 0) {
        _dice.addBonus(faceNumber, bonus);
      }
    }

    _displayValue = _dice.current.effectiveValue;
  }

  /// 面数を増やす。リスト最後に達したら最初に戻る。最大面数（20）に達したら増やさない。
  void _increaseFaces() {
    // 最大面数に達していれば何もしない
    if (_faceIndex >= allowedFaces.length - 1) {
      return;
    }

    setState(() {
      _faceIndex = (_faceIndex + 1) % allowedFaces.length;
      _initializeDice();
      _displayValue = null; // 表示値もリセット
    });
  }

  /// 面数変更の確認ダイアログを表示する。
  Future<void> _showFaceChangeDialog() async {
    // 最大面数に達していれば変更不可
    if (_faceIndex >= allowedFaces.length - 1) {
      return;
    }

    final nextFaces = allowedFaces[(_faceIndex + 1) % allowedFaces.length];

    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('面数を変更しますか？'),
          content: Text('$nextFaces 面ダイスに変更します。\n現在の強化値は引き継がれます。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('変更する'),
            ),
          ],
        );
      },
    );

    if (shouldChange ?? false) {
      _increaseFaces();
    }
  }

  /// 指定された面番号の強化ボーナス値を入力するダイアログを表示する。
  Future<void> _showBonusDialog(int faceNumber) async {
    int selectedBonus = 1;

    try {
      final bonusAmount = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text('面$faceNumber の強化値を選択'),
                content: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('+1')),
                    ButtonSegment(value: 2, label: Text('+2')),
                    ButtonSegment(value: 3, label: Text('+3')),
                  ],
                  selected: {selectedBonus},
                  onSelectionChanged: (Set<int> newSelection) {
                    setDialogState(() => selectedBonus = newSelection.first);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, selectedBonus),
                    child: const Text('決定'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (bonusAmount != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _dice.addBonus(faceNumber, bonusAmount);
            // 強化値の履歴に記録（面数変更後も引き継ぐため）
            _bonusHistory[faceNumber] = (_bonusHistory[faceNumber] ?? 0) + bonusAmount;
          });
        }
      }
    } catch (e) {
      // エラーハンドリング
    }
  }

  // サイコロをタップしたときの処理。アニメーションを行い、最後に dice.roll() で確定する。
  Future<void> _onTap() async {
    if (_isRolling) return;
    _isRolling = true;

    // アニメーションのフレーム数と1フレームの遅延（高速に切り替える）
    const int frames = 12;
    const Duration frameDelay = Duration(milliseconds: 40);

    // フレームごとにランダムな面を表示して「振っている」演出にする。
    for (int i = 0; i < frames; i++) {
      setState(() {
        _displayValue =
            _dice.faces[_random.nextInt(_dice.faces.length)].effectiveValue;
      });
      await Future.delayed(frameDelay);
    }

    // 最終的に dice.roll() を呼んで current を更新し、表示を確定する。
    final result = _dice.roll();
    setState(() {
      _displayValue = result;
    });

    // 短い余韻（任意）。不要ならコメントアウト可。
    await Future.delayed(const Duration(milliseconds: 80));

    _isRolling = false;
  }

  @override
  Widget build(BuildContext context) {
    final size = 160.0;
    final currentFaces = allowedFaces[_faceIndex];
    final isMaxFaces = _faceIndex >= allowedFaces.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('サイコロ'),
      ),
      body: Column(
        children: [
          // 上部：面数表示
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '$currentFaces 面ダイス',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          // 中央：サイコロ本体
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _onTap,
                // 四角形でサイコロを表現。中央に大きく出目を表示。
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 155, 69, 69),
                    border: Border.all(color: Colors.black87, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      )
                    ],
                  ),
                  child: Text(
                    '${_displayValue ?? _dice.current.effectiveValue}',
                    semanticsLabel: '現在の出目',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 強化ボタン群
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 4,
              children: List.generate(
                currentFaces,
                (index) {
                  final faceNumber = index + 1;
                  final bonus = _dice.getBonus(faceNumber);
                  return ElevatedButton(
                    key: ValueKey('bonus_button_$faceNumber'),
                    onPressed: () => _showBonusDialog(faceNumber),
                    child: Text(
                      bonus > 0 ? '[$faceNumber]+$bonus' : '[$faceNumber]',
                    ),
                  );
                },
              ),
            ),
          ),
          // 下部：面数変更ボタン（最大面数に達したら非活性）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: isMaxFaces ? null : _showFaceChangeDialog,
              child: Text(
                isMaxFaces
                    ? '最大面数に到達しました'
                    : '面数を変更 → ${allowedFaces[(_faceIndex + 1) % allowedFaces.length]}面',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
