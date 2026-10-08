# Per-device overrides for this machine. Untracked by git — see the README.

# Personal Claude subscription on demand, from anywhere.
#
# Work is the default account (~/.claude) and owns the MCP connectors. Anything
# under ~/personal switches to the personal account automatically through
# direnv (~/personal/.envrc); this is the escape hatch for personal work that
# happens outside that directory.
pclaude() {
	CLAUDE_CONFIG_DIR="$HOME/.claude-personal" claude "$@"
}
