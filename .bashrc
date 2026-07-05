# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$VOLTA_HOME/tools/image/node/22.17.1/bin:$PATH"

# peon-ping quick controls
alias peon="bash /home/hillerstorm/.claude/hooks/peon-ping/peon.sh"
[ -f /home/hillerstorm/.claude/hooks/peon-ping/completions.bash ] && source /home/hillerstorm/.claude/hooks/peon-ping/completions.bash

eval "$(thefuck --alias)"
