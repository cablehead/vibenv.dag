# Create and publish the vibenv-launcher container
export def "create launcher" [] {
  print "Building vibenv-launcher container..."

  let dagger_cmd = r#'container |
  from debian:stable-slim |
  with-exec -- "apt" "update" |
  with-exec -- "apt" "install" "-y" "curl" "ca-certificates" "docker.io" "dtach" |
  with-exec -- "sh" "-c" "curl -fsSL https://dl.dagger.io/dagger/install.sh | BIN_DIR=/usr/local/bin sh" |

  # Install eget for downloading binaries
  with-workdir "/usr/local/bin" |
  with-exec -- "sh" "-c" "curl https://zyedidia.github.io/eget.sh | sh" |

  # Install nushell
  with-env-variable "EGET_BIN" "/usr/local/bin" |
  with-exec -- "eget" "nushell/nushell" "--asset" "musl" "--all" |

  # Copy this git repo into container
  with-directory "/workspace/vibenv" "." |

  # Cleanup
  with-exec -- "apt" "clean" |
  with-exec -- "rm" "-rf" "/var/lib/apt/lists/*" |

  # Set environment
  with-env-variable "_EXPERIMENTAL_DAGGER_RUNNER_HOST" "unix:///run/dagger/engine.sock" |
  with-workdir "/workspace/vibenv" |

  publish "localhost:5000/vibenv-launcher:latest"'#

  dagger -c $dagger_cmd

  print "Pulling vibenv-launcher from registry to host Docker..."
  docker pull localhost:5000/vibenv-launcher:latest

  print "✅ vibenv-launcher is ready!"
}

# Launch a persistent Docker container session
export def launch [name: string] {
  let container_name = $"vibenv-($name)"

  print $"Launching persistent session: ($container_name)"

  (docker run -d --init --name $container_name
    -v /var/run/docker.sock:/var/run/docker.sock
    -v /run/dagger:/run/dagger
    localhost:5000/vibenv-launcher:latest
    dtach -N /tmp/vibenv.sock nu -c $"use vibenv; vibenv remote-launch ($name)")

  print $"✅ Session started. Use 'vibenv attach ($name)' to connect"
}

# Attach to a persistent session
export def attach [name: string] {
  let container_name = $"vibenv-($name)"
  docker exec -it $container_name dtach -a /tmp/vibenv.sock
}

# Direct dagger execution (original behavior)
export def "remote-launch" [name: string] {
  cat vibenv.dag
  | str trim
  | append $" | with-mounted-cache /root/session ($name) | with-workdir "/root/session" | terminal --cmd=sh,-c,'stty sane; zellij -s ($name)'"
  | str join ""
  | dagger
}
