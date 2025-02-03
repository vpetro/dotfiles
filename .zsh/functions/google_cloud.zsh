
gssh () {
  local instance_name=$(gcloud compute instances list | fzf | cut -d' ' -f1)
  if [ ! -z "$instance_name" ]; then
    eval "gcloud compute ssh --zone us-central1-a $instance_name"
  fi

}
