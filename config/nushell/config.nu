
$env.config.edit_mode = 'vi'

$env.config.table.header_on_separator = true
$env.config.table.trim = {
  methodology: "truncating"
  truncating_suffix: "..."
}
$env.config.table.abbreviated_row_count = 40
$env.config.table.show_empty = false
$env.config.table.mode = "compact"

$env.config.keybindings = $env.config.keybindings | append {
  name: open_command_editor
  modifier: control
  keycode: char_v
  mode: [vi_normal]
  event: {send: openeditor}
}

## PROMPT
def abrv [] {
  let s = $in
  if ($s | str length) <= 8 {
    return $s
  }
  let first_part = $s | str substring 0..2
  let length = $s | str length
  let last_part = $s | str substring ($length - 3)..$length
  $first_part + ".." + $last_part
}

$env.PROMPT_COMMAND_RIGHT = {|| "" }

$env.PROMPT_COMMAND = {||
  let home =  $nu.home-path

  let dir = (
    if ($env.PWD | path split | zip ($home | path split) | all { $in.0 == $in.1 }) {
      ($env.PWD | str replace $home "~")
    } else {
      $env.PWD
    }
  )

  let parts = $dir | path split
  let parts = $parts | first (($parts | length) - 1) | each { abrv } | append ($parts | last)
  let dir = $parts | path join

  let path_color = (if (is-admin) { ansi red_bold } else { ansi default })
  $"($path_color)($dir)"
}

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| " > " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| " $ " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| " = " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "   " }
## END PROMPT

use std-rfc/kv *

alias ept = each {|x| print ($x | table -e) }
