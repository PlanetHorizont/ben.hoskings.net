---
layout: "/_post.haml"
title: "ruby 2.0"
---


An auspicious day indeed---20 years ago today, in 1993, Matz started work on a new language. It saw its first public release about three years later, at the end of 1995. So happy 20th birthday to ruby, and a tip of the hat to Matz and all on ruby core who've worked hard on it since then.

Hopefully well see another big event today---the release of ruby-2.0. This is a release that's been years in the making. Version 2.0 has a strong theme, and that's _convention_---2.0 formalises useful conventions that us rubyists have grown to use, and it judiciously adds language features to address bad conventions.

I spoke at [RubyConf AU](http://www.rubyconf.org.au) on Friday about these changes. Here's a run-down, with some quick examples for the language changes---but first, a quick list of some more specific changes. There's a full list [in the NEWS file](https://github.com/ruby/ruby/blob/trunk/NEWS), but these are my favourites:

- The GC is copy-on-write friendly, thanks to [Narihiro Nakamura](https://twitter.com/nari_en). In the past, forked ruby processes would quickly duplicate their shared memory, because the GC used to modify every object during the mark phase of its mark-and-sweep run. As of 2.0, objects are marked in a separate data structure instead of on the objects themselves, leaving them unchanged and allowing the kernel to share lots of memory. In practise, this means your unicorns will consume less resident memory (although they'll still appear to have the same resident size [because of how RSIZE is reported](http://unix.stackexchange.com/a/34867)).

- Syck has been removed. The syck/psych yaml gauntlet that we all had to pass through around the 1.9.2 days is completely behind us now, which is great. Ruby now has a hard dependency on libyaml, but it's bundled for the cases where the library isn't present locally.

- Literal strings are unicode by default in 2.0. This means that the `# coding: utf-8` comment we've grown accustomed to adding isn't required for apps running on 2.0. This is a nice step in the direction of "all unicode all the time". A bunch of other encoding cleanups were made -- one example is `Time#to_s`, which returns a string encoded in US-ASCII instead of BINARY.

- The `LoadError` exception gains a `#path` method, which is the path to the file that failed to load.

- The list-of-string methods on `IO`, `StringIO` and friends, like `#lines`, `#chars` and `#bytes`, have been deprecated in favour of `#each_line`, etc. This is a nice change, pushing the feel of the enumerating API in the direction of the `#each` / `#each_thing` convention.
