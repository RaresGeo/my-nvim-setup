# Omarchy auto-generated tmux theme with powerline arrows

# status
set -g status-position top
set -g status "on"
set -g status-bg "{{ selection_background }}"
set -g status-justify "left"
set -g status-left-length "100"
set -g status-right-length "100"

# messages
set -g message-style "fg={{ foreground }},bg={{ selection_background }},align=centre"
set -g message-command-style "fg={{ foreground }},bg={{ selection_background }},align=centre"

# panes
set -g pane-border-style "fg={{ color8 }}"
set -g pane-active-border-style "fg={{ accent }}"

# windows
setw -g window-status-activity-style "fg={{ foreground }},bg={{ selection_background }},none"
setw -g window-status-separator ""
setw -g window-status-style "fg={{ foreground }},bg={{ selection_background }},none"

# Modes
setw -g clock-mode-colour "{{ accent }}"
setw -g mode-style "fg={{ color3 }},bg={{ foreground }},bold"

# statusline with powerline arrows
set -g status-left "#{?client_prefix,#[fg={{ background }}#,bg={{ color1 }}],#[fg={{ background }}#,bg={{ accent }}]}  #S #{?client_prefix,#[fg={{ color1 }}#,bg={{ selection_background }}],#[fg={{ accent }}#,bg={{ selection_background }}]} "
set -g status-right "#[fg={{ accent }}#,bg={{ selection_background }}]#[fg={{ background }}#,bg={{ accent }}]  #{b:pane_current_path} #[fg={{ color5 }}#,bg={{ accent }}]#[fg={{ background }}#,bg={{ color5 }}]  %Y-%m-%d %H:%M "

# window-status with arrows
setw -g window-status-format "#[fg={{ selection_background }}#,bg={{ selection_background }}]#[fg={{ color8 }}#,bg={{ selection_background }}] #I  #W #[fg={{ selection_background }}#,bg={{ selection_background }}]"
setw -g window-status-current-format "#[fg={{ selection_background }}#,bg={{ accent }}]#[fg={{ background }}#,bg={{ accent }}] #I  #W #[fg={{ accent }}#,bg={{ selection_background }}]"
