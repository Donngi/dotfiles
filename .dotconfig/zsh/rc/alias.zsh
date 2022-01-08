# ------------------------------------------------------------------------
# Git
# ------------------------------------------------------------------------

alias gs='git status'
alias gc='git commit'
alias gcm='git commit -m'
alias gcam='git commit -am '
alias gga='git graphall'
alias gaa='git add -A'
alias gd='git diff'
alias gf='git fetch -p --all'

# ------------------------------------------------------------------------
# AWS
# ------------------------------------------------------------------------

# AWSを含む環境変数をすべてunset
alias raws='unset $(export | grep AWS | egrep -o "^[^=]+")'

# pipeline-lens
function pipeline-lens-with-peco(){
    PIPELINE_NAME=`aws codepipeline list-pipelines --query "pipelines[*].[name]" --output text | peco`
    if [ -n "$PIPELINE_NAME" ]; then
        pipeline-lens --name ${PIPELINE_NAME}
    fi
}
alias pl=pipeline-lens-with-peco

function pipeline-lens-with-peco-run(){
    PIPELINE_NAME=`aws codepipeline list-pipelines --query "pipelines[*].[name]" --output text | peco`
    if [ -n "$PIPELINE_NAME" ]; then
        pipeline-lens --name ${PIPELINE_NAME} --run
    fi
}
alias plr=pipeline-lens-with-peco-run

# ------------------------------------------------------------------------
# Terraform
# ------------------------------------------------------------------------

alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfaauto='terraform apply --auto-approve'
alias tff='terraform fmt --recursive'

# ------------------------------------------------------------------------
# zsh
# ------------------------------------------------------------------------

# 起動速度測定
alias timezsh='time zsh -i -c exit'

# .zshxx再読み込み
alias reloadzsh="source $ZDOTDIR/.zshenv && source $ZDOTDIR/.zprofile && source $ZDOTDIR/.zshrc"

# ------------------------------------------------------------------------
# tree
# ------------------------------------------------------------------------

# .git を無視
alias tg='tree -a -I ".git"'


# ------------------------------------------------------------------------
# ls
# ------------------------------------------------------------------------

alias ls="ls -G"
alias ll="ls -lhG"
alias la="ls -lahG"

# ------------------------------------------------------------------------
# cd
# ------------------------------------------------------------------------

alias ..='cd ..'
alias ..2='cd ../..'
alias ..3='cd ../../..'

# ------------------------------------------------------------------------
# other
# ------------------------------------------------------------------------

alias openrepo='open "https://github.com/Jimon-s?tab=repositories"'
