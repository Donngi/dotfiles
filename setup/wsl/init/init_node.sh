# Install volta
# https://docs.volta.sh/guide/getting-started
curl https://get.volta.sh | bash

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

volta install node
node -v
