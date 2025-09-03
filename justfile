default: build

clean:
  rm -rf .build

format:
  swift format -r -i .

lint:
  swift format lint -r -s .

build: format lint
  swift build -c release --arch arm64 --arch x86_64 --product centerd

install: build
  cp .build/apple/Products/Release/centerd /usr/local/bin

uninstall:
  rm /usr/local/bin/centerd
