#!/usr/bin/env bats

# load the rsvm
source ./rsvm.sh

# override the RSVM_DIR
export RSVM_DIR=`pwd`

function cleanup()
{
  rm -rf `pwd`/versions/0.*
  rm -rf `pwd`/versions/nightly*
  rm -rf `pwd`/current
}

@test "'rsvm' prints the help" {
  cleanup
  run rsvm
  [ "${lines[0]}" = "Rust Version Manager" ]
  [ "${lines[2]}" = "Usage:" ]
  [ "${lines[3]}" = "  rsvm help | --help | -h       Show this message." ]
  cleanup
}

@test "'rsvm help' prints the help" {
  cleanup
  run rsvm help
  [ "${lines[3]}" = "  rsvm help | --help | -h       Show this message." ]
  cleanup
}

@test "'rsvm --help' prints the help" {
  cleanup
  run rsvm --help
  [ "${lines[3]}" = "  rsvm help | --help | -h       Show this message." ]
  cleanup
}

@test "'rsvm -h' prints the help" {
  cleanup
  run rsvm -h
  [ "${lines[3]}" = "  rsvm help | --help | -h       Show this message." ]
  cleanup
}

@test "'rsvm install' prints a notice that no version was defined" {
  cleanup
  run rsvm install
  [ "${lines[0]}" = "Please define a version of rust!" ]
  cleanup
}

@test "'rsvm install 0.1.1.1.1' prints a notice that the format is wrong" {
  cleanup
  run rsvm install 0.1.1.1.1
  [ "${lines[0]}" = "You defined a version of rust in a wrong format!" ]
  cleanup
}

@test "'rsvm install v0.4' prints a notice that the format is wrong" {
  cleanup
  run rsvm install v0.4
  [ "${lines[0]}" = "You defined a version of rust in a wrong format!" ]
  cleanup
}

@test "'rsvm install 1' prints a notice that the format is wrong" {
  cleanup
  run rsvm install 1
  [ "${lines[0]}" = "You defined a version of rust in a wrong format!" ]
  cleanup
}

@test "'rsvm install 0.4' is not complaining" {
  cleanup
  run rsvm install 0.4 --dry
  [ "${lines[0]}" = "Would install rust 0.4" ]
  cleanup
}

@test "'rsvm install 0.4.1' is not complaining" {
  cleanup
  run rsvm install 0.4.1 --dry
  [ "${lines[0]}" = "Would install rust 0.4.1" ]
  cleanup
}

@test "'rsvm ls' will return an empty list if no versions have been installed" {
  cleanup
  run rsvm ls
  [ "${lines[0]}" = "Installed versions:" ]
  [ "${lines[1]}" = "  -  None" ]
  cleanup
}

@test "'rsvm list' will return an empty list if no versions have been installed" {
  cleanup
  run rsvm list
  [ "${lines[0]}" = "Installed versions:" ]
  [ "${lines[1]}" = "  -  None" ]
  cleanup
}

@test "'rsvm ls' will return the installed versions" {
  cleanup
  run rsvm_init_folder_structure 0.1
  run rsvm_init_folder_structure 0.5

  run rsvm ls
  [ "${lines[0]}" = "Installed versions:" ]
  [ "${lines[1]}" = "  -   0.1" ]
  [ "${lines[2]}" = "  -   0.5" ]

  cleanup
}

@test "'rsvm use' will notify the user about missing version" {
  cleanup
  run rsvm use
  [ "${lines[0]}" = "Please define a version of rust!" ]
  cleanup
}

@test "'rsvm use' will notify the user about a malformed version" {
  cleanup
  run rsvm use 1.1.1.1.1
  [ "${lines[0]}" = "You defined a version of rust in a wrong format!" ]
  cleanup
}

@test "'rsvm use 0.1' will notify the user about a not installed version" {
  cleanup
  run rsvm use 0.1
  [ "${lines[1]}" = "You might want to install it with the following command:" ]
  [ "${lines[2]}" = "rsvm install 0.1" ]
  cleanup
}

@test "'rsvm use 0.1' will activate the right version" {
  cleanup
  run rsvm_init_folder_structure 0.1
  run rsvm use 0.1
  [ "${lines[0]}" = "Activating rust 0.1 ... done" ]
  cleanup
}

@test "'rsvm use nightly' will activate the right version" {
  cleanup
  run rsvm_init_folder_structure nightly.1234
  run rsvm use nightly.1234
  [ "${lines[0]}" = "Activating rust nightly.1234 ... done" ]
  cleanup
}

@test "'rsvm install 0.5' will activate automatic" {
  cleanup
  # dry run not make directory
  run rsvm_init_folder_structure 0.5
  run rsvm install 0.5 --dry
  run rsvm ls
  [ "${lines[0]}" = "Installed versions:" ]
  [ "${lines[1]}" = "  =>  0.5" ]
  cleanup
}

@test "'rsvm uninstall 0.1' will notify the user about a not installed version" {
  cleanup
  run rsvm uninstall 0.1
  [ "${lines[0]}" = "0.1 version is not installed yet..." ]
  cleanup
}

@test "'rsvm uninstall 0.1' will notify the user about current using version" {
  cleanup
  run rsvm_init_folder_structure 0.1
  run rsvm use 0.1
  run rsvm uninstall 0.1
  [ "${lines[0]}" = "rsvm: Cannot uninstall currently-active version, 0.1" ]
  cleanup
}

function uninstall() {
  # FIXME: current bats not support stdin.
  echo "yes" | rsvm uninstall $1
}

@test "'rsvm uninstall 0.1' will remove installed version" {
  cleanup
  run rsvm_init_folder_structure 0.1
  uninstall 0.1
  run rsvm ls
  [ "${lines[0]}" = "Installed versions:" ]
  [ "${lines[1]}" = "  -  None" ]
  cleanup
}
