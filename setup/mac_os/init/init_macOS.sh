#!/bin/bash

# トラックパッドの速度
defaults write -g com.apple.mouse.scaling 2.5

# キー長押し時の変換候補ポップアップを無効化 (キーリピートを有効化)
defaults write -g ApplePressAndHoldEnabled -bool false

# Dock のサイズ
defaults write com.apple.dock tilesize -integer 37
killall Dock
