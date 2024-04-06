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
; - Caps lockがF13として認識されている
;   (デフォルトでこの挙動だが、認識していない場合は置き換える)
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

