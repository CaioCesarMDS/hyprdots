# ============================================================================
# Zsh Plugins Configuration (.plugins.zsh)
#
# Loads and configures Zsh plugins using Zinit. Also sets up completion styles.
# ============================================================================

# --- Zinit (Plugin Manager) ---
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# --- Plugins and Snippets ---
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-syntax-highlighting

zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use

zinit snippet OMZP::git

# --- Completion Fix & Style ---
# Remove broken or outdated completion dump files, then initialize completion system
if [ ! -f ~/.zcompdump ] || grep -q "_complete" ~/.zcompdump 2>/dev/null; then
  rm -f ~/.zcompdump*
fi
autoload -U compinit && compinit -C

# Completion style settings
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:completion:cd:*' fzf-preview use-cache 'ls --color $realpath'
