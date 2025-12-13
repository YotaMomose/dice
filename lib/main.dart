import 'package:flutter/material.dart';
import 'player.dart';

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
  // プレイヤーのインスタンス
  late Player _player1;
  late Player _player2;

  @override
  void initState() {
    super.initState();
    _player1 = Player(1); // 上部プレイヤー
    _player2 = Player(2); // 下部プレイヤー
  }

  /// 指定されたプレイヤーの面数を増やす
  void _increasePlayerFaces(Player player) {
    setState(() {
      player.increaseFaces();
    });
  }

  /// 面数変更の確認ダイアログを表示する
  Future<void> _showFaceChangeDialog(Player player) async {
    if (player.isMaxFaces) {
      return;
    }

    final nextFaces = player.getNextFaces();

    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final dialog = AlertDialog(
          title: Text('プレイヤー${player.id}: 面数を変更しますか？'),
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
        if (player.id == 1) {
          return Transform.rotate(
            angle: 3.14159,
            child: dialog,
          );
        }

        return dialog;
      },
    );

    if (shouldChange ?? false) {
      _increasePlayerFaces(player);
    }
  }

  /// 強化ボーナス値を入力するダイアログを表示する
  Future<void> _showBonusDialog(Player player, int faceNumber) async {
    int selectedBonus = 1;

    try {
      final bonusAmount = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final dialog = AlertDialog(
                title: Text('プレイヤー${player.id}: 面$faceNumber の強化値を選択'),
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
              if (player.id == 1) {
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
            player.addBonus(faceNumber, bonusAmount);
          });
        }
      }
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// サイコロを振る
  Future<void> _rollDice(Player player) async {
    if (player.isRolling) return;
    player.isRolling = true;

    const int frames = 12;
    const Duration frameDelay = Duration(milliseconds: 40);

    // アニメーション
    for (int i = 0; i < frames; i++) {
      setState(() {
        player.displayValue =
            player.dice.faces[player.random.nextInt(player.dice.faces.length)].effectiveValue;
      });
      await Future.delayed(frameDelay);
    }

    // 確定
    setState(() {
      player.roll();
    });

    await Future.delayed(const Duration(milliseconds: 80));

    player.isRolling = false;
  }

  /// プレイヤーのサイコロUIを構築
  Widget _buildPlayerDiceUI(Player player, {bool isReversed = false}) {
    final size = 140.0;

    final column = Column(
      children: [
        // 面数表示
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '${player.currentFaces} 面ダイス',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        // サイコロ本体
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: () => _rollDice(player),
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
                  '${player.displayValue ?? player.dice.current.effectiveValue}',
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
              player.currentFaces,
              (index) {
                final faceNumber = index + 1;
                final bonus = player.getBonus(faceNumber);
                return ElevatedButton(
                  key: ValueKey('player${player.id}_bonus_button_$faceNumber'),
                  onPressed: () => _showBonusDialog(player, faceNumber),
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
            onPressed: player.isMaxFaces ? null : () => _showFaceChangeDialog(player),
            child: Text(
              player.isMaxFaces
                  ? '最大面数'
                  : '→ ${player.getNextFaces()}面',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );

    // 上下反転が必要な場合
    if (isReversed) {
      return Transform.rotate(
        angle: 3.14159,
        child: column,
      );
    }

    return column;
  }

  // メインのビルドメソッド（画面を作っている）
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            // プレイヤー1（上）
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 121, 173, 134),
                child: _buildPlayerDiceUI(_player1, isReversed: true),
              ),
            ),
            // 中央の区切り線
            Container(
              height: 2,
              color: Colors.black54,
            ),
            // プレイヤー2（下）
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 240, 170, 211),
                child: _buildPlayerDiceUI(_player2, isReversed: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
