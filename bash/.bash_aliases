# OS
# alias z='zoxide'
alias vim='nvim'

# Tmux
alias tma='tmux attach-session -t'
alias tmls='tmux ls'

# Task
alias t='task'
alias tl='task --list-all'

# GitOps
alias k='kubectl'
alias fgk='flux get kustomizations'
alias kga='kubectl get all'
alias kd='kubectl describe'
alias kgpw='kubectl get pods --watch'
alias kdd='kubectl delete'
alias kl='kubectl logs'
alias gllf='git log -1 --oneline && flux get kustomizations'
alias kggs='kubectl config current-context'
alias kfr='k get all -o name | fzf'
alias kfpd='k describe $(k get pods -o name | fzf)'
alias kprune='kubectl get rs -A -o wide | tail -n +2 | awk '"'"'{if ($3 + $4 + $5 == 0) print "kubectl delete rs -n "$1, $2 }'"'"' | sh'

# Git Aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gll='git log -1 --oneline'
alias nvimdiff='nvim -c ":DiffviewOpen"'
