# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

RSVM_VERSION="0.1.0"
RSVM_VERSION_PATTERN="((nightly(\.[0-9]+)?|[0-9]+\.[0-9]+(\.[0-9]+)?)(-(alpha|beta)(\.[0-9]*)?)?)"

# Auto detect the NVM_DIR
if [ ! -d "$RSVM_DIR" ]
then
  export RSVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) && pwd)
fi

rsvm_append_path()
{
  local newpath
  if [[ ":$1:" != *":$2:"* ]];
  then
    newpath="${1:+"$1:"}$2"
  else
    newpath="$1"
  fi
  echo $newpath
}

export PATH=$(rsvm_append_path $PATH $RSVM_DIR/current/dist/bin)
export LD_LIBRARY_PATH=$(rsvm_append_path $LD_LIBRARY_PATH $RSVM_DIR/current/dist/lib)
export DYLD_LIBRARY_PATH=$(rsvm_append_path $DYLD_LIBRARY_PATH $RSVM_DIR/current/dist/lib)
export MANPATH=$(rsvm_append_path $MANPATH $RSVM_DIR/current/dist/share/man)

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
  if [ ! -e $RSVM_DIR/current ]
  then
    echo "N/A"
    return
  fi
  target=`echo $(readlink $RSVM_DIR/current)|tr "/" "\n"`
  echo ${target[@]} | awk '{print$NF}'
}

rsvm_ls()
{
  DIRECTORIES=$(find $RSVM_DIR -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; \
    | sort \
    | egrep "^$RSVM_VERSION_PATTERN")

  echo "Installed versions:"
  echo ""

  if [ $(egrep -o "^$RSVM_VERSION_PATTERN" <<< "$DIRECTORIES" | wc -l) = 0 ]
  then
    echo '  -  None';
  else
    for line in $(echo $DIRECTORIES | tr " " "\n")
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

rsvm_install()
{
  local CURRENT_DIR=`pwd`
  local version


  if [[ $1 = "nightly" ]]
  then
    version=nightly.`date "+%Y%m%d%H%M%S"`
  else
    version=$1
  fi
  rsvm_init_folder_structure $version
  local SRC="$RSVM_DIR/$version/src"
  local DIST="$RSVM_DIR/$version/dist"

  cd $SRC

  local ARCH=`uname -m`
  local OSTYPE=`uname -s`
  case $OSTYPE in
    Linux)
      PLATFORM=$ARCH-unknown-linux-gnu
      ;;
    Darwin)
      PLATFORM=$ARCH-apple-darwin
      ;;
    *)
      echo "rsvm: Not support this platform, $OSTYPE"
      return
      ;;
  esac

  if [ -f "rust-$1-$PLATFORM.tar.gz" ]
  then
    echo "Sources for rust $version already downloaded ..."
  else
    echo -n "Downloading sources for rust $version ... "
    curl -o "rust-$1-$PLATFORM.tar.gz" "https://static.rust-lang.org/dist/rust-$1-$PLATFORM.tar.gz"
    echo "done"
  fi

  if [ -e "rust-$1" ]
  then
    echo "Sources for rust $version already extracted ..."
  else
    echo -n "Extracting source ... "
    tar -xzf "rust-$1-$PLATFORM.tar.gz"
    mv "rust-$1-$PLATFORM" "rust-$1"
    echo "done"
  fi

  if [ ! -f $SRC/rust-$1/bin/cargo ]
  then
    echo -n "Downloading sources for cargo nightly ... "
    curl -o "cargo-nightly-$PLATFORM.tar.gz" "https://static.rust-lang.org/cargo-dist/cargo-nightly-$PLATFORM.tar.gz"
    echo "done"

    echo -n "Extracting source ... "
    tar -xzf "cargo-nightly-$PLATFORM.tar.gz"
    mv "cargo-nightly-$PLATFORM" "cargo-nightly"
    echo "done"

    cd "$SRC/cargo-nightly"
    sh install.sh --prefix=$DIST
  fi

  cd "$SRC/rust-$1"
  sh install.sh --prefix=$DIST

  echo ""
  echo "And we are done. Have fun using rust $version."

  cd $CURRENT_DIR
}

rsvm_ls_remote()
{
  local ARCH=`uname -m`
  local OSTYPE=`uname -s`
  local VERSIONS
  local PLATFORM
  case $OSTYPE in
    Linux)
      PLATFORM=$ARCH-unknown-linux-gnu
      ;;
    Darwin)
      PLATFORM=$ARCH-apple-darwin
      ;;
    *)
      echo "rsvm: Not support this platform, $OSTYPE"
      return
      ;;
  esac

  VERSIONS=$(curl -s http://static.rust-lang.org/dist/index.txt -o - \
    | command egrep -o "rust-$RSVM_VERSION_PATTERN-$PLATFORM.tar.gz" \
    | command egrep -o "$RSVM_VERSION_PATTERN" \
    | command sort \
    | command uniq)
  for VERSION in $VERSIONS;
  do
    echo $VERSION
  done
}

rsvm_uninstall()
{
  if [ `rsvm_current` = "$1" ]
  then
    echo "rsvm: Cannot uninstall currently-active version, $1"
    return
  fi
  if [ ! -d "$RSVM_DIR/$1" ]
  then
    echo "$1 version is not installed yet..."
    return
  fi
  echo "uninstall $1 ..."
  rm -rI "$RSVM_DIR/$1"
}

rsvm()
{

  case $1 in
    ""|help|--help|-h)
      echo ''
      echo 'Rust Version Manager'
      echo '===================='
      echo ''
      echo 'Usage:'
      echo ''
      echo '  rsvm help | --help | -h       Show this message.'
      echo '  rsvm install <version>        Download and install a <version>.'
      echo '                                <version> could be for example "0.12.0".'
      echo '  rsvm uninstall <version>      Uninstall a <version>.'
      echo '  rsvm use <version>            Activate <version> for now and the future.'
      echo '  rsvm ls | list                List all installed versions of rust.'
      echo '  rsvm ls-remote                List remote versions available for install.'
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
        echo "  rsvm install 0.12.0"
      elif ([[ "$2" =~ ^$RSVM_VERSION_PATTERN$ ]])
      then
        if [ "$3" = "--dry" ]
        then
          echo "Would install rust $2"
        else
          rsvm_install "$2"
        fi
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm install 0.12.0"
      fi
      ;;
    ls|list)
      rsvm_ls
      ;;
    ls-remote)
      rsvm_ls_remote
      ;;
    use)
      if [ -z "$2" ]
      then
        # whoops. no version found!
        echo "Please define a version of rust!"
        echo ""
        echo "Example:"
        echo "  rsvm use 0.12.0"
      elif ([[ "$2" =~ ^$RSVM_VERSION_PATTERN$ ]])
      then
        rsvm_use "$2"
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm use 0.12.0"
      fi
      ;;
    uninstall)
      if [ -z "$2" ]
      then
        # whoops. no version found!
        echo "Please define a version of rust!"
        echo ""
        echo "Example:"
        echo "  rsvm use 0.12.0"
      elif ([[ "$2" =~ ^$RSVM_VERSION_PATTERN$ ]])
      then
        rsvm_uninstall "$2"
      else
        # the version was defined in a the wrong format.
        echo "You defined a version of rust in a wrong format!"
        echo "Please use either <major>.<minor> or <major>.<minor>.<patch>."
        echo ""
        echo "Example:"
        echo "  rsvm uninstall 0.12.0"
      fi
      ;;
    *)
      rsvm
  esac

  echo ''
}
# vim: et ts=2 sw=2
