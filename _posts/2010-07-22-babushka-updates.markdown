---
layout: post
title: "babushka v0.6"
---

I've been chipping away at the latest round of babushka updates over the last six weeks or so. They involved changes to existing babushka components, and several new ones. Once things were specced and working, I let the updates cool in a topic branch while I turned the design over in my hands to see if it felt right. After some tweaks I've decided it does, and so last week I merged the changes to [master][master]. If you update or install today you'll have the latest updates---as I write, at v0.6.1.

If you haven't used babushka before, [here's a quick tutorial and introduction][getting-started].

For the impatient, here's the short version.

- Sources have been unified into `~/.babushka/sources`, and `sources.yml` is gone;
- Namespace deps with `sourcename:depname` to jump sources, or to run from a non-default source;
- Instead of `app Chromium.app`, use `dep Chromium.app`;
- Instead of `gem_source 'rubygems source present'`, use `dep 'rubygems source present', :template => 'gem_source'`;
- The `pkg` template was renamed to `managed` because it looked like it handled OS X installer packages.

---

The latest round of updates involved redesigning the way deps and dep sources work, in order to make collaboration easier, encourage trust-based source sharing, and address what were obvious scaling barriers. A lot of the plumbing has been redesigned and reconnected. A couple of changes to the DSL were required, but it's remained largely the same.

A lot of the internal changes aren't directly visible; together, they mean that dep sources are a lot smoother and more automatic now. The visible changes arose from the fact that the more people start writing deps, the more everyone treads on each others' toes with naming collisions. As such, dep sources had to be made completely independent of each other. This involved a few separate changes to the way sources work.

---

_Each source maintains its own pool of deps now, so there are no naming conflicts across sources._

Previous versions of babushka loaded deps and templates from all sources into a single 'pool'. Deps were looked up from the pool by name at runtime when they were run, or were required by another dep. Now each source has a `DepPool` of its own, which stores just the deps defined in that source.

This allows deps in different sources to have the same name without conflicting with each other. The [core deps][core-deps] that are bundled with babushka also have their own source, and if you define deps in an interactive session like `irb`, they're stored in an implicit source.

In some situations, this means you have to include a dep's source in its name, so babushka knows where to look for it.

---

_To run a dep that isn't in a default source, its name has to be namespaced._ There are three default sources whose deps can be referred to without the source name:

- The core source, usually `/usr/local/babushka/deps`, which contains the deps babushka needs to install itself---things like ruby, git, and the standard package managers;
- The current project's deps, found in the current working directory at `./babushka-deps`;
- Your personal dep source, at `~/.babushka/deps`. In future, babushka will automatically set this directory up as a git repo pointing at `http://github.com/you/babushka-deps`.

To reference a dep that isn't in one of these three core sources, you just prepend the source name to it. So instead of running `babushka TextMate.app`, you should instead run `babushka benhoskings:TextMate.app` now, and so on.

Specifying dep names with `requires` statements follows the same pattern. To require a dep in one of the three core sources, or one that's in the same source as the requiring dep, there's no need to specify the source name. To require a non-core dep from a different source, just specify its source name as above.

    dep 'some TextMate plugin' do
      requires 'benhoskings:TextMate.app'
      …
    end

---

_The source system has been totally redesigned, so that it no longer requires a config file, is much more hackable, and can be completely automatic._

Firstly, sources are user-specific now, and stored in `~/.babushka/sources` instead of within the babushka installation for all to share (by default, `/usr/local/babushka/sources`).

Secondly, now that babushka knows where to look for namespaced deps, sources are lazily loaded when a dep they contain is required; the old design eagerly loaded all sources. This saves on startup time once you have more than a few sources present, and means babushka can handle dozens of sources without slowdown.

Thirdly, since deps can't conflict with each other anymore, there's no need to set source load order, and so `sources.yml` is gone. This makes the source system much simpler: a source's name is defined by the name of the directory it's in. This allows the source system to be used in a few different ways.

- If you run a dep like `benhoskings:Chromium.app`, the source at `~/.babushka/sources/benhoskings` will be loaded, no matter how it got there. So adding sources with custom names, or overriding someone else's source with one of your own, is simple---just name its directory accordingly.

- But, if `~/.babushka/sources/benhoskings` doesn't exist, it will be cloned from `http://github.com/benhoskings/babushka-deps.git`. This is probably what you'll want in most cases.

- You can still use `babushka sources -a <name> <uri>` to add a source with a custom name; that will clone `<uri>` into `~/.babushka/sources/<name>`.

- You can inspect all the present sources with `babushka sources -l`, which shows some info on each source that babushka knows about, including the path from which babushka will try to update it when it's used.

- Since `sources.yml` is gone, the only stored state is in the names of the source directories. So, it's completely safe to manually add, move, rename or delete directories within `~/.babushka/sources` .

All together, this means that the source system has been unified, so that it no longer distinguishes between sources that were added manually, and sources that were auto-added when a namespaced dep was run. They're all one and the same now, in `~/.babushka/sources`.

- **But, there is one caveat:** babushka assumes that it has control of any git repos within `~/.babushka/sources`, so don't leave uncommitted changes in any of those repos because babushka won't hesitate to blow them away. This might change in future; get in touch on the [mailing list][mailing-list] to share ideas on this.

---

_Everything is just a dep (and always was, but now it's obvious)._

Everything that you can declare with babushka's DSL is either a dep or a template. A dep at its lowest level is defined by the three statements `requires`, `met?` and `meet`, and all deps are based on those three, whether they explicitly define them or not.

You can't achieve a truly concise DSL without wrapping up common patterns as they emerge, though, and so you can define deps against templates, like `tmbundle`, `vim-plugin` or whatever you like. Because some things are worth making universal, a few of these templates are bundled along with babushka itself---like `app` for OS X applications, or `gem` for rubygems.

Confusion arose around these universal templates, though. Their top-level methods like `pkg` were defined in babushka core, which meant that they appeared to be special, and that their relation to a standard `dep` wasn't clear.

That's all cleaned up now. Just as sources have been unified, deps are always defined with the `dep` top-level method now, whether they use a template or not. Instead of saying `gem 'hpricot'`, you say either `dep 'hpricot', :template => 'gem'`, or `dep 'hpricot.gem'`. These two styles produce the same dep---the choice is there to allow you to include the template type in the dep's name.

In a lot of situations, this is just what you want---for example, `TextMate.app`, `Cucumber.tmbundle` and `sinatra.gem` are all concise names that are defined against templates, and describe exactly what they install. But, there are other situations where it gets messy, and the hash syntax is clearer---for example, `dep 'rubygems source present', :template => 'gem_source'`.

All the [core deps][core-deps] have been updated, along with the ones in [my dep source][benhoskings-deps]. You'll need to update your deps before they work with the new version of babushka. The best way to do this is to just try running one of your deps; as babushka tries to load your source it will complain about each piece of the old syntax it doesn't understand, and explain how you should update it.

---

_So, that's where things sit at the moment._ I think with this latest round of changes, babushka's design is solidifying. But having said that, I'm still very open to change, and I'm not afraid of making invasive changes if the case for them is strong enough. I'm really open to new ideas large and small, so if you have ideas, comments or feedback, I'd love to hear about them.

The best place for ideas and discussion is the [mailing list][mailing-list]. You should follow [@babushka_app][twitter] for updates and announcements, and [get in touch][tweet] whenever you like. Non-reply tweets are fairly sparse, so following won't clog up your timeline.


[getting-started]: /2010/07/24/getting-started-with-babushka
[master]: http://github.com/benhoskings/babushka
[mailing-list]: http://groups.google.com/group/babushka_app
[twitter]: http://twitter.com/babushka_app
[tweet]: http://twitter.com/?status=%40babushka_app%20
[core-deps]: http://github.com/benhoskings/babushka/tree/master/deps
[benhoskings-deps]: http://github.com/benhoskings/babushka-deps