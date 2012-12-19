const VERSION: &static/str = "0.0.1";

use core::*;

fn main() {
    let command: ~str = if os::args().len() == 1 { ~"" } else { copy os::args()[1] };

    match command {
      ~"--version" | ~"-v" => {
        io::println(~"rsvm " + VERSION);
      }

      ~"i" | ~"install" => {
        install();
      }

      ~"ls" | ~"list" => {

      }

      ~"u" | ~"use" => {

      }

      _ => {
        print_help()
      }
    }
}

fn print_teaser() {
    io::println("");
    io::println("Rust Version Manager");
    io::println("====================");
    io::println("");
}

fn print_help() {
    print_teaser();

    io::println("Usage:");
    io::println("");
    io::println("  rsvm help | --help | -h       Show this message.");
    io::println("  rsvm install <version>        Download and install a <version>. <version> could be for example '0.4'.");
    // echo '  rsvm uninstall <version>      Uninstall a <version>.'
    io::println("  rsvm use <version>            Activate <version> for now and the future.");
    io::println("  rsvm ls | list                List all installed versions of rust.");
    io::println("");
    io::println(~"Current version: " + VERSION);
    io::println("");
}

fn is_number(c: u8) -> bool {
    c >= 48 && c <= 57
}

fn is_valid_version_format(s: & str) -> bool {
    if s.len() == 3 {
        is_number(s[0]) && s[1] == 46 && is_number(s[2])
    } else if s.len() == 5 {
        is_number(s[0]) && s[1] == 46 && is_number(s[2]) && s[3] == 46 && is_number(s[4])
    } else {
        false
    }
}

fn install() {
    let version: ~str = if os::args().len() == 2 {
        ~""
    } else {
        copy os::args()[2]
    };

    print_teaser();

    if version == ~"" {
        io::println("Please define a version of rust!");
        io::println("");
        io::println("Example:");
        io::println("  rsvm install 0.4");
    } else if is_valid_version_format(version) {
        if os::args().len() == 4 && os::args()[3] == ~"--dry" {
            io::println(~"Would install rust v" + version);
        } else {
            // install
        }
    } else {
        io::println("You defined a version of rust in a wrong format!");
        io::println("Please use either <major>.<minor> or <major>.<minor>.<patch>.");
        io::println("");
        io::println("Example:");
        io::println("  rsvm install 0.4");
    }

    io::println("");
}
