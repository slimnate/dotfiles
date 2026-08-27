# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# /etc/omarchy.conf is written by omarchy-dev-link. When absent, force the
# package default instead of preserving a stale inherited dev-link value before
# we decide which rc file to source.
if [[ -f /etc/omarchy.conf ]]; then
  source /etc/omarchy.conf
  export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
else
  export OMARCHY_PATH=/usr/share/omarchy
fi
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# add ~/.local/bin to the PATH
PATH="$HOME/.local/bin:$PATH"

# Source the environment variables
. "$HOME/.local/share/../bin/env"

# Source the SSH agent
source "$HOME/.config/bash/ssh-agent.sh"

# Source the Starship prompt
eval "$(starship init bash)"

# OpenClaw Completion
source "/home/slim/.openclaw/completions/openclaw.bash"
