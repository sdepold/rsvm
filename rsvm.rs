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
        list();
      }

      ~"u" | ~"use" => {
        use_version();
      }

      _ => {
        help();
      }
    }
}

/////////////
// actions //
/////////////

fn help() {
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

fn list() {
    let dirs = os::list_dir(& get_path_to("root", None));
    let mut versions: ~[~str] = ~[];

    for dirs.each |&path| {
        if str::char_at(path, 0) == 'v' {
            versions.push(str::replace(path, "v", ""));
        }
    }

    print_teaser();

    io::println("Installed versions:");
    io::println("");

    if versions.len() == 0 {
        io::println("  -  None");
    } else {
        for versions.each |&version| {
            if version == get_active_version() {
                io::print(~"  => ");
            } else {
                io::print(~"  -  ");
            }

            io::println(~"v" + version);
        }
    }

    io::println("");
}

fn use_version() {
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
        io::println("  rsvm use 0.4");
    } else if is_valid_version_format(version) {
        io::print(~"Activating rust v" + version + ~" ... ");

        if version_exists(version) {
            activate_version(version);
            io::println("done");
        } else {
            io::println(~"failed. Version v" + version + ~" is not installed.");
        }
    } else {
        io::println("You defined a version of rust in a wrong format!");
        io::println("Please use either <major>.<minor> or <major>.<minor>.<patch>.");
        io::println("");
        io::println("Example:");
        io::println("  rsvm use 0.4");
    }

    io::println("");
}

/////////////
// helpers //
/////////////

fn create_folders_for_version(version: & str) {
    io::print(~"Creating the respective folders for rust v" + version + ~" ........ ");
    run::run_program("mkdir", [~"-p", get_path_to("src_dir", Some(version)).to_str()]);
    run::run_program("mkdir", [~"-p", get_path_to("dist_dir", Some(version)).to_str()]);
    io::println("done");
}

fn install_version(version: & str) {
    let current_dir = os::getcwd();

    create_folders_for_version(version);

    io::print(~"Downloading sources for rust v" + version + ~" .................... ");

    if get_path_to("rust_src_archive", Some(version)).exists() {
        io::println(~"already done");
    } else {
        run::run_program("wget", [
            ~"-q",  ~"http://dl.rust-lang.org/dist/rust-" + version + ~".tar.gz",
            ~"-O", get_path_to("rust_src_archive", Some(version)).to_str()
        ]);
        io::println("done");
    }

    io::print("Extracting sources ................................... ");

    if get_path_to("rust_src_dir", Some(version)).exists() {
        io::println(~"already done");
    } else {
        run::run_program("tar", [
            ~"-C", get_path_to("src_dir", Some(version)).to_str(),
            ~"-xzf", get_path_to("rust_src_archive", Some(version)).to_str()
        ]);
        io::println("done");
    }

    io::print(~"Configuring rust v" + version + ~" (might take a minute or two) ... ");

    os::change_dir(& get_path_to("rust_src_dir", Some(version)));

    let mut output = run::program_output(
        ~"./configure",
        [
            ~"--prefix=" + get_path_to("dist_dir", Some(version)).to_str(),
            ~"--local-rust-root=" + get_path_to("dist_dir", Some(version)).to_str()
        ]
    );

    if output.status != 0 {
        io::println("failed");
        io::println(output.out);
        io::println(output.err);
        os::set_exit_status(output.status);
        return;
    }

    io::println("done");

    io::print(~"Building rust v" + version + ~" (can take up to an hour) .......... ");

    output = run::program_output("make", []);

    if output.status != 0 {
        io::println("failed (make)");
        io::println(output.out);
        io::println(output.err);
        os::set_exit_status(output.status);
        return;
    }

    output = run::program_output("make", [ ~"install" ]);

    if output.status != 0 {
        io::println("failed (make install)");
        io::println(output.out);
        io::println(output.err);
        os::set_exit_status(output.status);
        return;
    }

    io::println("done");

    os::change_dir(&current_dir);
}

fn activate_version(version: & str) {

}

fn get_active_version() -> ~str {
    let output = run::program_output("readlink", [ get_path_to("current", None).to_str() ]);
    let path   = str::trim(output.out);

    str::replace(path, get_path_to("root", None).to_str() + ~"/v", "")
}

fn version_exists(version: &str) -> bool {
    get_path_to("version", Some(version)).exists()
}

fn print_teaser() {
    io::println("");
    io::println("Rust Version Manager");
    io::println("====================");
    io::println("");
}

pure fn is_number(c: u8) -> bool {
    c >= 48 && c <= 57
}

// use std::unicode::is_digit
pure fn is_valid_version_format(s: & str) -> bool {
    if s.len() == 3 {
        is_number(s[0]) && s[1] == 46 && is_number(s[2])
    } else if s.len() == 5 {
        is_number(s[0]) && s[1] == 46 && is_number(s[2]) && s[3] == 46 && is_number(s[4])
    } else {
        false
    }
}

fn get_path_to(target: & str, opt: Option<&str>) -> Path {
    let path: ~str = match target {
      "root" => {
        os::homedir().unwrap().to_str() + "/.rsvm"
      }

      "version" => {
        get_path_to(~"root", None).to_str() + ~"/v" + opt.unwrap()
      }

      "rust_src_archive" => {
        get_path_to("src_dir", opt).to_str() + "/rust-" + opt.unwrap() + ".tar.gz"
      }

      "rust_src_dir" => {
        get_path_to("src_dir", opt).to_str() + "/rust-" + opt.unwrap()
      }

      "src_dir" => {
        get_path_to("version", opt).to_str() + "/src"
      }

      "dist_dir" => {
        get_path_to("version", opt).to_str() + "/dist"
      }

      "current" => {
        get_path_to("root", None).to_str() + ~"/current"
      }

      _ => {
        io::println(~"Unknown option '" + target + "' ...");
        get_path_to("root", None).to_str()
      }
    };

    Path(path)
}
