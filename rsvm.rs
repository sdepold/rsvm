const VERSION: &static/str = "0.0.1";

fn main() {
    match os::args()[1] {
      ~"--version" | ~"-v" => {
        io::println(~"rsvm " + VERSION)
      }

      _ => {
        print_teaser()
      }
    }
}

fn print_teaser() {
    io::println("");
    io::println("Rust Version Manager");
    io::println("====================");
    io::println("");
}
