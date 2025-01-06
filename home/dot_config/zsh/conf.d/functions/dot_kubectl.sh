kpbn() {
  kubectl get pods --no-headers=true -o custom-columns=":metadata.name" | grep $@
}

kpbna() {
  kubectl get pods -A --no-headers=true -o custom-columns=":metadata.name" | grep $@
}
