function dctr --wraps='ctr -n moby -a /var/run/containerd/containerd.sock ' --wraps='sudo ctr -n moby -a /var/run/containerd/containerd.sock ' --description 'alias dctr=sudo ctr -n moby -a /var/run/containerd/containerd.sock '
  sudo ctr -n moby -a /var/run/containerd/containerd.sock  $argv
        
end
