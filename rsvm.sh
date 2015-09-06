# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

RSVM_VERSION="0.1.0"
RSVM_NIGHTLY_PATTERN="nightly(\.[0-9]+)?"
RSVM_NORMAL_PATTERN="[0-9]+\.[0-9]+(\.[0-9]+)?(-(alpha|beta)(\.[0-9]*)?)?"
RSVM_RC_PATTERN="$RSVM_NORMAL_PATTERN-rc(\.[0-9+])?"
RSVM_VERSION_PATTERN="($RSVM_NIGHTLY_PATTERN|$RSVM_NORMAL_PATTERN|$RSVM_RC_PATTERN)"

RSVM_ARCH=`uname -m`
RSVM_OSTYPE=`uname -s`
case $RSVM_OSTYPE in
  Linux)
    RSVM_PLATFORM=$RSVM_ARCH-unknown-linux-gnu
    ;;
  Darwin)
    RSVM_PLATFORM=$RSVM_ARCH-apple-darwin
    ;;
  *)
    ;;
esac

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
  target=`echo $(readlink $RSVM_DIR/current|tr "/" "\n")`
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
  local target=$1
  local dirname
  local url_prefix

  if [[ $1 = "nightly" ]]
  then
    dirname=nightly.`date "+%Y%m%d%H%M%S"`
  elif [ ${1: -3} = '-rc' ]
  then
    dirname=$1
    target=${1%%-rc}
    url_prefix='/staging'
    echo $target
  else
    dirname=$1
  fi
  rsvm_init_folder_structure $dirname
  local SRC="$RSVM_DIR/$dirname/src"
  local DIST="$RSVM_DIR/$dirname/dist"

  cd $SRC

  if [ -z $RSVM_PLATFORM ]
  then
    echo "rsvm: Not support this platform, $RSVM_OSTYPE"
    return
  fi

  if [ -f "rust-$target-$RSVM_PLATFORM.tar.gz" ]
  then
    echo "Sources for rust $dirname already downloaded ..."
  else
    echo "Downloading sources for rust $dirname ... "
    curl -o "rust-$target-$RSVM_PLATFORM.tar.gz" "https://static.rust-lang.org/dist$url_prefix/rust-$target-$RSVM_PLATFORM.tar.gz"
  fi

  if [ -e "rust-$target" ]
  then
    echo "Sources for rust $dirname already extracted ..."
  else
    echo -n "Extracting source ... "
    tar -xzf "rust-$target-$RSVM_PLATFORM.tar.gz"
    mv "rust-$target-$RSVM_PLATFORM" "rust-$target"
    echo "done"
  fi

  if [ ! -f $SRC/rust-$target/bin/cargo ] && [ ! -f $SRC/rust-$target/cargo/bin/cargo ]
  then
    echo "Downloading sources for cargo nightly ... "
    curl -o "cargo-nightly-$RSVM_PLATFORM.tar.gz" "https://static.rust-lang.org/cargo-dist/cargo-nightly-$RSVM_PLATFORM.tar.gz"

    echo -n "Extracting source ... "
    tar -xzf "cargo-nightly-$RSVM_PLATFORM.tar.gz"
    mv "cargo-nightly-$RSVM_PLATFORM" "cargo-nightly"
    echo "done"

    cd "$SRC/cargo-nightly"
    sh install.sh --prefix=$DIST
  fi

  cd "$SRC/rust-$target"
  sh install.sh --prefix=$DIST

  echo ""
  echo "And we are done. Have fun using rust $dirname."

  cd $CURRENT_DIR
}

rsvm_ls_remote()
{
  local VERSIONS

  if [ -z $RSVM_PLATFORM ]
  then
    echo "rsvm: Not support this platform, $RSVM_OSTYPE"
    return
  fi

  VERSIONS=$(curl -s http://static.rust-lang.org/dist/index.txt -o - \
    | command egrep -o "dist/rust-$RSVM_NORMAL_PATTERN-$RSVM_PLATFORM.tar.gz" \
    | command egrep -o "$RSVM_VERSION_PATTERN" \
    | command sort \
    | command uniq)
  for VERSION in $VERSIONS;
  do
    echo $VERSION
  done
  rsvm_ls_channel staging
  rsvm_ls_channel nightly
}

rsvm_ls_channel()
{
  local VERSIONS
  local POSTFIX

  if [ -z $RSVM_PLATFORM ]
  then
    echo "rsvm: Not support this platform, $RSVM_OSTYPE"
    return
  fi

  case $1 in
    staging|rc)
      POSTFIX='-rc'
      VERSIONS=$(curl -s http://static.rust-lang.org/dist/staging/channel-rust-stable -o - \
        | command egrep -o "rust-$RSVM_VERSION_PATTERN-$RSVM_PLATFORM.tar.gz" \
        | command egrep -o "$RSVM_VERSION_PATTERN" \
        | command sort \
        | command uniq)
      ;;
    stable|nightly)
      VERSIONS=$(curl -s http://static.rust-lang.org/dist/channel-rust-$1 -o - \
        | command egrep -o "rust-$RSVM_VERSION_PATTERN-$RSVM_PLATFORM.tar.gz" \
        | command egrep -o "$RSVM_VERSION_PATTERN" \
        | command sort \
        | command uniq)
      ;;
    *)
      echo "rsvm: Not support this channel, $1"
      return
      ;;
  esac

  for VERSION in $VERSIONS;
  do
    echo $VERSION$POSTFIX
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

  case $RSVM_OSTYPE in
    Darwin)
      rm -ri "$RSVM_DIR/$1"
      ;;
    *)
      rm -rI "$RSVM_DIR/$1"
      ;;
  esac
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
      echo '  rsvm ls-channel               Print a channel version available for install.'
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
    ls-channel)
      if [ -z "$2" ]
      then
        # whoops. no channel found!
        echo "Please define a channel of rust!"
        echo ""
        echo "Example:"
        echo "  rsvm ls-channel stable"
      else
        rsvm_ls_channel $2
      fi
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
