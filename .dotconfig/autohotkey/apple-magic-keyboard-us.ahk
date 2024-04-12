#Requires AutoHotkey v2.0

; -----------------------------------------------------------
; # 前提条件
; 本設定は、以下の環境で動かすことを前提にしています
; - Apple Magic Keyboard (US) を利用
; - OSのキーボード設定をUSに切り替え済み
; - PowerToy.Keyboard Managerで以下の置き換えを実施済み
;      左Win (=左Cmd)  → 左Ctrl  
;      右Win (=右Cmd)  → 右Ctrl  
;      左Ctrl(=左Ctrl) → 左Win
;      F13(=Capslock)  → 右Win
;
; すべての動作をAutoHotKeyだけで行うこともできそうではあったものの
; スクリプトが極めて煩雑になったため、
; PowerToysと併用してシンプルさを保つ設計にしています
; 
; 以降のセクションのコメントは、前提条件を満たしている場合に
; Apple Magic Keyboardの
; どのキーを押すと、どのような挙動になるかを記述しています
; -----------------------------------------------------------

; -----------------------------------------------------------
; IME切り替え
; Cmdキーを単独で押して離した場合、変換/無変換キーとして扱う
; -----------------------------------------------------------

; NOTE: LCtrl/RCtrl up に設定している理由
; 
; PowerToysでWinキーをCtrlキーに割り当てている場合、
; LCtrlとRCtrlに設定したホットキーが原因不明で起動しなかった
; 解決策として、Ctrl::{return} のようなCtrlへの割り当てを合わせて行うと
; なぜか起動するようになったが理由が全く分からなかった
; 
; また、同様に RWinに対してなにかしらの割り当てを行うと
; RCtrlのホットキー設定が動作しなくなる現象も発生した
; 
; upに設定した場合、これらの挙動が発生しなかったため、
; upへの割り当てを採用した

LCtrl up::{
    if (A_PriorKey == "LControl"){
        SendInput "{vk1D}"
    }
}

RCtrl up::{
    if (A_PriorKey == "RControl"){
        SendInput "{vk1C}"
    }
}

; -----------------------------------------------------------
; macOS風キーバインド
; Caps lockとの組み合わせで起動
; -----------------------------------------------------------

; NOTE: AutoHotKeyのドキュメントを読むと
; ~付加時は、元のキーの操作を残すと書かれていたが、
; なぜか逆の挙動で、~がないとWindowsメニューが開かれてしまったため
; ~を付与している

; 単体入力時にWinキーとして動作させない(ダミーキーを送信)
~RWin::SendInput "{Blind}{vkE8}"

; 矢印キー
RWin & f::SendInput "{Blind}{RWin up}{Right}"
RWin & p::SendInput "{Blind}{RWin up}{Up}"
RWin & n::SendInput "{Blind}{RWin up}{Down}"
RWin & b::SendInput "{Blind}{RWin up}{Left}"

; カーソル移動
RWin & a::SendInput "{Blind}{RWin up}{HOME}"
RWin & e::SendInput "{Blind}{RWin up}{END}"

; 削除
RWin & d::SendInput "{Blind}{RWin up}{Del}"
RWin & h::SendInput "{Blind}{RWin up}{BS}"
RWin & k::SendInput "{Blind}{RWin up}+{End}{Del}" ; カーソルの右側を削除
RWin & w::SendInput "{Blind}{RWin up}^+{Left}{Del}" ; 単語単位で削除

; 単語単位のカーソル操作
!Left::SendInput "^{Left}"
!Right::SendInput "^{Right}"
+!Left::SendInput "^+{Left}"
+!Right::SendInput "^+{Right}"
