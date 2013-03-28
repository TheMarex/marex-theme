# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

HOST_HOME='patrick-desktop'
HOST_LAPTOP='patrick-laptop'
DEFAULT_USER='patrick'

SEGMENT_FORWARD='⮀'
SEGMENT_BACKWARD='⮂'

CARET="⮁"

CURRENT_BG='NONE'

eval black=016
eval white=231

eval darkestgreen=022
eval darkgreen=028
eval mediumgreen=070
eval brightgreen=148

eval darkestcyan=023
eval mediumcyan=117

eval darkestblue=024
eval darkblue=031

eval darkestred=052
eval darkred=088
eval mediumred=124
eval brightred=160
eval brightestred=196

eval darkestpurple=055
eval mediumpurple=098
eval brightpurple=189

eval brightorange=208
eval brightestorange=214

eval gray0=233
eval gray1=235
eval gray2=236
eval gray3=239
eval gray4=240
eval gray5=241
eval gray6=244
eval gray7=245
eval gray8=247
eval gray9=250
eval gray10=252

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="$BG[$1]" || bg="$FX[reset]"
  [[ -n $2 ]] && fg="$FG[$2]" || fg="$FX[reset]"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg$FG[$CURRENT_BG]%}$SEGMENT_FORWARD%{$fg%} "
    echo "$1, $FG[$2]" > /home/patrick/debug_zsh
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

segment_separator() {
  echo -n " ⮁ "
}

# End the prompt, closing any open segments
prompt_end() {
	local fill_bg="$BG[$gray2]"
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{$FX[reset]$FG[$CURRENT_BG]%}$fill_bg$SEGMENT_FORWARD"
  else
    echo -n "%{$FX[reset]%}"
  fi
  echo "%{$fill_bg%f%}%E%{%f%b%k%}"
	echo "$FG[$gray3]$CARET$FX[reset]"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`
  local host=`hostname`
  local background="$gray2"
  if [[ "$user" == "root" ]]; then
    background="$brightred"
  fi

  if [[ "$user" != "$DEFAULT_USER" ]]; then
    if [[ ("$host" == "$HOST_HOME" || "$host" == "$HOST_LAPTOP") && -z "$SSH_CLIENT" ]]; then
      prompt_segment "$background" "$white" "%(!.%{%F{yello}%}.)$user"
    else
      prompt_segment "$background" "$white" "%(!.%{%F{yellow}%}.)$user@%m"
    fi
  fi
}

optional_text() {
		local text_length="$(echo $1 | wc -m)"
		((text_length = $CHARS + $text_length + 2))
    [[ "$text_length" -lt "$COLUMNS" ]] && echo -n "$1"
    [[ -n $2 && "$text_length" -gt "$COLUMNS" ]] && echo -n "$2"
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY=" $FX[bold]$FG[$white]±"
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment "$darkblue" "$black"
    else
      prompt_segment "$brightgreen" "$black"
    fi
		optional_text "${ref/refs\/heads\//⭠ }$dirty" "⭠"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment "$gray5" "$white" '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$RETVAL"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment "$black" "$white" "$symbols"
}

## Main prompt
build_prompt() {
  RETVAL=$?
	local long_path="$(pwd)"
  long_path=${long_path//$HOME/\~}
	CHARS=`echo "$long_path" | wc -m`
  prompt_status
  prompt_context
  prompt_dir
	prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
