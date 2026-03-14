# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# add ~/.local/bin to the PATH
PATH="$HOME/.local/bin:$PATH"

# Source the environment variables
ENV_FILE="$HOME/.local/bin/env"
if [ -f "$ENV_FILE" ]; then
  . "$ENV_FILE"
fi

# Source the SSH agent
source "$HOME/.config/bash/ssh-agent.sh"

# Source the Starship prompt
eval "$(starship init bash)"
