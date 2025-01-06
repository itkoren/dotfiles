function kpbn {
  kubectl get pods --no-headers=true -o custom-columns=":metadata.name" | grep $@
}

function kpbna {
  kubectl get pods -A --no-headers=true -o custom-columns=":metadata.name" | grep $@
}
