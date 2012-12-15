#!/usr/bin/env bats

@test "calling the executable without params prints the help" {
  run rsvm
  [ ${lines[0]} = "Rust Version Manager" ]
  [ ${lines[2]} = "Usage:" ]
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}
