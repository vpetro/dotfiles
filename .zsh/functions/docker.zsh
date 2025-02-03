de() {
  local container_name=$(docker ps --format '{{.Names}}' | fzf)
  if [ ! -z "$container_name" ]; then
    local command="$1"
    eval "docker exec -it $container_name $command"
  fi
}
