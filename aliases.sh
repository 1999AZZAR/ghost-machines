# Ghost Machine Connection Aliases
# Add these to your ~/.bashrc or ~/.zshrc

# Connect to any active ghost machine (targets the first one found)
alias start-ghost='docker exec -it $(docker ps --filter "name=ghost-machine" --format "{{.Names}}" | head -n 1) /bin/bash'

# Specifically target dual instances
alias start-ghost1='docker exec -it ghost-machine1 /bin/bash'
alias start-ghost2='docker exec -it ghost-machine2 /bin/bash'
