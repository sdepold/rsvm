# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

RSVM_VERSION="0.1.0"

# Auto detect the NVM_DIR
if [ ! -d "$RSVM_DIR" ]
then
  export RSVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) && pwd)
fi

if [ -e "$RSVM_DIR/current/dist/bin" ]
then
  PATH=$RSVM_DIR/current/dist/bin:$PATH
fi

rsvm_use()
{
  if [ -e "$RSVM_DIR/$1" ]
  then
    echo -n "Activating rust $1 ... "

    rm -rf $RSVM_DIR/current
    ln -s $RSVM_DIR/$1 $RSVM_DIR/current
    source $RSVM_DIR/rsvm.sh

    echo "done"
  else
    echo "The specified version $1 of rust is not installed..."
    echo "You might want to install it with the following command:"
    echo ""
    echo "rsvm install $1"
  fi
}

rsvm_current()
{
  target=`echo echo $(readlink .rsvm/current)|tr "/" "\n"`
  echo ${target[@]} | awk '{print$NF}'
}

rsvm_ls()
{
  directories=`find $RSVM_DIR -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \;|egrep "^(nightly\.[0-9]+|v[0-9]+\.[0-9]+\.?[0-9]*)"|sort`

  echo "Installed versions:"
  echo ""

  if [ `grep -o "v" <<< "$directories" | wc -l` = 0 ]
  then
    echo '  -  None';
  else
    for line in $(echo $directories | tr " " "\n")
    do
      if [ `rsvm_current` = "$line" ]
      then
        echo "  =>  $line"
      else
        echo "  -   $line"
      fi
    done
  fi
}

rsvm_init_folder_structure()
{
  echo -n "Creating the respective folders for rust $1 ... "

  mkdir -p "$RSVM_DIR/$1/src"
  mkdir -p "$RSVM_DIR/$1/dist"

  echo "done"
}

rsvm_install_nightly() {
  current_dir=`pwd`
  current=`date "+%Y%m%d%H%M%S"`
  v=nightly.$current

  rsvm_init_folder_structure $v

  curl https://static.rust-lang.org/rustup.sh | bash -s -- --prefix="$RSVM_DIR/$v/dist"

  echo ""
  echo "And we are done. Have fun using rust $v."
}

rsvm_install()
{
  current_dir=`pwd`

  rsvm_init_folder_structure v$1
  cd "$RSVM_DIR/v$1/src"

  arch=`uname -m`
  ostype=`uname`
  if [ "$ostype" = "Linux" ]
  then
    platform=$arch-unknown-linux-gnu
  fi

  if [ -f "rust-$1-$platform.tar.gz" ]
  then
    echo "Sources for rust v$1 already downloaded ..."
  else
    echo -n "Downloading sources for rust v$1 ... "
    curl -s -o "rust-$1-$platform.tar.gz" "https://static.rust-lang.org/dist/rust-$1-$platform.tar.gz"
    echo "done"
  fi

  if [ -e "rust-$1" ]
  then
    echo "Sources for rust v$1 already extracted ..."
  else
    echo -n "Extracting source ... "
    tar -xzf "rust-$1-$platform.tar.gz"
    mv "rust-$1-$platform" "rust-$1"
    echo "done"
  fi

  cd "rust-$1"

  sh install.sh --prefix=$RSVM_DIR/v$1/dist

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

  case $1 in
    ""|help|--help|-h)
      echo 'Usage:'
      echo ''
      echo '  rsvm help | --help | -h       Show this message.'
      echo '  rsvm install <version>        Download and install a <version>. <version> could be for example "0.4".'
      # echo '  rsvm uninstall <version>      Uninstall a <version>.'
      echo '  rsvm use <version>            Activate <version> for now and the future.'
      echo '  rsvm ls | list                List all installed versions of rust.'
      echo ''
      echo "Current version: $RSVM_VERSION"
      ;;
    --version|-v)
      echo "v$RSVM_VERSION"
      ;;
    install)
      if [ -z "$2" ]
      then
        # whoops. no version found!
        echo "Please define a version of rust!"
        echo ""
        echo "Example:"
        echo "  rsvm install 0.4"
      elif [ "$2" = "nightly" ]
      then
        rsvm_install_nightly
      elif ([[ "$2" =~ ^[0-9]+\.[0-9]+\.?[0-9]*$ ]])
      then
        rsvm_install "$2"
      elif ([[ "$2" =~ ^v[0-9]+\.[0-9]+\.?[0-9]*$ ]])
      then
        rsvm_install `echo "$2" | sed -r 's/^v//g'`
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm install 0.4"
      fi
      ;;
    ls|list)
      rsvm_ls
      ;;
    use)
      if [ -z "$2" ]
      then
        # whoops. no version found!
        echo "Please define a version of rust!"
        echo ""
        echo "Example:"
        echo "  rsvm use 0.4"
      elif ([[ "$2" =~ ^[0-9]+\.[0-9]+\.?[0-9]*$ ]])
      then
        rsvm_use "v$2"
      elif ([[ "$2" =~ ^(nightly\.[0-9]+|v[0-9]+\.[0-9]+\.?[0-9]*)$ ]])
      then
        rsvm_use "$2"
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm use 0.4"
      fi
      ;;
  esac

  echo ''
}
