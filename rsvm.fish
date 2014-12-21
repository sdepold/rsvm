# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

set RSVM_VERSION "0.1.1"

if not test -d "$RSVM_DIR"
  set RSVM_DIR (dirname $argv[1])
end

if [ -e "$RSVM_DIR/current/dist/bin" ]
  if not contains $RSVM_DIR/current/dist/bin $PATH
      set -x PATH $RSVM_DIR/current/dist/bin $PATH
  end
  if not contains $RSVM_DIR/current/dist/lib $LD_LIBRARY_PATH
      set -x LD_LIBRARY_PATH $RSVM_DIR/current/dist/lib $LD_LIBRARY_PATH
  end
end

function rsvm_use
  set -l v "$argv[1]"
  if test -e "$RSVM_DIR/$v"
    echo -n "Activating rust $v ... "

    rm -rf $RSVM_DIR/current
    ln -s $RSVM_DIR/$v $RSVM_DIR/current
    source $RSVM_DIR/rsvm.fish

    echo "done"
  else
    echo "The specified version $v of rust is not installed..."
    echo "You might want to install it with the following command:"
    echo ""
    echo "rsvm install $v"
  end
end

function rsvm_current
  echo (readlink $RSVM_DIR/current|tr "/" "\n" | tail -n 1)
end

function rsvm_ls
  set -l directories (find $RSVM_DIR -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \;|egrep "^(nightly\.[0-9]+|v[0-9]+\.[0-9]+\.?[0-9]*)"|sort)

  echo "Installed versions:"
  echo ""

  if [ (echo "$directories" | grep -o "v" | wc -l) = 0 ]
    echo '  -  None';
  else
    set -l curr (rsvm_current)
    for line in (echo $directories | tr " " "\n")
      if [ "$curr" = "$line" ]
        echo "  =>  $line"
      else
        echo "  -   $line"
      end
    end
  end
end

function rsvm_init_folder_structure
  set -l v $argv[1]
  echo -n "Creating the respective folders for rust $v ... "

  mkdir -p "$RSVM_DIR/$v/src"
  mkdir -p "$RSVM_DIR/$v/dist"

  echo "done"
end

function rsvm_install_nightly
  set -l current_dir (pwd)
  set -l current (date "+%Y%m%d%H%M%S")
  set -l v nightly.$current

  rsvm_init_folder_structure $v

  curl https://static.rust-lang.org/rustup.sh | bash -s -- --prefix="$RSVM_DIR/$v/dist"

  echo ""
  echo "And we are done. Have fun using rust $v."
end

function rsvm_install
  set -l current_dir (pwd)
  set -l v $argv[1]

  rsvm_init_folder_structure v$v
  cd "$RSVM_DIR/v$v/src"

  set -l arch (uname -m)

  switch (uname)
    case Linux
      set platform $arch-unknown-linux-gnu
  end

  if test -f "rust-$v-$platform.tar.gz"
    echo "Sources for rust v$v already downloaded ..."
  else
    echo -n "Downloading sources for rust v$v ... "
    curl -s -o "rust-$v-$platform.tar.gz" "https://static.rust-lang.org/dist/rust-$v-$platform.tar.gz"
    echo "done"
  end

  if test -e "rust-$v"
    echo "Sources for rust v$v already extracted ..."
  else
    echo -n "Extracting source ... "
    tar -xzf "rust-$v-$platform.tar.gz"
    mv "rust-$v-$platform" "rust-$v"
    echo "done"
  end

  cd "rust-$v"
  sh install.sh --prefix=$RSVM_DIR/v$v/dist

  if not test -f $RSVM_DIR/v$v/dist/bin/cargo
    cd "$RSVM_DIR/v$v/src"
    echo -n "Downloading sources for cargo nightly ... "
    curl -s -o "cargo-nightly-$platform.tar.gz" "https://static.rust-lang.org/cargo-dist/cargo-nightly-$platform.tar.gz"
    echo "done"

    echo -n "Extracting source ... "
    tar -xzf "cargo-nightly-$platform.tar.gz"
    mv "cargo-nightly-x86_64-unknown-linux-gnu" "cargo-nightly"
    echo "done"

    cd "cargo-nightly"
    sh install.sh --prefix=$RSVM_DIR/v$v/dist
  end

  echo ""
  echo "And we are done. Have fun using rust v$v."

  cd $current_dir
end

function rsvm_uninstall
  set -l current_dir (pwd)
  set -l v $argv[1]
  if [ $v = (rsvm_current) ]
    echo "rsvm: Cannot uninstall currently-active version, $v."
    return
  end
  if not test -d "$RSVM_DIR/$v"
    echo "$v version is not installed yet... "
    return
  end
  echo "uninstall $v ..."
  rm -rI "$RSVM_DIR/$v"
end

function rsvm
  switch "$argv[1]"
    case "help" "--help" "-h" ""
      echo ''
      echo 'Rust Version Manager'
      echo '===================='
      echo ''
      echo 'Usage:'
      echo ''
      echo '  rsvm help | --help | -h       Show this message.'
      echo '  rsvm install <version>        Download and install a <version>. <version> could be for example "0.11.0".'
      echo '  rsvm uninstall <version>      Uninstall a <version>.'
      echo '  rsvm use <version>            Activate <version> for now and the future.'
      echo '  rsvm ls | list                List all installed versions of rust.'
      echo ''
      echo "Current version: $RSVM_VERSION"
    case "version" "--version" "-v"
      echo "v$RSVM_VERSION"
    case "install" "ins"
      [ (count $argv) -ne 2 ]; and rsvm help; and return
      set -l v $argv[2]
      #set -l opt $argv[3]
      if [ "$v" = "nightly" ]
        rsvm_install_nightly
      else if test -z (echo "$v" | sed -r 's/0\.(8\.[0-9]+|[0-9]+\.[0-9]+)//g')
        rsvm_install "$v"
      else if test -z (echo "$v" | sed -r 's/v0\.(8\.[0-9]+|[0-9]+\.[0-9]+)//g')
        rsvm_install (echo "$v" | sed -r 's/^v//g')
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm install 0.11.0"
      end
    case "uninstall" "rm"
      [ (count $argv) -ne 2 ]; and rsvm help; and return
      set -l v $argv[2]
      rsvm_uninstall "$v"
    case "ls" "list"
      rsvm_ls
    case use
      [ (count $argv) -ne 2 ]; and rsvm help; and return
      set -l v $argv[2]
      if test -z (echo "$v" | sed -r 's/0\.(8\.[0-9]+|[0-9]+\.[0-9]+)//g')
        rsvm_use "v$v"
      else if test -z (echo "$v" | sed -r 's/v0\.(8\.[0-9]+|[0-9]+\.[0-9]+)//g')
        rsvm_use "$v"
      else if test -z (echo "$v" | sed -r 's/nightly\.[0-9]+//g')
        rsvm_use "$v"
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm use 0.11.0"
      end
  end
  echo ''
end
