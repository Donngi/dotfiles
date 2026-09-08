#!/bin/bash

# NOTE: グローバルドメイン (-g) と HIToolbox の変更は再ログインまで反映されない
# NOTE: GUI で手動設定が必要なものは manual_settings.md にまとめている

# 外観をダークモードに
defaults write -g AppleInterfaceStyle -string Dark

# トラックパッドの速度
defaults write -g com.apple.mouse.scaling 2.5

# トラックパッドのタップでクリック
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1

# キー長押し時の変換候補ポップアップを無効化 (キーリピートを有効化)
defaults write -g ApplePressAndHoldEnabled -bool false

# キーのリピート速度と、リピート入力認識までの時間
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 25

# Tab キーですべてのコントロールにフォーカスを移動できるように
defaults write -g AppleKeyboardUIMode -int 2

# fn / 🌐 キー単押しで何も起こさない
defaults write com.apple.HIToolbox AppleFnUsageType -int 0

# Dock を自動的に表示/非表示
defaults write com.apple.dock autohide -bool true

# Dock のサイズ
defaults write com.apple.dock tilesize -integer 37
killall Dock
