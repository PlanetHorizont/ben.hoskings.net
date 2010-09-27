---
layout: post
title: "babushka community stats"
---

I've merged a new feature into babushka's `next` branch that adds functionality in a new direction. The changes teach babushka to collectively build a database of the deps that are being run, their success rates, and where to find them. Babushka can query this database over HTTP, so everyone can discover new deps from babushka itself.

Firstly, while I'm pretty excited about this, it's definitely not a finalised design. Your feedback will shape its future.

Secondly, any tool that sends data to a server immediately raises privacy questions, so I'd like to describe the design, and show that it's truly a community database: open, transparent and anonymous.

---

_So, what is it?_ Well, there's a new command, `babushka search`, which queries this database, like so. You can try it out yourself if you switch to the `next` branch:

    babushka 'babushka next'
    babushka search tmbundle

![babushka search example](/images/babushka-search-example.png)

The results show matching deps that others have used, and for each, the number of runs this week, and the proportion of those runs that succeeded. This should give you a feel for what's popular and what's reliable at the moment. For the deps that are in a source on GitHub following the `username/babushka-deps` convention, the command to instantly run that dep is shown too.

_This data is collected by babushka itself._ Whenever babushka finishes running a dep from a public source, it writes some info about the run to a file. Then, whenever babushka is invoked, it asynchronously submits that info to the babushka web service. It's done in the background like this for three reasons:

- If it were synchronous, every babushka run would pause for a second or two while babushka contacted the web service, which would suck.
- It means the files can accumulate when your machine is offline, and be flushed to the web service whenever babushka is next run online.
- You can inspect the files, and see exactly what babushka is sending over the wire.

---

_If this system weren't carefully implemented, it would be a privacy problem._ I've designed the system in a way that I believe is completely transparent. You don't have to trust me in order to use babushka.

- Firstly (and obviously), **babushka is open source**. The calls it makes to the web service are cleanly defined in the code---just grep for `Net::HTTP`.
- Secondly, **the web service is also open source**---the code that runs `babushka.me` (a rails 3 app) is [on github](http://github.com/benhoskings/babushka.me) for all to see.
- **The unsent run info is stored on your machine as an HTTP param string**, so you can see the exact data that will be sent before the fact. They're in `~/.babushka/runs/`. (The info for a given run is sent the next time babushka is run.)
- **Only deps from public sources are reported**---that is, sources whose URIs start with `git://`, like read-only GitHub URIs. So if you have private deps that are stored locally on your machine, or in a private source with a `user@host`-style URI, or anything else, babushka will never submit those to the web service. Only sources pointing to `git://` remotes are considered.
- **The web service API is public**---babushka uses it when it submits runs and queries the database. The web service happily serves up JSON or YAML to anybody.
- **The database itself is public**, for anyone to download [as a postgres dump](http://babushka.me/db/babushka.me.psql). It's freshly exported by the web service whenever required via `babushka 'benhoskings:babushka.me db dump'`. (It's going to get pretty big pretty quickly, but that's a problem for later.)
- Finally, **the data is totally anonymous anyway**, so avenues via which I can appropriate the data for evil purposes are quite limited.

Here's an example. After running `babushka benhoskings:Cucumber.tmbundle`, here is the info written to `~/.babushka/runs`, which is the exact data that will be submitted as HTTP params to `http://babushka.me/runs.json`:

    ⚡ cat ~/.babushka/runs/1285303540.794963
    version=0.6.2&run_at=2010-09-24%2014:45:40%20+1000&system_info=Mac%20OS%20X
    %2010.6.4%20(Snow%20Leopard)&dep_name=Cucumber.tmbundle&source_uri=git://gi
    thub.com/benhoskings/babushka-deps.git&result=ok

Cleaning that up a bit, we can see that all it knows about me is that I'm a Mac user and I'm in GMT+10.

    version=0.6.2
    run_at=2010-09-24 14:45:40 +1000
    system_info=Mac OS X 10.6.4 (Snow Leopard)
    dep_name=Cucumber.tmbundle
    source_uri=git://github.com/benhoskings/babushka-deps.git
    result=ok

Since that endpoint is public, the database is obviously gameable. But, you know, don't do that please.

---

_So, that's my idea_. It's in `next`, it's working, and the database is growing as of now.

I'd love to hear your thoughts on this new feature, and your experience using it. The best ways to get in touch are to tweet at [@babushka_app](http://twitter.com/babushka_app), or send a message to the [mailing list](http://groups.google.com/group/babushka_app/). I'm keen for your feedback to influence how babushka develops. Sharing is awesome.
