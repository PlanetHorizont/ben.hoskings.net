---
layout: post
title: "babushka: dmg and macports support"
---

## {{ page.title }}

I just added a few new tricks to Babushka. It knows how to open a DMG now:

--- ruby
dmg "http://blah.org/appname.dmg" do |path|
  # Use the contents of the DMG here.
  # path is the path at which the DMG was mounted.
  # e.g. /Volumes/appname
end
---

The DMG is downloaded and mounted, and the unmount is handled automatically after the block returns.

So now, among other things, it can install MacPorts (which is a dependency of git, wget, etc on OS X).

---
> ruby bin/babushka.rb macports
Loaded 0 dependencies from ~/.babushka/deps.
Loaded 59 dependencies from ./deps.
macports {
  build tools {
    xcode tools {
    } √ xcode tools
    build tools / met? not defined.
  } √ build tools
  macports not already met.
  Downloading MacPorts-1.7.1-10.5-Leopard.dmg... done.
  Installing MacPorts-1.7.1... done.
  Running port selfupdate... done.
  macports met.
} √ macports
---

