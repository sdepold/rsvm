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

## Usage

Show the help messages. Choose the one that you like most.

```console
rsvm help
rsvm --help
rsvm -h
```

Download and install a &lt;version&gt;. &lt;version&gt; could be for example "0.4".

```console
rsvm install <version>
e.g.: rsvm install 0.4
```

Activate &lt;version&gt; for now and the future.

```console
rsvm use <version>
e.g. rsvm use 0.4
```

List all installed versions of rust. Choose the one that you like most.

```console
rsvm ls
rsvm list
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

