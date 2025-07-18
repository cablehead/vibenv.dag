export def launch [name: string] {
  cat vibenv.dag
  | str trim
  | append $" | with-mounted-cache /root/session ($name) | with-workdir "/root/session" | terminal --cmd=sh,-c,'stty sane; zellij -s ($name)'"
  | str join ""
  | dagger
}
