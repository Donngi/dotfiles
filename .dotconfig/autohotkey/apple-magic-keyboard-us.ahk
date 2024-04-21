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

; -----------------------------------------------------------
; macOS Alfred風
; -----------------------------------------------------------

; macOSで、Option+Spaceに割り当てている検索を
; Windowsの検索で再現
Alt & Space::SendInput("#s")

; macOSで、Cmd+Shift+Vに割り当てている拡張クリップボードを
; Windowsのクリップボードで再現
; 
; NOTE: LWin & v でHotKeyを設定しようとすると、
; 別途設定しているLWinをLCtrlに割り当てるHotKeyが無効化される事象が発生した
; 解決のめどが立たなかったため、暫定Shift+vでハンドルしている
Shift & v::{
    If (GetKeyState("LWin","P")){
        ; リマップの影響でCtrlが押下状態になっているので、明示的に外す
        SendInput("{Blind}{LCtrl Up}{RCtrl Up}")
        SendInput("#v")
    }else{
        SendInput("V")
    }
}

; -----------------------------------------------------------
; VSCode
; Windows版VSCodeが、F13を修飾キーとして受け取れないため
; AutoHotKeyで強制的にリマップする
; どのHotKeyがどのショートカットと結びつくかは、
; VSCodeのkeybindings.jsonを参照すること
; -----------------------------------------------------------

#HotIf WinActive("ahk_exe Code.exe")

    ; デフォルト状態だと、F13単体押下をVSCodeがなぜか認識しないため、
    ; 明示的にF13を送信する
    F13::F13

    ; macOSで独自設定として、ctrl+m, ctrl+jを2段階ショートカットの起動キーとしているため
    ; Windowsでも同様の動作を再現する
    ; AutoHotKeyには、XXXXを押した直後にYYYYを押した を直接検知する方法がないため、
    ; 1回目の押下時にフラグをオンにすることで実現している
    f13AndJPressed := False
    f13AndMPressed := False

    F13 & j::{
        global f13AndJPressed

        if (not f13AndJPressed){ ; フラグON動作を強調したかっため、not条件で記入
            f13AndJPressed := True
        }else{
            ; F13+J -> F13+J
            SendInput("{F13}")
            SendInput("^j")
            f13AndJPressed := False
        }
    }

    F13 & m::{
        global f13AndMPressed

        if (not f13AndJPressed){ ; フラグON動作を強調したかっため、not条件で記入
            f13AndMPressed := True
        }      
    }

    F13 & enter::{
        SendInput("{F13}")
        SendInput("^{Enter}")
    }

    F13 & space::{
        global f13AndMPressed

        if (f13AndMPressed){
            SendInput("{F13}")
            SendInput("+^{Space}")
            f13AndMPressed := False
        }else{
            SendInput("{F13}")
            SendInput("^{Space}")
        }
    }

    F13 & -::{
        SendInput("{F13}")
        If (GetKeyState("Shift","P")){
            SendInput("+^-")
        }else{
            SendInput("^-")
        }
    }

    F13 & Right::{
        If (GetKeyState("LWin", "P") || GetKeyState("RWin", "P")){
            ; Winキーの押下を明示的に外す
            ; リマップの影響のためか、Win UpでなくCtrl upが必要だった
            SendInput("{Blind}{LCtrl Up}{RCtrl Up}")

            SendInput("{F13}")
            SendInput("!+^{Right}")
        }
    }
    
    F13 & Left::{
        If (GetKeyState("LWin","P") || GetKeyState("RWin","P")){
            ; Winキーの押下を明示的に外す
            ; リマップの影響のためか、Win UpでなくCtrl upが必要だった
            SendInput("{Blind}{LCtrl Up}{RCtrl Up}")

            SendInput("{F13}")
            SendInput("!+^{Left}")
        }
    }

    F13 & g::{
        SendInput("{F13}")      
        SendInput("^g")
    }

    tab::{
        ; Ctrl+TTabで直前に開いたファイルを移動するショートカットは
        ; 次のファイルの選択にTab単体でなく、Ctrl+Tabを利用していた
        if (GetKeyState("F13","P")){
            SendInput("{Ctrl Down}{Tab}")
            KeyWait("F13")
            SendInput("{Ctrl Up}")
        }else{
            SendInput("{Tab}")
        }
    }

    F13 & \::{
        If (GetKeyState("Shift","P")){
            SendInput("{F13}")      
            SendInput("+^\")
        }else{
            SendInput("{F13}")      
            SendInput("^\")
        }
    }

    F13 & k::{
        global f13AndJPressed

        if (f13AndJPressed){
            SendInput("{F13}")
            SendInput("^k")
            f13AndJPressed := False
        }else{
            SendInput("{F13}")
            SendInput("!+^k")
        }
    }

#HotIf
