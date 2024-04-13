#Requires AutoHotkey v2.0

; -----------------------------------------------------------
; # 前提条件
; 本設定は、以下の環境で動かすことを前提にしています
; - Apple Magic Keyboard (US) を利用
;
; 以降のセクションのコメントは、前提条件を満たしている場合に
; Apple Magic Keyboardの
; どのキーを押すと、どのような挙動になるかを記述しています
; -----------------------------------------------------------

; -----------------------------------------------------------
; Ctrl/Winキーの割り当て
; - CmdキーをCtrlキーに割り当て
; - CtrlキーをWinキーに割り当て
; 
; IME切り替え
; - Cmdキーを単独で押して離した場合、変換/無変換キーとして扱う
; -----------------------------------------------------------

; NOTE:
; シンプルに *LWin::LCtrl のようなリマップを行うと
; 同一設定でも、ボタン押下のタイミングによって
; 挙動が異なる事象が発生した
; 
; 具体的には、
; 置き換え元のWinキーが押されたままになってしまい
; LWin+Aで、LCtrl+Aを入力したつもりが
; LWin+LCtrl+Aになる事象が、トリガー不明で定期的に発生した
; 
; この問題を解決するため、明示的にSendInputを利用する実装としている
*LWin::{
    SendInput("{Blind}{LCtrl down}")
}    
*LWin up::{
    SendInput("{Blind}{LCtrl up}")
    if (A_PriorKey == "LWin"){ ; upイベントの中では、この条件で単体押しを検知できる
        SendInput("{vk1D}")
    }
}

*RWin::{
    SendInput("{Blind}{RCtrl down}")
}    
*RWin up::{
    SendInput("{Blind}{RCtrl up}")
    if (A_PriorKey == "RWin"){ ; upイベントの中では、この条件で単体押しを検知できる
        SendInput("{vk1C}")
    }
}

*LCtrl::SendInput("{Blind}{LWin down}")
*LCtrl up::SendInput("{Blind}{LWin up}")

; -----------------------------------------------------------
; macOS Ctrlキーショートカット風キーバインド
; Capslock + 各種キーで起動
; -----------------------------------------------------------

; NOTE: Apple Magic Keyboard US配列のCapslockは
; デフォルトでF13として認識されている

; 矢印キー
F13 & f::SendInput "{Right}"
F13 & p::SendInput "{Up}"
F13 & n::SendInput "{Down}"
F13 & b::SendInput "{Left}"

; 行頭/行末移動
F13 & a::SendInput "{HOME}"
F13 & e::SendInput "{END}"

; 削除
F13 & d::SendInput "{Del}"
F13 & h::SendInput "{BS}"
F13 & k::SendInput "+{End}{Del}" ; カーソルの右側を削除
F13 & w::SendInput "^+{Left}{Del}" ; 単語単位で削除

; -----------------------------------------------------------
; macOS 単語移動操作風キーバインド
; Option+左右 の挙動を再現
; -----------------------------------------------------------

; 単語単位のカーソル操作
!Left::SendInput "^{Left}"
!Right::SendInput "^{Right}"
+!Left::SendInput "^+{Left}"
+!Right::SendInput "^+{Right}"
