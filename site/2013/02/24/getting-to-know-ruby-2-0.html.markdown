---
layout: "/_post.haml"
title: "getting to know ruby 2.0"
---


Today is an auspicious day for ruby. Exactly 20 years ago, on the 24th of February 1993, [Rubyのパパ, Matz](https://twitter.com/yukihiro_matz) started work on what was to become ruby. It saw its first public release about three years later, at the end of 1995. Since then many rubies have been cut and polished. So happy 20th birthday to ruby, and a tip of the hat to Matz and all on ruby core who've worked hard on it since then.

Hopefully well see another big event today---the release of ruby-2.0. This is a release that's been years in the making. Version 2.0 has a strong theme, and that's _convention_---2.0 formalises useful conventions that us rubyists have grown to use, and it judiciously adds language features to address bad conventions.

I spoke at [RubyConf AU](http://www.rubyconf.org.au) on Friday about these changes. Here's a run-down, with some quick examples for the language changes---but first, a quick list of some more specific changes. There's a full list [in the NEWS file](https://github.com/ruby/ruby/blob/trunk/NEWS), but these are my favourites:

- **The GC is copy-on-write friendly**, thanks to [Narihiro Nakamura](https://twitter.com/nari_en). In the past, forked ruby processes would quickly duplicate their shared memory, because the GC used to modify every object during the mark phase of its mark-and-sweep run. As of 2.0, objects are marked in a separate data structure instead of on the objects themselves, leaving them unchanged and allowing the kernel to share lots of memory. In practise, this means your unicorns will consume less resident memory (although they'll still appear to have the same resident size [because of how RSIZE is reported](http://unix.stackexchange.com/a/34867)). Pat Shaughnessy wrote [an excellent post](http://patshaughnessy.net/2012/3/23/why-you-should-be-excited-about-garbage-collection-in-ruby-2-0) detailing how Narihiro's new GC design works.

- **Syck has been removed**. The syck/psych yaml gauntlet that we all had to pass through around the 1.9.2 days is completely behind us now, which is great. Ruby now has a hard dependency on libyaml, but it's bundled for the cases where the library isn't present locally.

- **The vendored rubygems has been upgraded** to 2.0.0-preview2, which should be 2.0.0 final by release time. This new rubygems has full support for the new default gems that some vendored libaries have been moved into. Other notable changes include `gem search` being a remote search by default, and only `ri` docs being built by default. Good changes all round.

- **The default source encoding is UTF-8 now** (changed from US-ASCII). This means literal strings are unicode by default in 2.0, and the `# coding: utf-8` comment we've grown accustomed to adding isn't required anymore. This is a nice step in the direction of "all unicode all the time". A bunch of other encoding cleanups were made, too -- one example is `Time#to_s`, which returns a string encoded in US-ASCII instead of BINARY.

- **There's a new `#to_h` convention** to mirror `#to_a`. There are less hash-like things than array-like things, so it's not defined in as many places, but one nice addition is `Struct#to_h`, which returns a hash of the struct's keys and values: `Struct.new(:key).new('value').to_h #=> {:key=>"value"}`

- **A new `%i[]` / `%I[]` array literal was added**, which produces an array of symbols, just like `%w[]` & `%W[]` produce arrays of strings. I can't think of many situations where I'd want to use this syntax, but I think it makes sense to have it alongside its string equivalent.

- **`Zlib` supports streaming** when deflating and inflating now, which means large files can be processed without using up huge amounts of memory. This is a particularly nice change because MRI doesn't ever reduce its memory footprint while running -- growing the ruby process to allocate large objects is a one-way thing, even after those objects have been garbage collected.

- **`IO#lines` and friends have been deprecated.** The list-of-string methods on `IO`, `StringIO`, `Zlib::GzipReader` and so on, like `#lines`, `#chars` and `#bytes`, have been deprecated in favour of `#each_line`, etc. This is a nice change, pushing the feel of the enumerating API in the direction of the `#each` / `#each_thing` convention.
