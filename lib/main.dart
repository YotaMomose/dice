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

/// 画面を上下で分割し、各プレイヤーが独立したサイコロを操作できるWidget
class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  // 許可されている面数の一覧
  static const List<int> allowedFaces = [6, 8, 10, 12, 14, 16, 20];

  // プレイヤー1の状態
  late int _player1FaceIndex;
  late Dice _player1Dice;
  final Map<int, int> _player1BonusHistory = {};
  int? _player1DisplayValue;
  bool _player1IsRolling = false;
  final Random _player1Random = Random();

  // プレイヤー2の状態
  late int _player2FaceIndex;
  late Dice _player2Dice;
  final Map<int, int> _player2BonusHistory = {};
  int? _player2DisplayValue;
  bool _player2IsRolling = false;
  final Random _player2Random = Random();

  @override
  void initState() {
    super.initState();
    _player1FaceIndex = 0;
    _player2FaceIndex = 0;
    _initializeBothDice();
  }

  /// 両プレイヤーのサイコロを初期化
  void _initializeBothDice() {
    _initializePlayerDice(1);
    _initializePlayerDice(2);
  }

  /// 指定されたプレイヤーのサイコロを初期化。強化値履歴から復元する。
  void _initializePlayerDice(int playerNumber) {
    if (playerNumber == 1) {
      _player1Dice = Dice(FaceCount(allowedFaces[_player1FaceIndex]));
      for (int faceNumber = 1; faceNumber <= allowedFaces[_player1FaceIndex]; faceNumber++) {
        final bonus = _player1BonusHistory[faceNumber] ?? 0;
        if (bonus > 0) {
          _player1Dice.addBonus(faceNumber, bonus);
        }
      }
      _player1DisplayValue = _player1Dice.current.effectiveValue;
    } else {
      _player2Dice = Dice(FaceCount(allowedFaces[_player2FaceIndex]));
      for (int faceNumber = 1; faceNumber <= allowedFaces[_player2FaceIndex]; faceNumber++) {
        final bonus = _player2BonusHistory[faceNumber] ?? 0;
        if (bonus > 0) {
          _player2Dice.addBonus(faceNumber, bonus);
        }
      }
      _player2DisplayValue = _player2Dice.current.effectiveValue;
    }
  }

  /// 指定されたプレイヤーの面数を増やす
  void _increasePlayerFaces(int playerNumber) {
    if (playerNumber == 1) {
      if (_player1FaceIndex >= allowedFaces.length - 1) {
        return;
      }
      setState(() {
        _player1FaceIndex = (_player1FaceIndex + 1) % allowedFaces.length;
        _initializePlayerDice(1);
        _player1DisplayValue = null;
      });
    } else {
      if (_player2FaceIndex >= allowedFaces.length - 1) {
        return;
      }
      setState(() {
        _player2FaceIndex = (_player2FaceIndex + 1) % allowedFaces.length;
        _initializePlayerDice(2);
        _player2DisplayValue = null;
      });
    }
  }

  /// 面数変更の確認ダイアログを表示する
  Future<void> _showFaceChangeDialog(int playerNumber) async {
    final faceIndex = playerNumber == 1 ? _player1FaceIndex : _player2FaceIndex;
    final maxFaces = faceIndex >= allowedFaces.length - 1;

    if (maxFaces) {
      return;
    }

    final nextFaces = allowedFaces[(faceIndex + 1) % allowedFaces.length];

    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final dialog = AlertDialog(
          title: Text('プレイヤー$playerNumber: 面数を変更しますか？'),
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

        // プレイヤー1のダイアログは逆さまにする
        if (playerNumber == 1) {
          return Transform.rotate(
            angle: 3.14159,
            child: dialog,
          );
        }

        return dialog;
      },
    );

    if (shouldChange ?? false) {
      _increasePlayerFaces(playerNumber);
    }
  }

  /// 強化ボーナス値を入力するダイアログを表示する
  Future<void> _showBonusDialog(int playerNumber, int faceNumber) async {
    int selectedBonus = 1;

    try {
      final bonusAmount = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final dialog = AlertDialog(
                title: Text('プレイヤー$playerNumber: 面$faceNumber の強化値を選択'),
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

              // プレイヤー1のダイアログは逆さまにする
              if (playerNumber == 1) {
                return Transform.rotate(
                  angle: 3.14159,
                  child: dialog,
                );
              }

              return dialog;
            },
          );
        },
      );

      if (bonusAmount != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            if (playerNumber == 1) {
              _player1Dice.addBonus(faceNumber, bonusAmount);
              _player1BonusHistory[faceNumber] = (_player1BonusHistory[faceNumber] ?? 0) + bonusAmount;
            } else {
              _player2Dice.addBonus(faceNumber, bonusAmount);
              _player2BonusHistory[faceNumber] = (_player2BonusHistory[faceNumber] ?? 0) + bonusAmount;
            }
          });
        }
      }
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// サイコロを振る
  Future<void> _rollDice(int playerNumber) async {
    if (playerNumber == 1 && _player1IsRolling) return;
    if (playerNumber == 2 && _player2IsRolling) return;

    if (playerNumber == 1) {
      _player1IsRolling = true;
    } else {
      _player2IsRolling = true;
    }

    const int frames = 12;
    const Duration frameDelay = Duration(milliseconds: 40);

    // アニメーション
    for (int i = 0; i < frames; i++) {
      setState(() {
        if (playerNumber == 1) {
          _player1DisplayValue =
              _player1Dice.faces[_player1Random.nextInt(_player1Dice.faces.length)].effectiveValue;
        } else {
          _player2DisplayValue =
              _player2Dice.faces[_player2Random.nextInt(_player2Dice.faces.length)].effectiveValue;
        }
      });
      await Future.delayed(frameDelay);
    }

    // 確定
    setState(() {
      if (playerNumber == 1) {
        _player1DisplayValue = _player1Dice.roll();
      } else {
        _player2DisplayValue = _player2Dice.roll();
      }
    });

    await Future.delayed(const Duration(milliseconds: 80));

    if (playerNumber == 1) {
      _player1IsRolling = false;
    } else {
      _player2IsRolling = false;
    }
  }

  /// プレイヤーのサイコロUIを構築
  Widget _buildPlayerDiceUI(int playerNumber, {bool isReversed = false}) {
    final faceIndex = playerNumber == 1 ? _player1FaceIndex : _player2FaceIndex;
    final displayValue = playerNumber == 1 ? _player1DisplayValue : _player2DisplayValue;
    final dice = playerNumber == 1 ? _player1Dice : _player2Dice;
    final currentFaces = allowedFaces[faceIndex];
    final isMaxFaces = faceIndex >= allowedFaces.length - 1;
    final size = 140.0;

    final column = Column(
      children: [
        // 面数表示
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '$currentFaces 面ダイス',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        // サイコロ本体
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => _rollDice(playerNumber),
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
                  '${displayValue ?? dice.current.effectiveValue}',
                  style: TextStyle(
                    fontSize: 44,
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Wrap(
            spacing: 3,
            children: List.generate(
              currentFaces,
              (index) {
                final faceNumber = index + 1;
                final bonus = playerNumber == 1
                    ? _player1Dice.getBonus(faceNumber)
                    : _player2Dice.getBonus(faceNumber);
                return ElevatedButton(
                  key: ValueKey('player${playerNumber}_bonus_button_$faceNumber'),
                  onPressed: () => _showBonusDialog(playerNumber, faceNumber),
                  child: Text(
                    bonus > 0 ? '[$faceNumber]+$bonus' : '[$faceNumber]',
                  ),
                );
              },
            ),
          ),
        ),
        // 面数変更ボタン
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ElevatedButton(
            onPressed: isMaxFaces ? null : () => _showFaceChangeDialog(playerNumber),
            child: Text(
              isMaxFaces
                  ? '最大面数'
                  : '→ ${allowedFaces[(faceIndex + 1) % allowedFaces.length]}面',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );

    // 上下反転が必要な場合
    if (isReversed) {
      return Transform.rotate(
        angle: 3.14159, // 180度回転
        child: column,
      );
    }

    return column;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0), // 上部に40pxのパディングを追加
        child: Column(
          children: [
            // プレイヤー1（上）
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: _buildPlayerDiceUI(1, isReversed: true),
              ),
            ),
            // 中央の区切り線
            Container(
              height: 2,
              color: Colors.black54,
            ),
            // プレイヤー2（下・反転）
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: _buildPlayerDiceUI(2, isReversed: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
