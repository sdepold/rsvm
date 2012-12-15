# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

# Auto detect the NVM_DIR
if [ ! -d "$RSVM_DIR" ]; then
  export RSVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) && pwd)
fi

rsvm_install()
{
  current_dir=`pwd`

  echo -n "Creating the respective folders for rust v$1 ... "

  mkdir -p "$RSVM_DIR/v$1/src"
  mkdir -p "$RSVM_DIR/v$1/dist"

  echo "done"

  cd "$RSVM_DIR/v$1/src"

  if [ -f "rust-$1.tar.gz" ]
  then
    echo "Sources for rust v$1 already downloaded ..."
  else
    echo -n "Downloading sources for rust v$1 ... "
    wget -q "http://dl.rust-lang.org/dist/rust-$1.tar.gz"
    echo "done"
  fi

  if [ -e "rust-$1" ]
  then
    echo "Sources for rust v$1 already extracted ..."
  else
    echo -n "Extracting source ... "
    tar -xzf "rust-$1.tar.gz"
    echo "done"
  fi

  cd "rust-$1"

  echo ""
  echo "Configuring rust v$1. This will take some time. Grep a beer in the meantime."
  echo ""

  sleep 5

  ./configure --prefix=$RSVM_DIR/v$1/dist --local-rust-root=$RSVM_DIR/v$1/dist

  echo ""
  echo "Still awake? Cool. Configuration is done."
  echo ""
  echo "Building rust v$1. This will take even more time. See you later ... "
  echo ""

  sleep 5

  make && make install

  echo ""
  echo "And we are done. Have fun using rust v$1."

  cd $current_dir
}

rsvm()
{
  echo ''
  echo 'Rust Version Manager'
  echo '===================='
  echo ''

  # request for help or no parameter at all?
  # print the help
  if ([ -z "$1" ] || [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ])
  then
    echo 'Usage:'
    echo ''
    echo '  rsvm help | --help | -h       Show this message.'
    echo '  rsvm install <version>        Download and install a <version>. <version> could be for example "0.4".'
    echo '  rsvm uninstall <version>      Uninstall a <version>.'
    echo '  rsvm use <version>            Activate <version> for now and the future.'
    echo '  rsvm ls | list                List all installed versions of rust.'
  elif [ "$1" = "install" ]
  then
    if [ -z "$2" ]
    then
      # whoops. no version found!
      echo "Please define a version of rust!"
      echo ""
      echo "Example:"
      echo "  rsvm install 0.4"
    elif ([[ "$2" =~ ^[0-9]+\.[0-9]+\.?[0-9]*$ ]])
    then
      if [ "$3" = "--dry" ]
      then
        echo "Would install rust v$2"
      else
        rsvm_install "$2"
      fi
    else
      # the version was defined in a the wrong format.
      echo "You defined a version of rust in a wrong format!"
      echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
      echo ""
      echo "Example:"
      echo "  rsvm install 0.4"
    fi
  fi

  echo ''
}
