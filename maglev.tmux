#!/usr/bin/env bash
set -e

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/scripts/helpers.sh"

# Theme color
tmux_maglev_theme=$(get_tmux_option "@tmux-maglev-theme" "dark")
if [[ $tmux_maglev_theme == "light" ]]; then
    default_fg=colour0 # black
    default_bg=colour7 # white
else
    default_fg=colour7 # white
    default_bg=colour0 # black
fi

# Configure theme color for remote and non remote
if [[ -z $SSH_CLIENT ]]; then
    theme_color_1=colour6
else
    theme_color_1=colour5
fi

PLUGINS=$(tmux show-options -g | grep @tpm_plugins)

# Determine whether the tmux-cpu plugin should be installed
SHOW_CPU=false
if [[ $PLUGINS == *"tmux-cpu"* ]]; then
  SHOW_CPU=true
fi
SHOW_BATTERY=false
if [[ $PLUGINS == *"tmux-battery"* ]]; then
  SHOW_BATTERY=true
fi
SHOW_NETWORK=false
if [[ $PLUGINS == *"tmux-network-bandwidth"* ]]; then
  SHOW_NETWORK=true
fi

# Battery icons
tmux set -g @batt_charged_icon "︎♡"
tmux set -g @batt_charging_icon "︎♡"
tmux set -g @batt_discharging_icon "︎♡"
tmux set -g @batt_attached_icon "︎♡"

# Optional prefix highlight plugin
tmux set -g @prefix_highlight_show_copy_mode 'on'
tmux set -g @prefix_highlight_copy_mode_attr 'fg=black,bg=yellow,bold' # default is 'fg=default,bg=yellow'

# BEGIN Fix CPU segment --------------------------------------------------------

# The plugin “cpu” is removing a blank space between the session name and first
# window name. This script adds the blank space back to the `status-left`.
# Issue #2: https://github.com/caiogondim/maglev/issues/2

get_tmux_option() {
  local option
  local default_value
  local option_value

  option="$1"
  default_value="$2"
  option_value="$(tmux show-option -gqv "$option")"

  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

set_tmux_option() {
  local option=$1
  local value=$2

  tmux set-option -gq "$option" "$value"
}

main() {
  local status_left

  status_left=$(get_tmux_option "status-left")
  set_tmux_option "status-left" "$status_left "
}
main

# END Fix CPU segment ----------------------------------------------------------

apply_theme() {
  left_separator=''
  left_separator_black=''
  right_separator=''
  right_separator_black=''
  right_top_separator=''
  session_symbol=''

  # panes
  pane_border_fg=$default_fg
  pane_active_border_fg=colour4

  tmux set -g pane-border-style fg=$pane_border_fg \; set -g pane-active-border-style fg=$pane_active_border_fg
  #uncomment for fat borders
  #tmux set -ga pane-border-style bg=$pane_border_fg \; set -ga pane-active-border-style bg=$pane_active_border_fg

  display_panes_active_colour=colour4
  display_panes_colour=colour4
  tmux set -g display-panes-active-colour $display_panes_active_colour \; set -g display-panes-colour $display_panes_colour

  # messages
  message_fg=$default_fg
  message_bg=colour3 # yellow
  message_attr=bold
  tmux set -g message-style fg=$message_fg,bg=$message_bg,$message_attr

  message_command_fg=$default_fg
  message_command_bg=colour3 # yellow
  tmux set -g message-command-style fg=$message_command_fg,bg=$message_command_bg,$message_attr

  # windows mode
  mode_fg=$default_fg
  mode_bg=colour3 # yellow
  mode_attr=bold
  tmux setw -g mode-style fg=$mode_fg,bg=$mode_bg,$mode_attr

  # status line
  status_fg=$default_fg
  status_bg=$default_bg
  tmux set -g status-style fg=$status_fg,bg=$status_bg

  # OS icon
  if [ $(_os) = "macos" ]; then
    os_icon=
  else
    os_icon=
  fi

  session_fg=$default_bg
  session_bg=$theme_color_1
  status_left="#[fg=$session_fg,bg=$session_bg,bold] $os_icon  #h 󰂺 #S#[fg=$session_bg,bg=$status_bg,nobold]$left_separator_black  "
  if [ x"$(tmux -q -L tmux_theme_status_left_test -f /dev/null new-session -d \; show -g -v status-left \; kill-session)" = x"[#S] " ]; then
    status_left="$status_left"
  fi
  tmux set -g status-left-length 100 \; set -g status-left "$status_left"

  window_status_fg=$default_fg
  window_status_bg=$default_bg
  window_status_format=" #I #W "
  tmux setw -g window-status-style fg=$window_status_fg,bg=$window_status_bg \; setw -g window-status-format "$window_status_format"

  window_status_current_fg=$default_bg
  window_status_current_bg=colour4
  window_status_current_format="#[fg=$window_status_bg,bg=$window_status_current_bg]$left_separator_black#[fg=$window_status_current_fg,bg=$window_status_current_bg,bold]$window_status_format#[fg=$window_status_current_bg,bg=$status_bg,nobold]$left_separator_black "
  tmux setw -g window-status-current-format "$window_status_current_format"
  tmux set -g status-justify left

  window_status_activity_fg=default
  window_status_activity_bg=default
  window_status_activity_attr=underscore
  tmux setw -g window-status-activity-style fg=$window_status_activity_fg,bg=$window_status_activity_bg,$window_status_activity_attr

  window_status_bell_fg=colour3 # yellow
  window_status_bell_bg=default
  window_status_bell_attr=blink,bold
  tmux setw -g window-status-bell-style fg=$window_status_bell_fg,bg=$window_status_bell_bg,$window_status_bell_attr

  window_status_last_fg=colour4
  window_status_last_attr=default
  tmux setw -g window-status-last-style $window_status_last_attr,fg=$window_status_last_fg

  battery_full_fg=$theme_color_1
  battery_empty_fg=$default_bg
  battery_bg=$theme_color_1
  time_date_fg=$default_fg
  time_date_bg=colour3       # yellow
  whoami_fg=$default_bg
  whoami_bg=$theme_color_1
  host_fg=$default_bg
  host_bg=colour4
  status_right="#{prefix_highlight} #[fg=$host_fg,bg=$host_bg,nobold]$right_top_separator  󰃭 %m/%d %R #[fg=$host_bg,bg=$host_fg,nobold]"

  # Only show solid separator if CPU or Battery are to be displayed
  if [ "$SHOW_BATTERY" = true ] || [ "$SHOW_CPU" = true ]; then
    status_right="$status_right$right_top_separator#[fg=$battery_bg,bg=$host_fg,nobold]"
  fi

  if [ "$SHOW_BATTERY" = true ]; then
    status_right="$status_right $right_separator_black #[fg=$host_fg,bg=$battery_bg,bold] #{battery_icon} #{battery_percentage}#[fg=$host_bg,bg=$battery_fg,nobold]"
  fi

  # Only add intermediate separator if both CPU and Batter are to be displayed
  if [ "$SHOW_BATTERY" = true ] && [ "$SHOW_CPU" = true ]; then
    status_right="$status_right $right_separator#[fg=$battery_bg,bg=$battery_bg,bold]"
  fi

  if [ "$SHOW_NETWORK" = true ]; then
    status_right="$status_right#[fg=$host_fg,bg=$battery_bg,bold]$right_top_separator #{network_bandwidth} $right_separator_black"
  fi

  if [ "$SHOW_CPU" = true ]; then
    status_right="$status_right#[fg=$host_fg,bg=$battery_bg,bold]$right_top_separator 󰈸 CPU #{cpu_percentage} "
  fi

  tmux set -g status-right-length 64 \; set -g status-right "$status_right"

  # clock
  clock_mode_colour=colour4
  tmux setw -g clock-mode-colour $clock_mode_colour
}

circled_digit() {
  circled_digits='⓪①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳'
  if [ $1 -lt 20 ] 2>/dev/null; then
    echo ${circled_digits:$1:1}
  else
    echo $1
  fi
}

maximize_pane() {
  tmux -q -L swap-pane-test -f /dev/null new-session -d \; new-window \; new-window \; swap-pane -t :1 \; kill-session || {
    tmux display 'your tmux version has a buggy swap-pane command - see ticket #108, fixed in upstream commit 78e783e'
    exit
  }
  __current_pane=$(tmux display -p '#{pane_id}')

  __dead_panes=$(tmux list-panes -s -F '#{pane_dead} #{pane_id} #{pane_start_command}' | grep -o '^1 %.\+maximized.\+$' || true)
  __restore=$(echo "${__dead_panes}" | sed -n -E -e "s/^1 ${__current_pane} .+maximized.+(%[0-9]+)$/tmux swap-pane -s \1 -t ${__current_pane} \; kill-pane -t ${__current_pane}/p" -e "s/^1 (%[0-9]+) .+maximized.+${__current_pane}$/tmux swap-pane -s \1 -t ${__current_pane} \; kill-pane -t \1/p")

  if [ x"${__restore}" = x ]; then
    [ x"$(tmux list-panes | wc -l | sed 's/^ *//g')" = x1 ] && tmux display "Can't maximize with only one pane" && return
    __window=$(tmux new-window -P "exec maximized& tmux setw remain-on-exit on; clear; tmux clear-history; printf 'Pane has been maximized, press <prefix>+ to restore. %s' \\${__current_pane};")
    __window=${__window%.*}

    __guard=50
    while ([ x"$(tmux list-panes -t ${__window} -F '#{session_name}:#{window_index} #{pane_dead}')" != x"${__window} "1 ] && [ x"${__guard}" != x0 ]); do
      sleep 0.01
      __guard=$((__guard - 1))
    done
    if [ x"${__guard}" = 0 ]; then
      exit 1
    fi

    __new_pane=$(tmux display -p '#{pane_id}')
    tmux setw remain-on-exit off \; swap-pane -s "${__current_pane}" -t "${__new_pane}"
  else
    ${__restore} || tmux kill-pane
  fi
}

battery() {
  battery_symbol=$1
  battery_symbol_count=$2
  battery_palette=$3
  battery_status=$4
  if [ x"$battery_symbol_count" = x"auto" ]; then
    columns=$(tmux -q display -p '#{client_width}' 2>/dev/null || echo 80)
    if [ $columns -ge 80 ]; then
      battery_symbol_count=10
    else
      battery_symbol_count=5
    fi
  fi
  battery_symbol_heart_full=♥
  battery_symbol_heart_empty=♥
  battery_symbol_block_full=◼
  battery_symbol_block_empty=◻
  eval battery_symbol_full='$battery_symbol_'"$battery_symbol"'_full'
  eval battery_symbol_empty='$battery_symbol_'"$battery_symbol"'_empty'

  uname_s=$(uname -s)
  if [ x"$uname_s" = x"Darwin" ]; then
    batt=$(pmset -g batt)
    percentage=$(echo $batt | egrep -o [0-9]+%) || return
    discharging=$(echo $batt | grep -qi "discharging" && echo "true" || echo "false")
    charge="${percentage%%%} / 100"
  elif [ x"$uname_s" = x"Linux" ]; then
    batpath=/sys/class/power_supply/BAT0
    if [ ! -d $batpath ]; then
      batpath=/sys/class/power_supply/BAT1
    fi
    batfull=$batpath/energy_full
    batnow=$batpath/energy_now
    if [ ! -r $batfull -o ! -r $batnow ]; then
      return
    fi
    discharging=$(grep -qi "discharging" $batpath/status && echo "true" || echo "false")
    charge="$(cat $batnow) / $(cat $batfull)" || return
  fi

  if [ x"$battery_status" = x"1" -o x"$battery_status" = x"true" ]; then
    if [ x"$discharging" = x"true" ]; then
      printf "%s " 🔋
    else
      printf "%s " ⚡
    fi
  fi

  if echo $battery_palette | grep -q -E '^(colour[0-9]{1,3},?){3}$'; then
    battery_full_fg=$(echo $battery_palette | cut -d, -f1)
    battery_empty_fg=$(echo $battery_palette | cut -d, -f2)
    battery_bg=$(echo $battery_palette | cut -d, -f3)

    full=$(printf %.0f $(echo "$charge * $battery_symbol_count" | bc -l))
    [ $full -gt 0 ] &&
      printf '#[fg=%s,bg=%s]' $battery_full_fg $battery_bg &&
      printf "%0.s$battery_symbol_full" $(seq 1 $full)
    empty=$(($battery_symbol_count - $full))
    [ $empty -gt 0 ] &&
      printf '#[fg=%s,bg=%s]' $battery_empty_fg $battery_bg &&
      printf "%0.s$battery_symbol_empty" $(seq 1 $empty)
  elif echo $battery_palette | grep -q -E '^heat(,colour[0-9]{1,3})?$'; then
    battery_bg=$(echo $battery_palette | cut -s -d, -f2)
    battery_bg=${battery_bg:-colour16}
    heat="233 234 235 237 239 241 243 245 247 144 143 142 184 214 208 202 196"
    heat_count=$(echo $(echo $heat | wc -w))

    eval set -- "$heat"
    heat=$(eval echo $(eval echo $(printf "\\$\{\$(expr %s \* $heat_count / $battery_symbol_count)\} " $(seq 1 $battery_symbol_count))))

    full=$(printf %.0f $(echo "$charge * $battery_symbol_count" | bc -l))
    printf '#[bg=%s]' $battery_bg
    [ $full -gt 0 ] &&
      printf "#[fg=colour%s]$battery_symbol_full" $(echo $heat | cut -d' ' -f1-$full)
    empty=$(($battery_symbol_count - $full))
    if [ x"$battery_symbol" = x"heart" ]; then
      [ $empty -gt 0 ] &&
        printf '#[fg=%s]' $battery_bg &&
        printf "%0.s$battery_symbol_empty" $(seq 1 $empty)
    else
      [ $empty -gt 0 ] &&
        printf "#[fg=colour%s]$battery_symbol_empty" $(echo $heat | cut -d' ' -f$((full + 1))-$(($full + $empty)))
    fi
  fi
}

apply_theme
