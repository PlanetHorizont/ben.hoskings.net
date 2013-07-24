---
layout: "/_post.haml"
title: "speedy rspec with rails"
---

So rails rspec runs are really slow to start up. There are two reasons why:

- Rails is initialised each time, which takes a few seconds
- `db:test:prepare` runs before each run, which is another complete rails initialisation in itself

These delays don't have anything to do with rspec. It's just the nature of the Rails framework—there's a lot of ruby to load, to get the framework off the ground. These tweaks don't make that process any faster, they avoid it---firstly by removing a rails initialisation, and then by moving the delay of another away from each rspec run.

To fix the first, install [spork](http://wiki.github.com/dchelimsky/rspec/spork-autospec-pure-bdd-joy) and configure it in `spec/spec_helper.rb`. Spork keeps an instance of your app running, and listens for connections from a spork-aware `rake spec` run. This removes the Rails startup delay more or less completely, since when you run `rake spec`, spork has your app ready and waiting to run specs transparently via DRb.

As for the second, I don't see any need to run `db:test:prepare` before every run when transactional fixtures are being used. It's simple to disable. Change this

    Spec::Rake::SpecTask.new(:spec => spec_prereq) do |t|

to this

    Spec::Rake::SpecTask.new(:spec) do |t|

in `lib/tasks/rspec.rake`.

With `db:test:prepare` and its subtasks not running, spork there's less than a second of delay before specs start running. In my book, that's close to fast enough to pleasantly run, and get results in realtime. Coupled with autotest, this should mean much snappier pass/fail feedback too.

It seems messy to me to have those tasks defined within the app. In fact, most of the rails testing / speccing setup seems to involve just spraying messy generated code around the place. I think this is an example of something done wrong in spite of the fact that the tests may be passing.

Next, to make ⌘R spec runs in TextMate spork-aware, head to the TextMate preferences and add `--drb` to the `TM_RSPEC_OPTS` variable (creating it if required). I also had to patch the `spec_mate` helper [like so](http://github.com/benhoskings/ruby-rspec.tmbundle/commit/c70b16106cd5ba74e97cc967d0e8f307850cbd28).

Running through spork causes a bit of a performance hit, too---it eliminates the startup delay, but the specs run slower, since there's a DRb back and forth involved for each one. Spork is for running a few tests at a time, or for running through autotest, while you're developing. When you run your full suite, you should stop the spork listener and run them locally at full speed.
