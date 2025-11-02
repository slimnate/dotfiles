# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

. "$HOME/.local/share/../bin/env"

# eval $(ssh-agent -s)
# ssh-add ~/.ssh/id_ed25519

# SSH agent - source: https://gist.github.com/darrenpmeyer/e7ad217d929f87a7b7052b3282d1b24c#details
ssh_pid_file="$HOME/.config/ssh-agent.pid"
SSH_AUTH_SOCK="$HOME/.config/ssh-agent.sock"
if [ -z "$SSH_AGENT_PID" ]
then
	# no PID exported, try to get it from pidfile
	SSH_AGENT_PID=$(cat "$ssh_pid_file")
fi

if ! kill -0 $SSH_AGENT_PID &> /dev/null
then
	# the agent is not running, start it
	rm "$SSH_AUTH_SOCK" &> /dev/null
	>&2 echo "Starting SSH agent, since it's not running; this can take a moment"
	eval "$(ssh-agent -s -a "$SSH_AUTH_SOCK")"
	echo "$SSH_AGENT_PID" > "$ssh_pid_file"
	ssh-add -A 2>/dev/null

	>&2 echo "Started ssh-agent with '$SSH_AUTH_SOCK'"
else
	>&2 echo "ssh-agent on '$SSH_AUTH_SOCK' ($SSH_AGENT_PID)"
fi
export SSH_AGENT_PID
export SSH_AUTH_SOCK