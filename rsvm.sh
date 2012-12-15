# Rust Version Manager
# ====================
#
# To use the rsvm command source this file from your bash profile.

# Auto detect the NVM_DIR
if [ ! -d "$NVM_DIR" ]; then
  export NVM_DIR=$(cd $(dirname ${BASH_SOURCE[0]:-$0}) && pwd)
fi

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
        echo -n "Creating the respective folder for rust v$2 ... "
        mkdir -p "`pwd`/v$2"
        echo "done"
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
