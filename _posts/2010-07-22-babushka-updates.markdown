---
layout: post
title: "babushka v0.6"
---

I've been chipping away at the latest round of babushka updates over the last six weeks or so. They involved changes to quite a few distinct parts of babushka, several new components, and a lot of refactoring of existing ones. I held the updates in a topic branch and let them cool while I turned the design over in my hands to see if it felt right. After some tweaks I've decided it does feel right, and so earlier this week I merged the changes to master. If you update or install today you'll have the latest updates—as I write, at v0.6.1.

To install for the first time, or update an existing system, just run

    bash -c "`curl babushka.me/up`"

That script downloads a temporary copy of babushka that is used to run `babushka babushka`, which installs babushka for real. So if you already have babushka installed, you can just run that instead.

## But,

The changes to the DSL in 0.6 are backwards-incompatible. They're find-and-replaceable changes that only consist of method name changes, but they're top-level changes that will cause breakage in most dep sources until that source is updated, so I wanted to make sure I only caused one single instance of breakage. Better to get the DSL updates right the first time, and get the transition over with in one go.

## Rationale

So, why? Well, babushka started as a proof-of-concept in a single `babushka.rb` file, and all the deps were hardcoded into babushka itself. Obviously that wasn't going to scale, or even last once I got my first user, but to just show the idea worked and was worth pursuing, it was the right choice.

## Then

The next step was to separate the deps from the engine, and so dep sources were introduced. But the more you lower the barrier to entry, the more things get used, and who wants to add a whole bunch of arbitrary sources just to discover others' recipes? So autosources were introduced—just specify a qualified name like `benhoskings:textmate`, and the `textmate` dep is run from my dep source, which is pulled from github.

## Now

The next problem was scaling. When it was just a few dudes writing deps, then things worked alright, but very quickly, dep names started to conflict, and 