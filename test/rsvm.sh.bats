#!/usr/bin/env bats

@test "calling the executable without params prints the help" {
  run ./rsvm.sh
  echo ${lines[0]}
  [ ${lines[0]} = "Rust Version Manager" ]
  [ ${lines[2]} = "Usage:" ]
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "calling the executable with the help param prints the help" {
  run ./rsvm.sh help
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "calling the executable with the --help param prints the help" {
  run ./rsvm.sh --help
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "calling the executable with the -h param prints the help" {
  run ./rsvm.sh -h
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "calling the executable with the install param prints a notice that no version was defined" {
  run ./rsvm.sh install
  [ ${lines[2]} = "Please define a version of rust!" ]
}
