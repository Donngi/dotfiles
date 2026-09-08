# macOS の手動設定

システム設定の GUI で手動で行う必要がある項目のチェックリスト。

## このファイルの位置づけ

macOS の設定は、安全にスクリプト化できるものと、そうでないものがある。

- **スクリプト化できるもの**は同じディレクトリの `init_macOS.sh` にある。キーが名前付きで意味が読め、値が単一のスカラーで、書き損じても影響がその設定 1 個に閉じるもの。
- **このファイルに書くもの**は、キーが番号で値が位置依存の配列だったり、書き損じると同じドメインの他の設定を巻き込んだり、複数ドメインに同じ値をミラーしないと反映されなかったりするもの。`defaults write` で書けなくはないが、割に合わない。

新しい Mac をセットアップしたら、`make mac-os-init-all` を実行したうえで、以下を手で設定する。

## キーボード

- [ ] **音声入力のショートカットを `option + ,` にする**
      `システム設定 > キーボード > 音声入力 > ショートカット > カスタマイズ…` を開き、`option + ,` を押して記録する。
      既定の「fn を 2 回押す」と同じ設定エントリを共有しているため、これを設定すると fn 二度押しでの起動は無くなる。

- [ ] **入力ソースを ABC と 日本語(ローマ字入力) の 2 つにする**
      `システム設定 > キーボード > 入力ソース > 編集` から追加する。
      入力ソースの設定は辞書の配列で、書き損じると日本語入力そのものが消えるためスクリプト化しない。

## キーボードショートカット

`システム設定 > キーボード > キーボードショートカット` を開く。
これらは `com.apple.symbolichotkeys` の番号キーに `(文字の ASCII, キーコード, 修飾キーマスク)` という配列で入っており、書き間違えるとホットキー定義をまとめて壊すためスクリプト化しない。

- [ ] **入力ソース > 「前の入力ソースを選択」「入力メニューの次のソースを選択」をオフ**
      IME 切り替えは Karabiner のコマンドキー単押し (`.dotconfig/karabiner/_karabiner.json`) に一本化しているため。

- [ ] **Spotlight > 「Spotlight検索を表示」をオフ**
      `cmd + space` を Alfred に譲るため。

## トラックパッドとアクセシビリティ

- [ ] **3 本指のドラッグを有効にする**
      `システム設定 > アクセシビリティ > ポインタコントロール > トラックパッドオプション` を開き、
      「ドラッグにトラックパッドを使用」をオンにして、ドラッグスタイルを「3 本指のドラッグ」にする。
      内蔵トラックパッドと Magic Trackpad で別ドメインに同じ値を書く必要があるためスクリプト化しない。
      これを有効にすると、3 本指スワイプ (Mission Control / アプリケーション間の移動) は自動的にオフになる。

## 設定できたかの確認

```bash
# 音声入力のショートカット
# parameters が (44, 43, 524288) = (',' の ASCII, キーコード, option) なら設定済み
/usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:162" ~/Library/Preferences/com.apple.symbolichotkeys.plist

# 入力ソース切り替え (60, 61) と Spotlight (64) のショートカット
# enabled が false なら設定済み
for id in 60 61 64; do
  /usr/libexec/PlistBuddy -c "Print :AppleSymbolicHotKeys:$id:enabled" ~/Library/Preferences/com.apple.symbolichotkeys.plist
done

# 3 本指のドラッグ (1 なら有効)
defaults read com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag

# 入力ソース
defaults read com.apple.HIToolbox AppleEnabledInputSources
```

## 運用

このリストは、ある時点の Mac の実際の設定を調べて起こしたもの。取りこぼしがありうる。
今後 GUI で設定を変えたら、スクリプト化できるなら `init_macOS.sh` に、できないならここに追記すること。
