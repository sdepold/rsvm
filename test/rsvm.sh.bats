#!/usr/bin/env bats

source ./rsvm.sh

@test "'rsvm' prints the help" {
  run rsvm
  echo ${lines[0]}
  [ ${lines[0]} = "Rust Version Manager" ]
  [ ${lines[2]} = "Usage:" ]
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "'rsvm help' prints the help" {
  run rsvm help
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "'rsvm --help' prints the help" {
  run rsvm --help
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "'rsvm -h' prints the help" {
  run rsvm -h
  [ ${lines[3]} = "  rsvm help | --help | -h       Show this message." ]
}

@test "'rsvm install' prints a notice that no version was defined" {
  run rsvm install
  [ ${lines[2]} = "Please define a version of rust!" ]
}

@test "'rsvm install 0.1.1.1.1' prints a notice that the format is wrong" {
  run rsvm install 0.1.1.1.1
  [ ${lines[2]} = "You defined a version of rust in a wrong format!" ]
}

@test "'rsvm install v0.4' prints a notice that the format is wrong" {
  run rsvm install v0.4
  [ ${lines[2]} = "You defined a version of rust in a wrong format!" ]
}

@test "'rsvm install 1' prints a notice that the format is wrong" {
  run rsvm install 1
  [ ${lines[2]} = "You defined a version of rust in a wrong format!" ]
}

@test "'rsvm install 0.4' is not complaining" {
  run rsvm install 0.4 --dry
  [ ${lines[2]} = "Would install rust v0.4" ]
}

@test "'rsvm install 0.4.1' is not complaining" {
  run rsvm install 0.4.1 --dry
  [ ${lines[2]} = "Would install rust v0.4.1" ]
}
