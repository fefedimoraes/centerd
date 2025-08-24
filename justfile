default: build

clean:
  rm -rf .build

build:
  swift build -c release --arch arm64 --arch x86_64 --product centerd

install: build
  cp .build/apple/Products/Release/centerd /usr/local/bin
