# rsvm

A version manager for rust.

## Installation

```console
curl https://raw.github.com/sdepold/rsvm/master/install.sh | sh
```

or

```console
wget -qO- https://raw.github.com/sdepold/rsvm/master/install.sh | sh
```

## Running the tests

RSVM is tested with bats. Install like this:

```console
git clone https://github.com/sstephenson/bats.git
cd bats
./install.sh /usr/local
```

Inside the rsvm repository do this:

```console
bats test/rsvm.sh.bats
```

