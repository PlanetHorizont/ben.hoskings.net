---
layout: post
title: "babushka v0.6"
---

I've been chipping away at the latest round of babushka updates over the last six weeks or so. They involved changes to several babushka components, and several new ones. I let the updates cool in a topic branch while I turned the design over in my hands to see if it felt right. After some tweaks I've decided it does, and so earlier this week I merged the changes to [master][master]. If you update or install today you'll have the latest updates---as I write, at v0.6.1.

If you haven't used babushka before, [here's a quick getting started guide][getting-started].

The latest round of updates involved a redesign of the way deps and dep sources work, in order to make collaboration easier, nudge usage in the direction of decentralised collaboration, and address what were obvious scaling barriers. The syntax has largely remained the same, but a lot of the plumbing has been redesigned and reconnected, and a couple of changes to the DSL were required.

A lot of the internal changes aren't directly visible; they just mean that dep sources are a lot smoother and more automatic now. The visible changes arose from the fact that the more people start writing deps, the more people tread on each others' toes with naming collisions. As such, dep sources had to be made completely independent of each other. This involved a few separate changes to the way sources work. I'm sure there's a good foot-related pun there that explains 



- Instead of loading deps from all sources into a single pool, each source has its own pool now, so there are no naming conflicts across sources.

- To reference a dep that isn't in the same source or one of the core sources, its name has to be namespaced---like `benhoskings:textmate` above.
- The source system was redesigned so that it no longer distinguishes between sources that were added manually, and sources that were auto-added by a namespaced dep. Everything is automatic now, and the sources.yml config file has been eliminated. The only use of sources.yml was specifying load order, and now that sources are independent, load order doesn't really mean anything.
- Instead of storing sources in `/usr/local/babushka/sources` for all to share, they're user-specific now, and live in `~/.babushka/sources`.
- Now that babushka knows where to look for namespaced deps, sources are only loaded when a dep inside them is required. The old design loaded all known sources all the time.





- Defining meta deps used to add a top-level method, like `pkg` or `tmbundle`, and since those can't be namespaced, they had to go.





## But,

The changes to the DSL in 0.6 are backwards-incompatible. They're find-and-replaceable changes that only consist of method name changes, but they're top-level changes that will cause breakage in most dep sources until that source is updated, so I wanted to make sure I only caused one single instance of breakage. Better to get the DSL updates right the first time, and get the transition over with in one go.

When the new babushka finds a dep using the old, incompatible syntax, it prints an example showing how it should be upgraded.

## Rationale

So, why? Well, babushka started as a proof-of-concept in a single `babushka.rb` file, and all the deps were hardcoded into babushka itself. Obviously that wasn't going to scale, or even last once I got my first user, but to just show the idea worked and was worth pursuing, it was the right choice.

The next step was to separate the deps from the engine by adding dep sources. But the more you lower the barrier to entry, the more things get used, so autosources were introduced—just specify a qualified name like `benhoskings:textmate`, and the `textmate` dep is run from my dep source, which is pulled from github.

The next problem was scaling. Things worked alright when it was just a few dudes writing deps, but very quickly, dep names started to conflict, and it was clear that the dep source idea wouldn't scale as it was without people constantly treading on others' toes.

## Everything is just a dep (and always was)

The changes have made both writing and running deps a lot more intuitive, and removed a couple of elements of the original design that tended to confuse.

Everything that you can declare with babushka's DSL is a dep or a template. A dep at its lowest level is defined by the three declarations `requires`, `met?` and `meet`, and all deps are based on those three, whether they explicitly define them or not.

You can't get true conciseness without wrapping up common patterns, though, and so you can use templates, like `tmbundle`, `vim-plugin` or whatever you like. Because some things are universal, though, a few of these were bundled along with babushka itself---like `pkg` for writing deps that work with the system's package manager, or `gem` for rubygems.

These special templates were defined in an outdated way that predated templates, but in essence they were the same thing. But because those top-level methods like `pkg` were there in babushka core, they appeared to be special, and their relation to a standard `dep` wasn't clear.

That's all cleaned up now as well. Just as manual and auto sources have been unified, all deps are defined with the `dep` top-level method now, whether they use a template or not.

Instead of saying `pkg 'mongo'`, you say either `dep 'mongo', :template => 'managed'`, or `dep 'mongo.managed'` - whichever suits the situation better.

[getting-started]: /2010/07/24/getting-started-with-babushka
[master]: http://github.com/benhoskings/babushka