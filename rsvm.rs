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
        print_help();
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

pure fn is_number(c: u8) -> bool {
    c >= 48 && c <= 57
}

pure fn is_valid_version_format(s: & str) -> bool {
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
            install_version(version);
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

fn create_folders_for_version(version: & str) {
    io::println("Creating the respective folders for rust v$1 ... ");

    core::run::run_program("mkdir", [~"-p", ~"'$RSVM_DIR/v" + version + "/src'"]);
    core::run::run_program("mkdir", [~"-p", ~"'$RSVM_DIR/v" + version + "/dist'"]);

    io::println("done");
}

fn install_version(version: & str) {
    create_folders_for_version(version);

  //   current_dir=`pwd`

  // rsvm_init_folder_structure $1
  // cd "$RSVM_DIR/v$1/src"

  // if [ -f "rust-$1.tar.gz" ]
  // then
  //   echo "Sources for rust v$1 already downloaded ..."
  // else
  //   echo -n "Downloading sources for rust v$1 ... "
  //   wget -q "http://dl.rust-lang.org/dist/rust-$1.tar.gz"
  //   echo "done"
  // fi

  // if [ -e "rust-$1" ]
  // then
  //   echo "Sources for rust v$1 already extracted ..."
  // else
  //   echo -n "Extracting source ... "
  //   tar -xzf "rust-$1.tar.gz"
  //   echo "done"
  // fi

  // cd "rust-$1"

  // echo ""
  // echo "Configuring rust v$1. This will take some time. Grep a beer in the meantime."
  // echo ""

  // sleep 5

  // ./configure --prefix=$RSVM_DIR/v$1/dist --local-rust-root=$RSVM_DIR/v$1/dist

  // echo ""
  // echo "Still awake? Cool. Configuration is done."
  // echo ""
  // echo "Building rust v$1. This will take even more time. See you later ... "
  // echo ""

  // sleep 5

  // make && make install

  // echo ""
  // echo "And we are done. Have fun using rust v$1."

  // cd $current_dir
}
