---
layout: post
title: "babushka v0.6"
---

I've been chipping away at the latest round of babushka updates over the last six weeks or so. They involved changes to several babushka components, and several new ones. I let the updates cool in a topic branch while I turned the design over in my hands to see if it felt right. After some tweaks I've decided it does, and so earlier this week I merged the changes to master. If you update or install today you'll have the latest updates---as I write, at v0.6.1.

To install for the first time, or update an existing system, just run

    bash -c "`curl babushka.me/up`"

That script downloads a temporary copy of babushka that is used to run `babushka babushka`, which installs babushka for real. So if you already have babushka installed, you can just run that instead.

## But,

The changes to the DSL in 0.6 are backwards-incompatible. They're find-and-replaceable changes that only consist of method name changes, but they're top-level changes that will cause breakage in most dep sources until that source is updated, so I wanted to make sure I only caused one single instance of breakage. Better to get the DSL updates right the first time, and get the transition over with in one go.

When the new babushka finds a dep using the old, incompatible syntax, it prints an example showing how it should be upgraded.

## Rationale

So, why? Well, babushka started as a proof-of-concept in a single `babushka.rb` file, and all the deps were hardcoded into babushka itself. Obviously that wasn't going to scale, or even last once I got my first user, but to just show the idea worked and was worth pursuing, it was the right choice.

The next step was to separate the deps from the engine by adding dep sources. But the more you lower the barrier to entry, the more things get used, so autosources were introduced—just specify a qualified name like `benhoskings:textmate`, and the `textmate` dep is run from my dep source, which is pulled from github.

The next problem was scaling. Things worked alright when it was just a few dudes writing deps, but very quickly, dep names started to conflict, and it was clear that the dep source idea wouldn't scale as it was without people constantly treading on others' toes.

So, the purpose of the updates is to make dep sources independent of each other. This involved a few separate changes to the way sources work.

- Instead of loading sources into a single DepPool, each source has its own now, so it can independently maintain its own deps.
- To reference a dep that isn't in the same source or one of the core sources, its name has to be namespaced---like `benhoskings:textmate` above.
- Defining meta deps used to add a top-level method, like `pkg` or `tmbundle`, and since those can't be namespaced, they had to go.
- The source system was redesigned so that it no longer distinguishes between sources that were added manually, and sources that were auto-added by a namespaced dep. Everything is automatic now, and the sources.yml config file has been eliminated. The only use of sources.yml was specifying load order, and now that sources are independent, load order doesn't really mean anything.
- Instead of storing sources in `/usr/local/babushka/sources` for all to share, they're user-specific now, and live in `~/.babushka/sources`.
- Now that babushka knows where to look for namespaced deps, sources are only loaded when a dep inside them is required. The old design loaded all known sources all the time.

## Everything is just a dep (and always was)

The changes have made both writing and running deps a lot more intuitive, and removed a couple of elements of the original design that tended to confuse.

Everything that you can declare with babushka's DSL is a dep or a template. A dep at its lowest level is defined by the three declarations `requires`, `met?` and `meet`, and all deps are based on those three, whether they explicitly define them or not.

You can't get true conciseness without wrapping up common patterns, and so you can use templates, 

Instead of saying `pkg 'mongo'`, you say either `dep 'mongo', :template => 'managed'`, or `dep 'mongo.managed'` - whichever suits the situation better.