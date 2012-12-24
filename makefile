all:
	mkdir -p dist
	rustc ./rsvm.rs -o dist/rsvm
	chmod +x dist/rsvm
