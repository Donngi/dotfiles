# ------------------------------------------------------------------------
# Git
# ------------------------------------------------------------------------

alias gs='git status'
alias gg='git graphall'

# ------------------------------------------------------------------------
# AWS
# ------------------------------------------------------------------------

# AWSを含む環境変数をすべてunset
alias raws='unset $(export | grep AWS | egrep -o "^[^=]+")'

# ------------------------------------------------------------------------
# Terraform
# ------------------------------------------------------------------------

alias tf='terraform'
