# zmodload zsh/zprof

integer t0=$(date '+%s')  # move this around

fpath=($fpath $HOME/.zsh/functions)
typeset -U fpath

# Completion init with bounded-staleness caching.
#   - If .zcompdump exists and is <24h old: `compinit -C` trusts it and skips
#     the per-file security audit (the expensive part). Fast path.
#   - Otherwise (missing or >24h old): full `compinit` rebuilds the dump and
#     picks up completions for any tools installed since the last rebuild.
# This bounds staleness to ~24h instead of "forever until manual rm", which
# unconditional `compinit -C` suffered from -- newly brew-installed tools'
# completions now appear within a day automatically.
# Glob qualifier (#qNmh-24): N=nullglob, mh-24=modified within last 24 hours.
zmodload zsh/complist 2>/dev/null
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qNmh-24) ]]; then
    compinit -C
else
    compinit
fi

# Byte-compile the completion dump to a .zwc so the next shell loads
# pre-parsed completions instead of re-parsing ~50KB of code. compinit's
# internal `source ~/.zcompdump` automatically prefers a newer sibling
# .zwc, so this run pays the compile cost once (in the background) and
# every subsequent shell reads the compiled form. Profiling (zsh-bench +
# zprof) showed completion loading dominates first-prompt lag, so this is
# the highest-leverage startup win. The uv hook below globs `.zcompdump*`,
# which also clears the stale .zwc when completions are regenerated.
if [[ ! -e ~/.zcompdump.zwc || ~/.zcompdump -nt ~/.zcompdump.zwc ]]; then
    zcompile ~/.zcompdump &!
fi

# Inlined equivalent of `eval "$(brew shellenv)"` -- saves ~40ms of subprocess
# overhead on every shell start. These values are stable for Apple Silicon
# installs; if you ever migrate brew prefix, regenerate from `brew shellenv`.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export INFOPATH="/opt/homebrew/share/info${INFOPATH:+:$INFOPATH}"
# /opt/homebrew/bin is already on PATH via /etc/paths.d/homebrew (added by
# /usr/libexec/path_helper from /etc/zprofile). Prepend /opt/homebrew/sbin
# for completeness; `typeset -U path` in setopt.zsh dedupes.
path=(/opt/homebrew/bin /opt/homebrew/sbin $path)

source ~/.zsh/setopt.zsh
source ~/.zsh/completion.zsh
source ~/.zsh/editor.zsh
# source ~/.zsh/bindkeys.zsh
source ~/.zsh/history.zsh
source ~/.zsh/exports.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/prompt.zsh
source ~/.zsh/functions.zsh
source ~/.zsh/functions/githelpers.zsh
source ~/.zsh/functions/docker.zsh
source ~/.zsh/functions/google_cloud.zsh
source ~/.zsh/fzf_theme.zsh

source ~/.zsh/plugins.zsh

source ~/.vault/keys.zsh

# notify if startup time is too long
# function {
#     local -i t1 startup
#     t1=$(date '+%s')
#     startup=$(( t1 - t0 ))
#     [[ $startup -gt 1 ]] && print "Hmm, poor shell startup time: $startup"
# }
# unset t0

#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Homebrew Ruby block removed 2026-06-06. It was dormant (the guard dir
# /opt/homebrew/opt/ruby/bin doesn't exist), but it was a latent startup
# landmine: if Ruby were ever brew-installed, the `gem environment gemdir`
# subprocess forks Ruby on every shell start (~80-170ms measured). If you
# need Homebrew Ruby again, prefer a static PATH and avoid the subprocess:
#   export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
#   export PATH="/opt/homebrew/lib/ruby/gems/<ver>/bin:$PATH"  # hardcode, no `gem` fork

# TODO uncomment this this if you're turning of the vi mode plugin
# eval "$(fzf --zsh)"

alias luamake=/Users/petrov/oss/lua-language-server/3rd/luamake/luamake

# NOTE: second `brew shellenv` removed -- already called at top of this file.

# sdkman removed 2026-04-17 -- 6 months of history showed zero JVM usage.
# If Java is ever needed again: `mise use -g java@17` (or reinstate sdkman
# with `source ~/.sdkman/bin/sdkman-init.sh`). The ~/.sdkman directory is
# still on disk and can be `rm -rf`d after a grace period.

# load nvm to manage nodejs versions
# [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# uv completion: installed as ~/.zsh/functions/_uv so compinit loads it lazily
# via fpath on first tab completion. Regenerate if uv binary is newer.
_uv_completion_file="${HOME}/.zsh/functions/_uv"
if [[ ! -f "$_uv_completion_file" ]] || [[ "$(command -v uv)" -nt "$_uv_completion_file" ]]; then
    uv generate-shell-completion zsh > "$_uv_completion_file"
    # force compinit to re-scan next shell start
    rm -f "${HOME}/.zcompdump"*(N)
fi



# notify if startup time is too long
# function {
#     local -i t1 startup
#     t1=$(date '+%s')
#     startup=$(( t1 - t0 ))
#     [[ $startup -gt 1 ]] && print "Hmm, poor shell startup time: $startup"
# }
unset t0

# zprof

nv() {
  local appname=$1
  shift
  if [ "$#" -eq 0 ]; then
    NVIM_APPNAME=$appname command nvim
  else
    NVIM_APPNAME=$appname command nvim "$@"
  fi
}


# ### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
# export PATH="/Users/pverkhogliad/.rd/bin:$PATH"
# ### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Inlined equivalent of `eval "$(mise activate --shims zsh)"`.
# That command just emits two PATH prepends -- no reason to fork a subprocess
# for them every shell start. `typeset -U path` handles de-duplication.
# Using shims (not the chpwd hook): stable binary paths for editors/LSPs, and
# no hook cost on cd. Trade-off: ~10ms per shim invocation, and `mise shell
# <tool>@ver` is unsupported (use `mise exec <tool>@ver -- ...` instead).
path=("$HOME/.local/share/mise/shims" /opt/homebrew/bin $path)

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/pverkhogliad/.lmstudio/bin"
# End of LM Studio CLI section

export SSH_AUTH_SOCK=/Users/pverkhogliad/.yubiagent/sock

# personal scripts and local installs first on PATH
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

export PATH="/usr/local/MacGPG2/bin:$PATH"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/pverkhogliad/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
