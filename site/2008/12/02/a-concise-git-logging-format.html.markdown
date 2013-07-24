---
layout: "/_post.haml"
title: "a concise git logging format"
---

A `git merge`, and hence also the merging stage of a `git pull`, sets `ORIG_HEAD` to the commit that `HEAD` pointed to before the merge. So the commits between these two points are the ones the most recent merge introduced.

    git log ORIG_HEAD..HEAD \
      --pretty=format:"%Cblue%h%Creset %Cgreen%an%Creset %s"
