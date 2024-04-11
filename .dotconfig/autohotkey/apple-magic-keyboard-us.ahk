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
; Cmdキーを短く押した場合、変換/無変換キーとして扱う
; -----------------------------------------------------------

global shortPressBoarder := 500 ;sec
global leftCtrlDownTime := 0
global rightCtrlDownTime := 0

LCtrl::start_time_recorder("LCtrl")
LCtrl up::send_key_if_short_press("LCtrl")

RCtrl::start_time_recorder("RCtrl")
RCtrl up::send_key_if_short_press("RCtrl")

Ctrl::Return ; NOTE: 原因不明だが、Ctrlに対してなにか割り当てられていないと上記の割り当てが動作しない

start_time_recorder(key){
    ; global変数を関数内で呼び出す際は、再定義が必要
    global leftCtrlDownTime
    global rightCtrlDownTime

    if (key == "LCtrl"){
        leftCtrlDownTime := A_TickCount
    } else if (key == "RCtrl") {
        rightCtrlDownTime := A_TickCount
    } else {
        ; TODO error
    }
}

send_key_if_short_press(key){
    ; global変数を関数内で呼び出す際は、再定義が必要
    global leftCtrlDownTime
    global rightCtrlDownTime
    global shortPressBoarder

    if (key == "LCtrl"){
        duration := A_TickCount - leftCtrlDownTime
        if (duration <= shortPressBoarder) {
            SendInput "{vk1D}"
        }
    } else if (key == "RCtrl") {
        duration := A_TickCount - rightCtrlDownTime
        if (duration <= shortPressBoarder) {
            SendInput "{vk1C}"
        }
    } else {
        ; TODO error
    }
}

; -----------------------------------------------------------
; macOS風キーバインド
; Caps lockとの組み合わせで起動
; -----------------------------------------------------------

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