# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
unsetopt share_history

PROMPT_INDENT=5

prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n " %{%k%}"
  fi
  echo -n "\n${(l:$PROMPT_INDENT:: :)}%{%F{blue}%}╰────➤%{%f%}"
}

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# Source Deno env if it exists
[[ -f "$HOME/.deno/env" ]] && . "$HOME/.deno/env"

[[ -o login ]] && cd work 2>/dev/null

export VOLTA_HOME="$HOME/.volta"
[[ -d "$VOLTA_HOME/bin" ]] && export PATH="$VOLTA_HOME/bin:$PATH"

# Some things might be handled or installed by something else, like mise, so do this conditionally.
[[ -d "/usr/local/go/bin" ]] && export PATH="$PATH:/usr/local/go/bin"
GOPATH=$(go env GOPATH 2>/dev/null)
[[ -d "$GOPATH/bin" ]] && export PATH="$PATH:$GOPATH/bin"
[[ -d "$HOME/.foundry/bin" ]] && export PATH="$PATH:$HOME/.foundry/bin"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$PATH:$HOME/.cargo/bin"
[[ -d "/home/linuxbrew/.linuxbrew/opt/openjdk@21/bin" ]] && export PATH="/home/linuxbrew/.linuxbrew/opt/openjdk@21/bin:$PATH"

# Some things like Arch might not have homebrew
[[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
command -v mise &>/dev/null && eval "$(mise activate zsh)"
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

if command -v zoxide &>/dev/null; then
	eval "$(zoxide init zsh)"
	alias cd="z"
fi

if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

if command -v docker &> /dev/null; then
	dorun() {
	    local services=$(docker compose config --services)
	    local service_count=$(echo "$services" | wc -l)
	    
	    if [ "$service_count" -eq 1 ]; then
		docker compose run --rm $services "$@"
	    else
		docker compose run --rm "$@"
	    fi
	}

	doup() { 
		docker compose up "$@"
	}
fi

if command -v fzf &> /dev/null; then
	ff() {
		local search_dir="${1:-.}"
		local file
		file=$(find "$search_dir" -type f | fzf --preview 'bat --style=numbers --color=always {}') || return
		[[ -n "$file" ]] && echo "$file"
	}

	fcd() {
		local search_dir="${1:-.}"
		local preview_cmd

		if command -v eza &>/dev/null; then
		preview_cmd='eza -lh --group-directories-first --icons=auto {}'
		else
		preview_cmd='ls -la {}'
		fi

		local dir
		dir=$(find "$search_dir" -type d | fzf \
		--preview "$preview_cmd") || return
		[[ -n "$dir" ]] && cd "$dir"
	}

	fnvim() {
		fcd "$@" || return
		nvim .
	}

  if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
  fi
fi

alias delete-branches='~/.my_scripts/delete_all_git_branches.sh'
alias prs="gh pr list --author=\"@me\" --json number,title,url"
alias ghurl="git remote -v | grep origin | grep fetch | awk '{print $2}' | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/.git$//g'"

alias xcopy='xclip -sel clip'

alias wakehp='wakeonlan $(cat ~/.ssh/homelab_hp_mac)'
alias sshhp='ssh daniel@$(cat ~/.ssh/homelab_hp_ip)'
