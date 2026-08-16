
# Refresh cloud auth and export GOOGLE_* env vars into the current shell.
# Usage: workon <env>
workon() {
    source "${HOME}/bin/workon.sh" "$@"
}

# gssh () {
#   local instance_name=$(gcloud compute instances list | fzf | cut -d' ' -f1)
#   if [ ! -z "$instance_name" ]; then
#     eval "gcloud compute ssh --zone us-central1-a $instance_name"
#   fi

# }
