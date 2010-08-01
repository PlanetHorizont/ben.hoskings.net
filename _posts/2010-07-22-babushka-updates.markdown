---
layout: post
title: "babushka v0.6"
---

I've been chipping away at the latest round of babushka updates over the last six weeks or so. They involved changes to existing babushka components, and several new ones. Once things were specced and working, I let the updates cool in a topic branch while I turned the design over in my hands to see if it felt right. After some tweaks I've decided it does, and so last week I merged the changes to [master][master]. If you update or install today you'll have the latest updates---as I write, at v0.6.1.

If you haven't used babushka before, [here's a quick tutorial and introduction][getting-started].

The latest round of updates involved redesigning the way deps and dep sources work, in order to make collaboration easier, encourage trust-based source sharing, and address what were obvious scaling barriers. A lot of the plumbing has been redesigned and reconnected. A couple of changes to the DSL were required, but it's remained largely the same.

A lot of the internal changes aren't directly visible; together, they mean that dep sources are a lot smoother and more automatic now. The visible changes arose from the fact that the more people start writing deps, the more everyone treads on each others' toes with naming collisions. As such, dep sources had to be made completely independent of each other. This involved a few separate changes to the way sources work.

_Each source maintains its own pool of deps now, so there are no naming conflicts across sources._

Previous versions of babushka loaded deps and templates from all sources into a single 'pool'. Deps were looked up from the pool by name at runtime when they were run, or were required by another dep. Now each source has a `DepPool` of its own, which stores just the deps defined in that source.

This allows deps in different sources to have the same name without conflicting with each other. The core deps that are bundled with babushka also have their own source, and if you define deps in an interactive session like `irb`, they're stored in an implicit source.

In some situations, this means you have to include a dep's source in its name, so babushka knows where to look for it.

_To run a dep that isn't in a default source, its name has to be namespaced._

There are three default sources whose deps can be referred to without the source name:

- The core source, usually `/usr/local/babushka/deps`, which contains the deps babushka needs to install itself---things like ruby, git, and the standard package managers;

- The current project's deps, found in the current working directory at `./babushka-deps`;

- Your personal dep source, at `~/.babushka/deps`. In future, babushka will automatically set this directory up as a git repo pointing at `http://github.com/you/babushka-deps`.

To reference a dep that isn't in one of these three core sources, you just prepend the source name to it. So instead of running `babushka TextMate.app`, you should instead run `babushka benhoskings:TextMate.app` now, and so on.

Specifying dep names with `requires` statements follows the same pattern. To require a dep in one of the three core sources, or one that's in the same source as the requiring dep, there's no need to specify the source name. To require a non-core dep from a different source, just specify its source name as above.

    dep 'some TextMate plugin' do
      requires 'benhoskings:TextMate.app'
      …
    end

_The source system has been totally redesigned, so that it no longer requires a config file, is much more hackable, and can be completely automatic._

Firstly, sources are user-specific now, and stored in `~/.babushka/sources` instead of within the babushka installation for all to share (by default, `/usr/local/babushka/sources`).

Secondly, now that babushka knows where to look for namespaced deps, sources are only loaded when a dep they contain is required. The old design loaded all known sources all the time.

Thirdly, since deps can't conflict with each other anymore, there's no need to set source load order, and so `sources.yml` is gone. This makes the source system much simpler: a source's name is defined by the name of the directory it's in. This allows the source system to be used in a few different ways.

- If you run a dep like `benhoskings:Chromium.app`, the source at `~/.babushka/sources/benhoskings` will be loaded, no matter how it got there. So adding sources with custom names, or overriding someone else's source with one of your own, is simple---just name its directory accordingly.

- But, if `~/.babushka/sources/benhoskings` doesn't exist, it will be cloned from `http://github.com/benhoskings/babushka-deps.git`. This is probably what you'll want in most cases.

- You can still use `babushka sources -a <name> <uri>` to add a source with a custom name; that will clone `<uri>` into `~/.babushka/sources/<name>`.

- You can inspect all the present sources with `babushka sources -l`, which shows some info on each source that babushka can see, including the path from which babushka will try to update it when it's used.

- Since `sources.yml` is gone, the only stored state is in the names of the source directories. So it's completely safe to manually add, move, rename or delete directories within `~/.babushka/sources`.

All together, this means that the source system has been unified, so that it no longer distinguishes between sources that were added manually, and sources that were auto-added when a namespaced dep was run. They're all one and the same now, in `~/.babushka/sources`.

- **But, there is one caveat:** babushka assumes that it has control of any git repos within `~/.babushka/sources`, so don't leave uncommitted changes in any of those repos because babushka won't hesitate to blow them away.


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