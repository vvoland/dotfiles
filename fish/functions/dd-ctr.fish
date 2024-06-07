function dd-ctr
  docker run -it --rm -v /run/containerd/:/run/containerd/ docker:dind ctr -n moby  $argv; 
end
