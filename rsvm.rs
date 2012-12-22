use core::*;

const VERSION: &static/str = "0.0.1";

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

fn get_rsvm_directory() -> ~str {
    os::homedir().unwrap().to_str() + "/.rsvm"
}

fn get_rsvm_version_directory(version: & str) -> ~str {
     get_rsvm_directory() + "/v" + version
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
    io::print(~"Creating the respective folders for rust v" + version + ~" ... ");
    run::run_program("mkdir", [~"-p", get_rsvm_version_directory(version) + "/src"]);
    run::run_program("mkdir", [~"-p", get_rsvm_version_directory(version) + "/dist"]);
    io::println("done");
}

fn install_version(version: & str) {
    create_folders_for_version(version);

    let compressed_src_path   = Path(get_rsvm_version_directory(version) + "/src/rust-" + version + ".tar.gz");
    let uncompressed_src_path = Path(get_rsvm_version_directory(version) + "/src/rust-" + version);

    if compressed_src_path.exists() {
        io::println(~"Sources for rust v" + version + ~" already downloaded ...");
    } else {
        io::print(~"Downloading sources for rust v" + version + ~" ... ");
        run::run_program("wget", [
            ~"-q", ~"http://dl.rust-lang.org/dist/rust-" + version + ".tar.gz",
            ~"-O", compressed_src_path.to_str()
        ]);
        io::println("done");
    }

    if uncompressed_src_path.exists() {
        io::println(~"Sources for rust v" + version + ~" already extracted ...");
    } else {
        io::print("Extracting sources ... ");
        run::run_program("tar", [
            ~"-C", get_rsvm_version_directory(version) + "/src",
            ~"-xzf", compressed_src_path.to_str()
        ]);
        io::println("done");
    }

    io::println("");
    io::println(~"Configuring rust v" + version + ~". This will take some time. Grep a beer in the meantime.");

    let mut output = run::program_output(uncompressed_src_path.to_str() + ~"/configure", [
        ~"--prefix=" + get_rsvm_version_directory(version) + ~"/dist",
        ~"--local-rust-root=" + get_rsvm_version_directory(version) + ~"/dist"
    ]);

    if output.status != 0 {
        io::println("Hmm, an error occurred ...");
        io::println(output.out);
        io::println(output.err);
        os::set_exit_status(output.status);
        return;
    }

    io::println("Still awake? Cool. Configuration is done.");

    io::println("");
    io::println(~"Building rust v" + version + ~". This will take even more time. See you later ... ");

    output = run::program_output("make", [
        ~"-C", uncompressed_src_path.to_str()
    ]);

    if output.status != 0 {
        io::println("Hmm, an error occurred while running 'make' ...");
        io::println(output.out);
        io::println(output.err);
        os::set_exit_status(output.status);
        return;
    }

    output = run::program_output("make", [ ~"-C", uncompressed_src_path.to_str(), ~"install" ]);

    if output.status != 0 {
        io::println("Hmm, an error occurred while running 'make install' ...");
        io::println(output.out);
        io::println(output.err);
        os::set_exit_status(output.status);
        return;
    }

    io::println("And we are done. Have fun using rust v$1.");
}
