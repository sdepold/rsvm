#!/usr/bin/env bats

# load the rsvm
source ./rsvm.sh

# override the RSVM_DIR
export RSVM_DIR=`pwd`

cleanup()
{
  rm -rf `pwd`/v*
  rm -rf `pwd`/current
}

assert()
{
  echo "Expecting '$1' to equal '$2'"
  [ "$1" = "$2" ]
}

@test "'rsvm' prints the help" {
  run rsvm
  assert ${lines[0]} "Rust Version Manager"
  assert ${lines[2]} "Usage:"
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
}

@test "'rsvm help' prints the help" {
  run rsvm help
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
}

@test "'rsvm --help' prints the help" {
  run rsvm --help
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
}

@test "'rsvm -h' prints the help" {
  run rsvm -h
  assert ${lines[3]} "  rsvm help | --help | -h       Show this message."
}

@test "'rsvm install' prints a notice that no version was defined" {
  run rsvm install
  assert ${lines[2]} "Please define a version of rust!"
}

@test "'rsvm install 0.1.1.1.1' prints a notice that the format is wrong" {
  run rsvm install 0.1.1.1.1
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
}

@test "'rsvm install v0.4' prints a notice that the format is wrong" {
  run rsvm install v0.4
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
}

@test "'rsvm install 1' prints a notice that the format is wrong" {
  run rsvm install 1
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
}

@test "'rsvm install 0.4' is not complaining" {
  run rsvm install 0.4 --dry
  assert ${lines[2]} "Would install rust v0.4"
}

@test "'rsvm install 0.4.1' is not complaining" {
  run rsvm install 0.4.1 --dry
  assert ${lines[2]} "Would install rust v0.4.1"
}

@test "'rsvm ls' will return an empty list if no versions have been installed" {
  run rsvm ls
  assert ${lines[2]} "Installed versions:"
  assert ${lines[3]} "  -  None"
}

@test "'rsvm list' will return an empty list if no versions have been installed" {
  run rsvm list
  assert ${lines[2]} "Installed versions:"
  assert ${lines[3]} "  -  None"
}

@test "'rsvm ls' will return the installed versions" {
  run rsvm_init_folder_structure 0.1
  run rsvm_init_folder_structure 0.5

  run rsvm ls
  assert ${lines[2]} "Installed versions:"
  assert ${lines[3]} "  -   v0.1"
  assert ${lines[4]} "  -   v0.5"

  cleanup
}

@test "'rsvm use' will notify the user about missing version" {
  run rsvm use
  assert ${lines[2]} "Please define a version of rust!"
}

@test "'rsvm use' will notify the user about a malformed version" {
  run rsvm use 1.1.1.1.1
  assert ${lines[2]} "You defined a version of rust in a wrong format!"
}

@test "'rsvm use 0.1' will notify the user about a not installed version" {
  run rsvm use 0.1
  assert ${lines[3]} "You might want to install it with the following command:"
  assert ${lines[4]} "rsvm install 0.1"
}

@test "'rsvm use 0.1' will activate the right version" {
  run rsvm_init_folder_structure 0.1
  run rsvm use 0.1
  assert ${lines[2]} "Activating rust v0.1 ... done"
  cleanup
}
