---
layout: post
title: "spork + no db prep: four-fold speedup"
---

Here are some numbers for the rails rspeccing changes I [wrote about earlier today](http://ben.hoskings.net/2009/07/16/speedy-rspec-with-rails):

before
---
> time rake spec
13.27 real         9.93 user         2.18 sys
---
after
---
> time rake spec
3.35 real         0.88 user         0.25 sys
---

Nice.

