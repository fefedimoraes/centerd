default: clean-archive archive install

clean-archive:
  rm -rf centerd.xcarchive

archive:
  xcodebuild -workspace centerd.xcodeproj/project.xcworkspace -scheme centerd -configuration release -archivePath centerd.xcarchive clean archive

install: archive
  cp centerd.xcarchive/Products/usr/local/bin/centerd /usr/local/bin
