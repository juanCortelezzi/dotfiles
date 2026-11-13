#!/usr/bin/env bash
set -u

mode=${1:-warm}
prompt_re='tester@dotfiles-zsh'
pass=0
fail=0
known=0
plugins_cmd=$HOME/.config/zsh/zsh-plugins
shims=/tmp/shims
netlog=/tmp/net.log
starts=()
blank=()

t() { tmux -L zt -f /dev/null "$@"; }
now() { date +%s%N; }
ms() { echo $(( ($(now) - $1) / 1000000 )); }
screen() { t capture-pane -p -J -S - -t "$S"; }
count() { screen | grep -cxF -- "$1"; }
prompts() { screen | grep -cF -- "$prompt_re"; }
last_prompt() { screen | grep -F -- "$prompt_re" | tail -1; }
has() { (( $(count "$1") >= ${2:-1} )); }
until_ok() {
  local end=$(( $(now) + $1 * 1000000 ))
  shift
  until "$@"; do
    (( $(now) > end )) && return 1
    sleep 0.01
  done
}
key() { t send-keys -t "$S" -H "$@"; }
typ() {
  local h
  for h in $(printf %s "$1" | od -An -tx1); do
    key "$h"
    sleep 0.01
  done
}
enter() { key 0d; }
run() { typ "$1"; enter; }
expect() { until_ok "${3:-5000}" has "$1" "${2:-1}"; }

BS=7f ESC=1b TAB=09 CTRL_C=03 CTRL_K=0b CTRL_J=0a
UP_CSI='1b 5b 41' UP_SS3='1b 4f 41' DOWN_CSI='1b 5b 42' DOWN_SS3='1b 4f 42' RIGHT='1b 5b 43'

boot() {
  t kill-session -a -t keep 2>/dev/null
  pkill -x zsh-patina
  until_ok 2000 eval '! pgrep -x zsh-patina >/dev/null'
  rm -rf /tmp/zsh-patina-*
}

spawn() {
  S=$1
  shift
  t kill-session -t "$S" 2>/dev/null
  t0=$(now)
  t new-session -d -s "$S" -x 120 -y 50 -- "$@" \; pipe-pane -t "$S" "cat >/tmp/raw-$S"
  pid=$(t display -p -t "$S" '#{pane_pid}')
}

zle_started() { grep -q $'\e\\[?2004h' "/tmp/raw-$S" 2>/dev/null; }
prompt_shown() { (( $(prompts) > 0 )); }

wait_prompt() {
  until_ok "$1" eval 'prompt_shown || zle_started' || { why="no prompt"; return 1; }
  if until_ok 1000 prompt_shown; then
    startup_ms=$(ms "$t0")
    starts+=("$startup_ms")
    return 0
  fi
  blank+=("$S")
  key 0c
  until_ok 5000 prompt_shown || { why="no prompt even after ^L"; return 1; }
  startup_ms=""
}

start() {
  spawn "$1" zsh -l
  wait_prompt 20000
}

probes=0
why=""
first_ms=""
loaded() {
  local end=$(( $(now) + ${1:-60000} * 1000000 ))
  while (( $(now) < end )); do
    probes=$(( probes + 1 ))
    t send-keys -t "$S" -l -- "print -r -- P$probes:\${+widgets[autosuggest-accept]}\${+functions[_zsh_patina]}\${+functions[compdef]}"
    enter
    until_ok $(( (end - $(now)) / 1000000 )) eval 'screen | grep -q "^P$probes:"' || break
    has "P$probes:111" && return 0
    sleep 0.2
  done
  why="plugins not loaded: $(screen | grep -E "^P[0-9]+:" | tail -1)"
  return 1
}

fresh() {
  [[ $2 == immediate ]] && boot
  start "$1" || return 1
  [[ $2 == loaded ]] && { loaded || return 1; }
  return 0
}

report() {
  if (( $1 )); then
    pass=$(( pass + 1 ))
    printf 'PASS  %s\n' "$2"
  else
    fail=$(( fail + 1 ))
    printf 'FAIL  %s%s\n' "$2" "${3:+  ($3)}"
    [[ -n ${DEBUG:-} ]] && screen | grep -v '^$' | tail -15 | sed 's/^/      | /'
  fi
  return 0
}

check() {
  local name=$1
  shift
  why=""
  "$@"
  report $(( ! $? )) "$name" "$why"
  t kill-session -t "$S" 2>/dev/null
}

check_known() {
  local name=$1
  shift
  why=""
  if "$@"; then
    report 1 "$name"
  else
    known=$(( known + 1 ))
    printf 'KNOWN %s%s\n' "$name" "${why:+  ($why)}"
  fi
  t kill-session -t "$S" 2>/dev/null
}

make_shims() {
  mkdir -p "$shims"
  printf '#!/bin/sh\necho "curl $*" >>%s\nexit 1\n' "$netlog" >"$shims/curl"
  printf '#!/bin/sh\ncase " $* " in *" clone "*|*" fetch "*|*" pull "*|*" ls-remote "*) echo "git $*" >>%s; exit 1;; esac\nexec /usr/bin/git "$@"\n' "$netlog" >"$shims/git"
  chmod +x "$shims/curl" "$shims/git"
  rm -f "$netlog"
}
offline() { PATH=$shims:$PATH "$@"; }
no_network() { [[ ! -s $netlog ]] || { why="ran: $(tr '\n' ';' <"$netlog")"; return 1; }; }

install_checks() {
  local out err rc t1
  t1=$(now)
  out=$("$plugins_cmd" install 2>/tmp/install.err); rc=$?
  err=$(tr '\n' ' ' </tmp/install.err)
  (( rc == 0 )) && [[ -z $err ]] && (( $(wc -l <<<"$out") == 3 ))
  report $(( ! $? )) "install: installs all plugins with a 3-line summary ($(ms "$t1") ms)" "rc=$rc out=$(tr '\n' ' ' <<<"$out") err=$err"
  make_shims
  out=$(offline "$plugins_cmd" install 2>&1); rc=$?
  why=""
  (( rc == 0 )) && no_network && [[ $(grep -c ': present$' <<<"$out") == 3 ]]
  report $(( ! $? )) "install: second run leaves existing plugins alone, no network" "${why:-rc=$rc out=$(tr '\n' ' ' <<<"$out")}"
}

update_checks() {
  local dir=$HOME/.local/share/zsh/plugins/zsh-completions dump out rc
  dump=$HOME/.cache/zsh/zcompdump-$(zsh -fc 'print $ZSH_VERSION')
  touch "$dir/dirty"
  out=$("$plugins_cmd" update 2>&1); rc=$?
  rm -f "$dir/dirty"
  (( rc != 0 )) && grep -q 'zsh-completions: has local changes' <<<"$out"
  report $(( ! $? )) "update: refuses a repo with local changes" "rc=$rc out=$(tr '\n' ' ' <<<"$out")"
  mkdir -p "${dump%/*}"; touch "$dump" "${dump%/*}/keep"
  out=$("$plugins_cmd" update 2>&1); rc=$?
  (( rc == 0 )) && [[ ! -e $dump && -e ${dump%/*}/keep ]] && (( $(wc -l <<<"$out") == 3 ))
  report $(( ! $? )) "update: fast-forwards, re-verifies patina, removes only the zcompdump" "rc=$rc out=$(tr '\n' ' ' <<<"$out")"
  rm -f "${dump%/*}/keep"
}

startup_checks() {
  boot
  local cwds=/tmp/cwds prompts_seen=/tmp/prompts stop=/tmp/stop
  rm -f "$cwds" "$prompts_seen" "$stop" "$HOME/startup.err"
  rm -f "$netlog"
  spawn startup sh -c 'PATH=$0:$PATH exec zsh -l 2>"$HOME/startup.err"' "$shims"
  (
    while [[ ! -e $stop ]]; do
      readlink "/proc/$pid/cwd" >>"$cwds"
      sleep 0.005
    done
  ) &
  local cwd_sampler=$!
  (
    while [[ ! -e $stop ]]; do
      t capture-pane -p -J -t "$S" | grep -F -- "$prompt_re" >>"$prompts_seen"
      sleep 0.05
    done
  ) &
  local screen_sampler=$!
  local first_ok=0 load_ok=0 load_ms=""
  if wait_prompt 180000; then
    first_ok=1
    first_ms=$startup_ms
    run 'print -r -- "pwd1:$PWD"'
    loaded 180000 && { load_ok=1; load_ms=$(ms "$t0"); }
    sleep 0.5
  fi
  touch "$stop"
  wait "$cwd_sampler" "$screen_sampler"
  run 'print -r -- "pwd2:$PWD"'
  expect "pwd2:$HOME" 1 5000

  report "$first_ok" "startup: first prompt appears${startup_ms:+ (${startup_ms} ms)}"
  report "$load_ok" "startup: plugins loaded (autosuggest, patina, compinit)${load_ms:+ (${load_ms} ms)}" "$why"
  local p1 p2
  p1=$(screen | grep -m1 '^pwd1:' || true)
  p2=$(screen | grep -m1 '^pwd2:' || true)
  [[ $p1 == "pwd1:$HOME" ]]; report $(( ! $? )) "startup: command typed at first prompt runs in \$HOME" "${p1:-no output}"
  [[ $p2 == "pwd2:$HOME" ]]; report $(( ! $? )) "startup: cwd is \$HOME after plugins load" "${p2:-no output}"
  local bad_cwd
  bad_cwd=$(sort -u "$cwds" | grep -vxF "$HOME" | tr '\n' ' ')
  [[ -z $bad_cwd ]]; report $(( ! $? )) "startup: shell cwd never leaves \$HOME while loading" "seen ${bad_cwd% }"
  local bad_prompt
  bad_prompt=$(grep -m1 -E 'zsh-(patina|autosuggestions|completions)' "$prompts_seen")
  [[ -z $bad_prompt ]]; report $(( ! $? )) "startup: prompt never shows a plugin directory (zsh-patina)" "$bad_prompt"
  local err
  err=$(head -c 200 "$HOME/startup.err" | tr -s '\n ' ' ')
  [[ ! -s $HOME/startup.err ]]; report $(( ! $? )) "startup: no stderr output" "$err"
  why=""; no_network; report $(( ! $? )) "startup: no network (git clone/fetch/pull, curl)" "$why"
  t kill-session -t "$S" 2>/dev/null
}

sc_ctrl_c_during_load() {
  boot
  start "$1" || return 1
  local i
  for i in $(seq 20); do key $CTRL_C; sleep 0.05; done
  loaded || return 1
  run 'print -r -- "pwd3:$PWD"'
  expect "pwd3:$HOME" || { why=$(screen | grep -m1 '^pwd3:' || echo "no output"); return 1; }
}

sc_absent() {
  boot
  local data=/tmp/no-plugins
  rm -rf "$data" "$netlog"
  spawn "$1" sh -c 'XDG_DATA_HOME=$0 PATH=$1:$PATH exec zsh -l 2>/tmp/absent.err' "$data" "$shims"
  wait_prompt 20000 || return 1
  run 'print -r -- ab$((6*7))'
  expect ab42 || { why="command did not run"; return 1; }
  no_network || return 1
  [[ ! -e $data/zsh ]] || { why="created $data/zsh"; return 1; }
  local err
  err=$(cat /tmp/absent.err)
  [[ $(wc -l <<<"$err") == 1 && $err == *"zsh-plugins install"* ]] || { why="stderr: $(tr '\n' ' ' <<<"$err")"; return 1; }
}

sc_start_elsewhere() {
  spawn "$1" sh -c 'cd /tmp && exec zsh -l'
  wait_prompt 20000 || return 1
  run 'print -r -- "cwd:$PWD"'
  expect cwd:/tmp || { why=$(screen | grep -m1 '^cwd:' || echo "no output"); return 1; }
}

sc_zdotdir_untouched() {
  local h=/tmp/zdot-home before after
  rm -rf "$h"
  mkdir -p "$h/.local/share" "$h/.cache"
  cp -R /dotfiles/zsh/. "$h/"
  ln -s "$HOME/.local/share/zsh" "$h/.local/share/zsh"
  before=$(ls -lAR --full-time "$h/.config/zsh")
  spawn "$1" env HOME="$h" zsh -l
  wait_prompt 20000 || return 1
  run 'print -r -- zd1'; expect zd1 || return 1
  typ 'print -r -- ~/.zshe'; key $TAB; sleep 0.3; enter
  expect "$h/.zshenv" || { why="no completion"; return 1; }
  key $UP_CSI; sleep 0.1; enter; expect "$h/.zshenv" 2 || return 1
  run exit
  until_ok 5000 eval '! t has-session -t "$S" 2>/dev/null' || { why="shell did not exit"; return 1; }
  after=$(ls -lAR --full-time "$h/.config/zsh")
  [[ $before == "$after" ]] || { why="ZDOTDIR changed"; return 1; }
  [[ -s $h/.cache/zsh/zhistory ]] && compgen -G "$h/.cache/zsh/zcompdump-*" >/dev/null || { why="history or zcompdump not in \$XDG_CACHE_HOME/zsh: $(ls -A "$h/.cache/zsh" | tr '\n' ' ')"; return 1; }
}

sc_focus_events() {
  fresh "$1" "$2" || return 1
  local shape
  typ 'print -r -- fo1abc'; key 1b 5b 49; sleep 0.1; key 1b 5b 4f; sleep 0.1
  shape=$(t display -p -t "$S" '#{cursor_shape}')
  key $BS; typ d; enter
  expect fo1abd || { why="got: $(screen | grep -m1 '^fo1')"; return 1; }
  [[ $shape == bar ]] || { why="cursor became $shape after focus events"; return 1; }
}

sc_backspace() {
  fresh "$1" "$2" || return 1
  typ 'print -r -- bs1abc'; key $BS; enter
  expect bs1ab || { why="got: $(screen | grep -m1 '^bs1')"; return 1; }
}

sc_backspace_after_esc_a() {
  fresh "$1" "$2" || return 1
  typ 'print -r -- bs2abc'; key $ESC; sleep 0.1; typ a; key $BS; enter
  expect bs2ab || { why="got: $(screen | grep -m1 '^bs2')"; return 1; }
}

sc_backspace_after_up() {
  fresh "$1" "$2" || return 1
  run 'print -r -- bs4abc'; expect bs4abc || return 1
  key $UP_CSI; sleep 0.1; key $BS; enter
  expect bs4ab || { why="got: $(screen | grep '^bs4' | tail -1)"; return 1; }
}

sc_up() {
  fresh "$1" "$2" || return 1
  run "print -r -- up-$3"; expect "up-$3" || return 1
  key $4; sleep 0.1; enter
  expect "up-$3" 2 || { why="previous command not recalled"; return 1; }
}

sc_up_after_esc() {
  fresh "$1" "$2" || return 1
  run 'print -r -- up-esc'; expect up-esc || return 1
  key $ESC; sleep 0.1; key $UP_CSI; sleep 0.1; enter
  expect up-esc 2 || { why="previous command not recalled"; return 1; }
}

sc_up_history_file() {
  start seed || return 1
  run 'print -r -- seed-from-last-session'; expect seed-from-last-session || return 1
  t kill-session -t seed
  start "$1" || return 1
  key $UP_CSI; sleep 0.1; enter
  expect seed-from-last-session || { why="last session's command not recalled"; return 1; }
}

sc_down() {
  fresh "$1" "$2" || return 1
  run "print -r -- dn1-$3"; expect "dn1-$3" || return 1
  run "print -r -- dn2-$3"; expect "dn2-$3" || return 1
  key $UP_CSI; sleep 0.1; key $UP_CSI; sleep 0.1; key $4; sleep 0.1; enter
  expect "dn2-$3" 2 && has "dn1-$3" && ! has "dn1-$3" 2 || { why="Down did not move to the newer entry"; return 1; }
}

sc_ctrl_k() {
  fresh "$1" "$2" || return 1
  run 'print -r -- ck1'; expect ck1 || return 1
  run 'echo ck-other'; expect ck-other || return 1
  typ print; key $CTRL_K; sleep 0.1; enter
  expect ck1 2 || { why="prefix search did not recall 'print -r -- ck1'"; return 1; }
}

sc_ctrl_j() {
  fresh "$1" "$2" || return 1
  run 'print -r -- cj1'; expect cj1 || return 1
  run 'print -r -- cj2'; expect cj2 || return 1
  run 'echo cj-other'; expect cj-other || return 1
  typ print; key $CTRL_K; sleep 0.1; key $CTRL_K; sleep 0.1; key $CTRL_J; sleep 0.1; enter
  expect cj2 2 && ! has cj1 2 || { why="^j did not move forward through prefix matches"; return 1; }
}

sc_enter() {
  fresh "$1" "$2" || return 1
  run 'print -r -- en$((6*7))'
  expect en42 || { why="command did not run"; return 1; }
}

sc_ctrl_c_clears() {
  fresh "$1" "$2" || return 1
  typ 'print -r -- cc1'; key $CTRL_C; sleep 0.1
  run 'print -r -- cc2'
  expect cc2 || { why="next command did not run"; return 1; }
  ! has cc1 || { why="cancelled line ran"; return 1; }
}

sc_patina_stalled() {
  fresh "$1" "$2" || return 1
  run 'print -r -- stall1'; expect stall1 || return 1
  pkill -STOP -x zsh-patina
  typ 'print -r -- stall2'; enter
  expect stall2 1 3000
  local ok=$?
  pkill -CONT -x zsh-patina
  (( ok == 0 )) || { why="line editor froze until the daemon resumed"; return 1; }
}

sc_tab_file() {
  fresh "$1" "$2" || return 1
  typ 'print -r -- ~/.zshe'; key $TAB; sleep 0.3; enter
  expect "$HOME/.zshenv" || { why="no completion"; return 1; }
}

sc_tab_compsys() {
  fresh "$1" "$2" || return 1
  typ 'tmux new-ses'; key $TAB
  until_ok 3000 eval 'screen | grep -q "tmux new-session"' || { why="no tmux subcommand completion"; return 1; }
  key $CTRL_C
}

sc_autosuggest() {
  fresh "$1" "$2" || return 1
  run 'print -r -- as-suggestion'; expect as-suggestion || return 1
  typ 'print -r -- as-s'
  until_ok 3000 eval '[[ $(last_prompt) == *"print -r -- as-suggestion" ]]' || { why="no suggestion shown"; return 1; }
  key $RIGHT; sleep 0.1; enter
  expect as-suggestion 2 || { why="suggestion not accepted with Right"; return 1; }
}

coloured_print() { t capture-pane -p -e -t "$S" | grep -qE $'\e\\[[0-9;:]*mprint'; }

sc_highlight() {
  fresh "$1" "$2" || return 1
  typ 'print -r -- hl'
  until_ok 3000 coloured_print || { why="command word not coloured"; return 1; }
  key $CTRL_C
}

sc_cursor_shape() {
  fresh "$1" "$2" || return 1
  local ins cmd
  typ x; sleep 0.2; ins=$(t display -p -t "$S" '#{cursor_shape}')
  key $ESC; sleep 0.6; cmd=$(t display -p -t "$S" '#{cursor_shape}')
  key $CTRL_C
  [[ $ins == bar && $cmd == block ]] || { why="insert=$ins normal=$cmd"; return 1; }
}

t new-session -d -s keep -- sleep infinity \; set -g default-terminal "${ZSH_TERM:-xterm-ghostty}"

echo "mode: $mode  TERM: ${ZSH_TERM:-xterm-ghostty}  zsh: $(zsh --version | cut -d' ' -f2)  tmux: $(tmux -V | cut -d' ' -f2)"
install_checks
[[ $mode == cold ]] && update_checks
startup_checks
check "startup: Ctrl-C at first prompt keeps cwd \$HOME" sc_ctrl_c_during_load ctrlc
check "startup: does not cd when started outside \$HOME" sc_start_elsewhere elsewhere
check "startup: without plugins the shell works and prints one hint, no network" sc_absent absent
check "nothing is written to ZDOTDIR; history and zcompdump go to \$XDG_CACHE_HOME/zsh" sc_zdotdir_untouched zdot
for when in immediate loaded; do
  check "backspace deletes [$when]" sc_backspace bs $when
  check "backspace after Esc then a [$when]" sc_backspace_after_esc_a bsesc $when
  check "backspace after Up recall [$when]" sc_backspace_after_up bsup $when
  check "Up CSI \\e[A recalls previous [$when]" sc_up upcsi $when csi "$UP_CSI"
  check "Up SS3 \\eOA recalls previous [$when]" sc_up upss3 $when ss3 "$UP_SS3"
  check "Up after Esc recalls previous [$when]" sc_up_after_esc upesc $when
  check "Down CSI \\e[B moves to newer [$when]" sc_down dncsi $when csi "$DOWN_CSI"
  check "Down SS3 \\eOB moves to newer [$when]" sc_down dnss3 $when ss3 "$DOWN_SS3"
  check "^k prefix search [$when]" sc_ctrl_k ck $when
  check "^j prefix search forward [$when]" sc_ctrl_j cj $when
  check "Enter runs command [$when]" sc_enter en $when
  check "Ctrl-C clears the line [$when]" sc_ctrl_c_clears cc $when
  check "focus in/out bytes keep insert mode and Backspace works [$when]" sc_focus_events fo $when
done
check "Up at first prompt recalls last session's command [immediate]" sc_up_history_file hist
check "Tab completes a file [loaded]" sc_tab_file tabf loaded
check "Tab completes tmux subcommand via compinit [loaded]" sc_tab_compsys tabc loaded
check "autosuggestion shown and accepted with Right [loaded]" sc_autosuggest as loaded
check "patina highlights the command word [loaded]" sc_highlight hl loaded
check_known "typing works while the patina daemon is stalled (SIGSTOP) [loaded]" sc_patina_stalled stall loaded
check "vi cursor is a bar in insert and a block in normal [loaded]" sc_cursor_shape cur loaded

for i in $(seq 100); do
  start burst$i
  t kill-session -t "burst$i"
done
total=$(( ${#starts[@]} + ${#blank[@]} ))
(( ${#blank[@]} == 0 )); report $(( ! $? )) "every start draws its prompt without a keypress" "${#blank[@]} of $total starts stayed blank until ^L: ${blank[*]}"
median=$(printf '%s\n' "${starts[@]}" | sort -n | sed -n "$(( (${#starts[@]} + 1) / 2 ))p")
echo "startup: first prompt after boot ${first_ms:-?} ms, median ${median} ms over ${#starts[@]} starts"
echo "result: $pass passed, $fail failed, $known known limitations"
t kill-server
(( fail == 0 ))
