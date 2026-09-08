#!/bin/sh
# System-level setup for Linux servers that run AI agents (Claude Code, Codex).
# Needs sudo. Safe to re-run.
#
# 1. sysstat  - system-wide history (sar): when did memory/swap fill up
# 2. atop     - per-process history: which process ate the memory
# 3. earlyoom - kill the biggest process before the machine starts thrashing
# 4. sshd     - keep sshd out of the OOM killer and ahead of the swap queue
# 5. agents.slice - memory cap for everything started via the `claude`/`codex`
#                   zsh wrappers (see zsh/zshrc), as a share of physical RAM

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "Linux only, nothing to do."
    exit 0
fi

echo "=== Installing packages ==="
sudo apt-get update -qq
sudo apt-get install -y -qq sysstat atop earlyoom

echo ""
echo "=== sysstat ==="
sudo sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat
sudo systemctl enable --now sysstat >/dev/null

echo ""
echo "=== atop (60s samples) ==="
sudo sed -i 's/^LOGINTERVAL=.*/LOGINTERVAL=60/' /etc/default/atop
sudo systemctl enable atop >/dev/null
sudo systemctl restart atop

echo ""
echo "=== earlyoom ==="
# Fire when both free RAM < 5% and free swap < 10%.
# Prefer killing agent workloads; avoid the things needed to get back in.
sudo tee /etc/default/earlyoom >/dev/null <<'CONF'
EARLYOOM_ARGS="-m 5 -s 10 --prefer '^(lean|lake|node|python[0-9.]*|claude|codex)$' --avoid '^(sshd|systemd.*|tmux.*|zsh|atop|sadc)$'"
CONF
sudo systemctl enable earlyoom >/dev/null
sudo systemctl restart earlyoom

echo ""
echo "=== sshd protection ==="
SSH_UNIT=ssh
systemctl list-unit-files ssh.service --no-legend 2>/dev/null | grep -q . || SSH_UNIT=sshd
sudo mkdir -p /etc/systemd/system/$SSH_UNIT.service.d
sudo tee /etc/systemd/system/$SSH_UNIT.service.d/override.conf >/dev/null <<'CONF'
[Service]
# Never picked by the OOM killer
OOMScoreAdjust=-1000
# Keep this much resident even under memory pressure
MemoryLow=256M
# Win CPU contention against user workloads (default weight is 100)
CPUWeight=1000
CONF
sudo systemctl daemon-reload
sudo systemctl restart $SSH_UNIT

echo ""
echo "=== swappiness ==="
# Prefer dropping page cache over swapping out processes.
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-agents.conf >/dev/null
sudo sysctl -q -p /etc/sysctl.d/99-agents.conf

echo ""
echo "=== agents.slice (user cgroup for claude/codex) ==="
# Percentages are of physical RAM, recomputed by systemd on every boot.
# MemoryHigh throttles, MemoryMax kills the biggest process inside the slice.
systemctl --user set-property agents.slice MemoryHigh=70% MemoryMax=80% MemorySwapMax=0

echo ""
echo "=== Status ==="
for u in sysstat-collect.timer atop earlyoom $SSH_UNIT; do
    printf '%-24s %s\n' "$u" "$(systemctl is-active $u)"
done
printf '%-24s %s\n' "swappiness" "$(sysctl -n vm.swappiness)"
systemctl --user show agents.slice -p MemoryHigh -p MemoryMax -p MemorySwapMax | sed 's/^/agents.slice /'
echo ""
echo "✅ Done. Open a new shell so the claude/codex wrappers take effect."
