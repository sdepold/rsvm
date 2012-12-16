#!/usr/bin/env bats

# load the rsvm
source ./rsvm.sh

# override the RSVM_DIR
export RSVM_DIR=`pwd`

function cleanup()
{
  rm -rf `pwd`/v*
  rm -rf `pwd`/current
}

function assert()
{
  echo "Expecting '$1' to equal '$2'"
  [ "$1" = "$2" ]
}

@test "'rsvm' prints the help" {
  cleanup
  run rsvm
  assert ${lines[0]} "Rust Version Manager"
  assert ${lines[2]} "Usage:"
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
  cleanup
}

@test "'rsvm help' prints the help" {
  cleanup
  run rsvm help
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
  cleanup
}

@test "'rsvm --help' prints the help" {
  cleanup
  run rsvm --help
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
  cleanup
}

@test "'rsvm -h' prints the help" {
  cleanup
  run rsvm -h
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
  cleanup
}

@test "'rsvm install' prints a notice that no version was defined" {
  cleanup
  run rsvm install
  assert ${lines[2]} "Please define a version of rust!"
  cleanup
}

@test "'rsvm install 0.1.1.1.1' prints a notice that the format is wrong" {
  cleanup
  run rsvm install 0.1.1.1.1
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
  cleanup
}

@test "'rsvm install v0.4' prints a notice that the format is wrong" {
  cleanup
  run rsvm install v0.4
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
  cleanup
}

@test "'rsvm install 1' prints a notice that the format is wrong" {
  cleanup
  run rsvm install 1
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
  cleanup
}

@test "'rsvm install 0.4' is not complaining" {
  cleanup
  run rsvm install 0.4 --dry
  assert ${lines[2]} "Would install rust v0.4"
  cleanup
}

@test "'rsvm install 0.4.1' is not complaining" {
  cleanup
  run rsvm install 0.4.1 --dry
  assert ${lines[2]} "Would install rust v0.4.1"
  cleanup
}

@test "'rsvm ls' will return an empty list if no versions have been installed" {
  cleanup
  run rsvm ls
  assert ${lines[2]} "Installed versions:"
  assert ${lines[3]} "  -  None"
  cleanup
}

@test "'rsvm list' will return an empty list if no versions have been installed" {
  cleanup
  run rsvm list
  assert ${lines[2]} "Installed versions:"
  assert ${lines[3]} "  -  None"
  cleanup
}

@test "'rsvm ls' will return the installed versions" {
  cleanup
  run rsvm_init_folder_structure 0.1
  run rsvm_init_folder_structure 0.5

  run rsvm ls
  assert ${lines[2]} "Installed versions:"
  assert ${lines[3]} "  -   v0.1"
  assert ${lines[4]} "  -   v0.5"

  cleanup
}

@test "'rsvm use' will notify the user about missing version" {
  cleanup
  run rsvm use
  assert ${lines[2]} "Please define a version of rust!"
  cleanup
}

@test "'rsvm use' will notify the user about a malformed version" {
  cleanup
  run rsvm use 1.1.1.1.1
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
  cleanup
}

@test "'rsvm use 0.1' will notify the user about a not installed version" {
  cleanup
  run rsvm use 0.1
  assert ${lines[3]} "You might want to install it with the following command:"
  assert ${lines[4]} "rsvm install 0.1"
  cleanup
}

@test "'rsvm use 0.1' will activate the right version" {
  cleanup
  run rsvm_init_folder_structure 0.1
  run rsvm use 0.1
  assert ${lines[2]} "Activating rust v0.1 ... done"
  cleanup
}
