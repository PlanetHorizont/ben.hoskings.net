---
layout: "/_post.haml"
title: "getting started with babushka"
---

_To install for the first time, or update an existing system_, just run
 
    bash -c "`curl babushka.me/up`"

That's for a box with `curl`, like a Mac. Most Linux boxes have `wget` instead, so for those, run

    bash -c "`wget -O - babushka.me/up`"

The script at `babushka.me/up` downloads a temporary copy of babushka in a tarball, which is used to run `babushka babushka`, which in turn installs babushka for real. So if you already have babushka installed, you can just run

    `babushka babushka`

The only difference is that the bootstrap command runs from a fresh copy of babushka that it downloads, and `babushka babushka` runs from the version that's currently on your system.
