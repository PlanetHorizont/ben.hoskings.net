---
layout: post
title: "pull, inspect, update -- and then push."
---

## {{ page.title }}

A common thing I do with git is push my changes to a remote repo, after first updating my project locally with all the changes others have pushed. But I always forget to update first, so the process usually goes--

- push
- rap my fingers on the table for five seconds while my laptop talks to github on the other side of the world
- "oh crap I should have pulled first"
- pull
- update submodules
- push
- "hmm, what did I just push"
- get a coffee (this step should have been first).

So, I made a little alias to handle it all for me, dropping in my [new commits alias][1]:

---
alias gitp='git pull &&
  git log ORIG_HEAD..HEAD \
    --pretty=format:"%Cblue%h%Creset %Cgreen%an%Creset %s" | cat &&
  echo &&
  git submodule update &&
  git log $(git config branch.master.remote)/master..master \
    --pretty=format:"%Cblue%h%Creset %Cgreen%an%Creset %s" | cat &&
  echo &&
  git push'
---

This alias pulls, lists the new commits, updates submodules, lists the commits that are about to be pushed, and then pushes them.

Since the `log` comes after the `pull`, it shows a list of the commits that were just pulled down along with a snippet of their commit message. I like this because it lets me see what everyone else has done in the last little while every time I hit the shared repo.

[1]: http://ben.hoskings.net/2008/12/02/a-concise-git-logging-format

