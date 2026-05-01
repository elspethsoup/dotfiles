# Claude Code plugin for oh-my-zsh
(( $+commands[claude] )) || return

# Aliases
alias cc='claude'
alias ccc='claude --continue'
alias ccr='claude --resume'
alias claude-yolo='claude --allow-dangerously-skip-permissions'

# Bootstrap a new project workspace and launch claude with project context
function new-project() {
  local projects_dir="$HOME/workspace/projects"

  # Snapshot existing projects before launching Claude
  local before
  before=$(ls "$projects_dir" 2>/dev/null | sort)

  # Launch interactive Claude with wrapper skill (auto-approve all tools)
  ( cd "$projects_dir" && claude --permission-mode=auto "/new-project-setup" )

  # Find the new project by diffing directory listing before/after
  local after new_project
  after=$(ls "$projects_dir" 2>/dev/null | sort)
  new_project=$(comm -23 <(echo "$after") <(echo "$before") | head -1)

  if [[ -z "$new_project" ]]; then
    echo "new-project: no new project detected. Did you complete the skill and type /exit?" >&2
    return 1
  fi

  cd "$projects_dir/$new_project"
  claude --append-system-prompt-file CLAUDE.md
}

# Completion
function _claude() {
  local -a subcommands
  subcommands=(
    'auth:Manage authentication'
    'mcp:Manage MCP servers'
    'agents:List available agent types'
    'update:Update Claude Code'
    'remote-control:Start remote control mode'
  )

  local -a global_flags
  global_flags=(
    '(-c --continue)'{-c,--continue}'[Continue most recent conversation]'
    '(-r --resume)'{-r,--resume}'[Resume a conversation by session ID]'
    '(-p --print)'{-p,--print}'[Print mode (non-interactive)]'
    '--model[Model to use]:model:(sonnet opus haiku claude-sonnet-4-6 claude-opus-4-6 claude-haiku-4-5-20251001)'
    '(-w --worktree)'{-w,--worktree}'[Run in a git worktree]'
    '(-v --version)'{-v,--version}'[Show version]'
    '--verbose[Enable verbose logging]'
    '--debug[Enable debug logging]'
    '--agent[Agent type to use]'
    '--permission-mode[Permission mode]:mode:(auto plan approve skip)'
    '--add-dir[Add directory to context]:directory:_directories'
    '--mcp-config[MCP config file]:file:_files'
    '--output-format[Output format]:format:(text json stream-json)'
    '--input-format[Input format]:format:(text stream-json)'
    '--system-prompt[System prompt]:prompt:'
    '--system-prompt-file[System prompt file]:file:_files'
    '--append-system-prompt[Append to system prompt]:prompt:'
    '--append-system-prompt-file[Append system prompt file]:file:_files'
    '--allowedTools[Allowed tools]:tools:'
    '--disallowedTools[Disallowed tools]:tools:'
    '--tools[Tools configuration]:tools:'
    '--max-turns[Max conversation turns]:turns:'
    '--max-budget-usd[Max budget in USD]:budget:'
    '--json-schema[JSON schema for output]:schema:'
    '--session-id[Session ID]:id:'
    '--fork-session[Fork from existing session]'
    '--no-session-persistence[Disable session persistence]'
    '--dangerously-skip-permissions[Skip permission checks]'
    '--allow-dangerously-skip-permissions[Allow skipping permission checks]'
  )

  _arguments -C \
    '1:command:->cmd' \
    '*:: :->args' \
    $global_flags

  case $state in
    cmd)
      _describe -t commands 'claude command' subcommands
      ;;
    args)
      case $words[1] in
        auth)
          local -a auth_cmds
          auth_cmds=(
            'login:Log in to Claude'
            'logout:Log out of Claude'
            'status:Show authentication status'
          )
          _describe -t commands 'auth command' auth_cmds
          ;;
        mcp)
          local -a mcp_cmds
          mcp_cmds=(
            'add:Add an MCP server'
            'add-json:Add an MCP server from JSON'
            'add-from-claude-desktop:Import from Claude Desktop'
            'list:List MCP servers'
            'get:Get MCP server details'
            'remove:Remove an MCP server'
            'reset-project-choices:Reset project choices'
            'serve:Start MCP server mode'
          )
          _describe -t commands 'mcp command' mcp_cmds
          ;;
      esac
      ;;
  esac
}

compdef _claude claude
