#? NVM wrapper. Félix Saparelli. Public Domain
#> https://github.com/passcod/nvm-fish-wrapper
#v 1.1.0

function rsvm_set
  if test (count $argv) -gt 1
    #echo set: k: $argv[1] v: $argv[2..-1]
    set -gx $argv[1] $argv[2..-1]
  else
    #echo unset: k: $argv[1]
    set -egx $argv[1]
  end
end

function rsvm_split_env
  set k (echo $argv | cut -d\= -f1)
  set v (echo $argv | cut -d\= -f2-)
  echo $k
  echo $v
end

function rsvm_find_paths
  echo $argv | grep -oE '[^:]+' | grep -w '.rsvm'
end

function rsvm_set_path
  set k $argv[1]
  set r $argv[2..-1]

  set newpath
  for o in $$k
    if echo $o | grep -qvw '.rsvm'
      set newpath $newpath $o
    end
  end

  for p in (rsvm_find_paths $r)
    set newpath $p $newpath
  end
  rsvm_set $k $newpath
end

function rsvm_mod_env
  set tmpnew $tmpdir/newenv

  bash -c "source ~/.rsvm/rsvm.sh && source $tmpold && rsvm $argv && export status=\$? && env > $tmpnew && exit \$status"

  set rsvmstat $status
  if test $rsvmstat -gt 0
    return $rsvmstat
  end

  rsvm_set RUST_SRC_PATH

  for e in (cat $tmpnew)
    set p (rsvm_split_env $e)

    if test (echo $p[1] | cut -d_ -f1) = rsvm
      if test (count $p) -lt 2
        rsvm_set $p[1] ''
        continue
      end

      rsvm_set $p[1] $p[2..-1]
      continue
    end

    if test $p[1] = PATH
      rsvm_set_path PATH $p[2..-1]
    else if test $p[1] = LD_LIBRARY_PATH
      rsvm_set_path LD_LIBRARY_PATH $p[2..-1]
    else if test $p[1] = DYLD_LIBRARY_PATH
      rsvm_set_path DYLD_LIBRARY_PATH $p[2..-1]
    else if test $p[1] = MANPATH
      rsvm_set_path MANPATH $p[2..-1]
    else if test $p[1] = RUST_SRC_PATH
      rsvm_set RUST_SRC_PATH $p[2..-1]
    else if test $p[1] = CARGO_HOME
      rsvm_set CARGO_HOME $p[2..-1]
    else if test $p[1] = RUSTUP_HOME
      rsvm_set RUSTUP_HOME $p[2..-1]
    end
  end

  return $rsvmstat
end

function rsvm
  set -g tmpdir (mktemp -d 2>/dev/null; or mktemp -d -t 'rsvm-wrapper') # Linux || OS X
  set -g tmpold $tmpdir/oldenv
  env | grep -E '^((rsvm|RUST)_|(MAN)?PATH=)' | sed -E 's/\\\\?([ ()])/\\\\\\1/g' > $tmpold

  set -l arg1 $argv[1]
  if echo $arg1 | grep -qE '^(use|install|deactivate)$'
    rsvm_mod_env $argv
    set s $status
  else if test $arg1 = 'unload' 2>/dev/null
    functions -e (functions | grep -E '^rsvm(_|$)')
  else
    bash -c "source ~/.rsvm/rsvm.sh && source $tmpold && rsvm $argv"
    set s $status
  end

  rm -r $tmpdir
  return $s
end
