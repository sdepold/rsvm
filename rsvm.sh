# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

RSVM_VERSION="0.4.1"
RSVM_NIGHTLY_PATTERN="nightly(\.[0-9]+)?"
RSVM_BETA_PATTERN="beta(\.[0-9]+)?"
RSVM_NORMAL_PATTERN="[0-9]+\.[0-9]+(\.[0-9]+)?(-(alpha|beta)(\.[0-9]*)?)?"
RSVM_RC_PATTERN="$RSVM_NORMAL_PATTERN-rc(\.[0-9]+)?"
RSVM_VERSION_PATTERN="($RSVM_NIGHTLY_PATTERN|$RSVM_NORMAL_PATTERN|$RSVM_RC_PATTERN|$RSVM_BETA_PATTERN)"
RSVM_LAST_INSTALLED_VERSION=
RSVM_SCRIPT=${BASH_SOURCE[0]}

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

# Auto detect the RSVM_DIR
if [ ! -d "$RSVM_DIR" ]
then
  export RSVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) && pwd)
fi

rsvm_initialize()
{
  if [ ! -d "$RSVM_DIR/versions" ]
  then
    mkdir -p "$RSVM_DIR/versions"
  fi
  if [ ! -f "$RSVM_DIR/.rsvm_version" ]
  then
    touch "$RSVM_DIR/.rsvm_version"
  fi
  local rsvm_version=$(cat "$RSVM_DIR/.rsvm_version")
  if [ -z "$rsvm_version" ]
  then
    local DIRECTORIES=$(find "$RSVM_DIR" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; \
      | sort \
      | egrep "^$RSVM_VERSION_PATTERN")

    mkdir -p "$RSVM_DIR/versions"
    for line in $(echo $DIRECTORIES | tr " " "\n")
    do
      mv "$RSVM_DIR/$line" "$RSVM_DIR/versions"
    done
  fi
  echo "1" > "$RSVM_DIR/.rsvm_version"
}


rsvm_check_etag()
{
  if [ -f $2.etag ]
  then
    curl -s -I -H "If-None-Match:$(cat $2.etag)" $1 | grep 304 | wc -l
  elif [ -f $2 ]
  then
    local ETAG=$(md5sum $2 | awk '{print $1}')
    curl -s -I -H "If-None-Match:\"$ETAG\"" $1 | grep 304 | wc -l
  else
    echo 0
  fi
}

rsvm_file_download()
{
  local OPTS
  # download custom etag
  if [ "$3" = true ]
  then
    curl -I -s $1 | grep ETag | awk '{print $2}' > $2.etag
    OPTS='-#'
  else
    OPTS='-s'
  fi

  if [ $(rsvm_check_etag $1 $2) = 0 ]
  then
    # not match etag; new download
    curl $OPTS -o $2 $1
  else
    # match etag; resume download
    curl $OPTS -o $2 -C - $1
  fi

}

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

export PATH=$(rsvm_append_path $PATH "$RSVM_DIR/current/dist/bin")
export LD_LIBRARY_PATH=$(rsvm_append_path $LD_LIBRARY_PATH "$RSVM_DIR/current/dist/lib")
export DYLD_LIBRARY_PATH=$(rsvm_append_path $DYLD_LIBRARY_PATH "$RSVM_DIR/current/dist/lib")
export MANPATH=$(rsvm_append_path $MANPATH "$RSVM_DIR/current/dist/share/man")
export RSVM_SRC_PATH="$RSVM_DIR/current/src/rustc-source/src"
if [ -e "$RSVM_SRC_PATH" ]
then
  export RUST_SRC_PATH="$RSVM_SRC_PATH"
else
  unset RUST_SRC_PATH
fi

rsvm_use()
{
  if [ -e "$RSVM_DIR/versions/$1" ]
  then
    echo -n "Activating rust $1 ... "

    rm -rf "$RSVM_DIR/current"
    ln -s "$RSVM_DIR/versions/$1" "$RSVM_DIR/current"
    source $RSVM_SCRIPT

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
  if [ ! -e "$RSVM_DIR/current" ]
  then
    echo "N/A"
    return
  fi
  target=`echo $(readlink "$RSVM_DIR/current"|tr "/" "\n")`
  echo ${target[@]} | awk '{print$NF}'
}

rsvm_ls()
{
  DIRECTORIES=$(find "$RSVM_DIR/versions" -maxdepth 1 -mindepth 1 -type d -exec basename '{}' \; \
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

  mkdir -p "$RSVM_DIR/versions/$1/src"
  mkdir -p "$RSVM_DIR/versions/$1/dist"

  echo "done"
}

rsvm_install()
{
  local CURRENT_DIR=`pwd`
  local target=$1
  local with_rustc_source=$2
  local dirname
  local url_prefix
  local LAST_VERSION

  if [ ${1: -3} = '-rc' ]
  then
    url_prefix='/staging/dist'
    target=${1%%-rc}
  fi

  if [[ $1 = "nightly" ]] || [[ $1 = "beta" ]] || [ ${1: -3} = '-rc' ]
  then
    # if same version reuse directory
    LAST_VERSION=$(rsvm_ls|grep $1|tail -n 1|awk '{print $2}')
    if [ $(rsvm_check_etag \
             "https://static.rust-lang.org/dist$url_prfix/rust-$target-$RSVM_PLATFORM.tar.gz" \
             "$RSVM_DIR/versions/$LAST_VERSION/src/rust-$target-$RSVM_PLATFORM.tar.gz") = 1 ]
    then
      dirname=$LAST_VERSION
    else
      dirname=$1.`date "+%Y%m%d%H%M%S"`
    fi
  else
    dirname=$1
  fi

  rsvm_init_folder_structure $dirname
  local SRC="$RSVM_DIR/versions/$dirname/src"
  local DIST="$RSVM_DIR/versions/$dirname/dist"

  cd $SRC

  if [ -z $RSVM_PLATFORM ]
  then
    echo "rsvm: Not support this platform, $RSVM_OSTYPE"
    return
  fi

  echo "Downloading sources for rust $dirname ... "
  rsvm_file_download \
    "https://static.rust-lang.org/dist$url_prfix/rust-$target-$RSVM_PLATFORM.tar.gz" \
    "rust-$target-$RSVM_PLATFORM.tar.gz" \
    true

  if [ -e "rust-$target" ]
  then
    echo "Sources for rust $dirname already extracted ..."
  else
    echo -n "Extracting source ... "
    tar -xzf "rust-$target-$RSVM_PLATFORM.tar.gz"
    mv "rust-$target-$RSVM_PLATFORM" "rust-$target"
    echo "done"
  fi

  if [ "$with_rustc_source" = true ]
  then
    echo "Downloading sources for rustc sourcecode $dirname ... "
    rsvm_file_download \
      "https://static.rust-lang.org/dist$url_prfix/rustc-$target-src.tar.gz" \
      "rustc-$target-src.tar.gz" \
      true
    if [ -e "rustc-source" ]
    then
      echo "Sources for rustc $dirname already extracted ..."
    else
      echo -n "Extracting source ... "
      tar -xzf "rustc-$target-src.tar.gz"
      mv "rustc-$target" "rustc-source"
    fi
  fi

  if [ ! -f $SRC/rust-$target/bin/cargo ] && [ ! -f $SRC/rust-$target/cargo/bin/cargo ]
  then
    echo "Downloading sources for cargo nightly ... "
    rsvm_file_download \
      "https://static.rust-lang.org/cargo-dist/cargo-nightly-$RSVM_PLATFORM.tar.gz" \
      "cargo-nightly-$RSVM_PLATFORM.tar.gz" \
      true

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
  RSVM_LAST_INSTALLED_VERSION=$dirname
}

rsvm_ls_remote()
{
  local VERSIONS
  local STABLE_VERSION

  if [ -z $RSVM_PLATFORM ]
  then
    echo "rsvm: Not support this platform, $RSVM_OSTYPE"
    return
  fi

  STABLE_VERSION=$(rsvm_ls_channel stable)
  rsvm_file_download http://static.rust-lang.org/dist/index.txt "$RSVM_DIR/cache/index.txt"
  VERSIONS=$(cat "$RSVM_DIR/cache/index.txt" \
    | command egrep -o "^/dist/rust-$RSVM_NORMAL_PATTERN-$RSVM_PLATFORM.tar.gz" \
    | command egrep -o "$RSVM_VERSION_PATTERN" \
    | command sort \
    | command uniq)
  for VERSION in $VERSIONS;
  do
    if [ "$STABLE_VERSION" = "$VERSION" ]
    then
      continue
    fi
    echo $VERSION
  done
  echo $STABLE_VERSION
  rsvm_ls_channel staging
  rsvm_ls_channel beta
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
      rsvm_file_download http://static.rust-lang.org/dist/staging/dist/channel-rust-stable "$RSVM_DIR/cache/channel-rust-staging"
      VERSIONS=$(cat "$RSVM_DIR/cache/channel-rust-staging" \
        | command egrep -o "rust-$RSVM_VERSION_PATTERN-$RSVM_PLATFORM.tar.gz" \
        | command egrep -o "$RSVM_VERSION_PATTERN" \
        | command sort \
        | command uniq)
      ;;
    stable|beta|nightly)
      rsvm_file_download http://static.rust-lang.org/dist/channel-rust-$1 "$RSVM_DIR/cache/channel-rust-$1"
      VERSIONS=$(cat "$RSVM_DIR/cache/channel-rust-$1" \
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
  if [ ! -d "$RSVM_DIR/versions/$1" ]
  then
    echo "$1 version is not installed yet..."
    return
  fi
  echo "uninstall $1 ..."

  case $RSVM_OSTYPE in
    Darwin)
      rm -ri "$RSVM_DIR/versions/$1"
      ;;
    *)
      rm -rI "$RSVM_DIR/versions/$1"
      ;;
  esac
}

rsvm()
{
  rsvm_initialize

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
        local version=$2
        local with_rustc_source=true
        for i in ${@:3:${#@}}
        do
          case $i in
            --dry)
              echo "Would install rust $version"
              RSVM_LAST_INSTALLED_VERSION=$version
              rsvm_use $RSVM_LAST_INSTALLED_VERSION
              exit
              ;;
            --without-rustc-source)
              with_rustc_source=false
              ;;
            *)
              ;;
          esac
        done
        rsvm_install "$version" "$with_rustc_source"
        rsvm_use $RSVM_LAST_INSTALLED_VERSION
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
