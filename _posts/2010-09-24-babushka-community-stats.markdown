---
layout: post
title: "babushka community stats"
---

I've merged a new feature into babushka's `next` branch that adds functionality in a new direction. The changes mean that babushka installs everywhere collectively build a database of which deps are being run, where they came from, and their success rate. Babushka can search this database over HTTP, so everyone can discover new deps from babushka itself.

Firstly, while I'm pretty excited about this, it's definitely not a finalised design. Your feedback will shape its future.

Secondly, any tool that sends data to a server immediately raises privacy questions, so I'd like to describe the design, and show that it's truly a community database: open, transparent and anonymous.

_So, what is it?_ Well, there's a new command, `babushka search`, which queries this database, like so. You can try it out yourself if you switch to the `next` branch:

    babushka 'babushka next'
    babushka search tmbundle

![babushka search example](/images/babushka-search-example.png)

The results show deps others have run that match your query, and for each, the number of runs this week and the proportion that succeeded. This should give you a feel for what's popular and what's reliable at the moment. For the deps that are in a source on GitHub following the `username/babushka-deps` convention, the command to instantly run that dep is shown too.

_This data is collected by babushka itself._ Whenever babushka finishes running a dep from a public source, it logs the run to a file. Whenever babushka is started, it asynchronously submits info from previous runs to the babushka web service. It's done in the background like this for three reasons:

- If it were synchronous, every babushka run would pause for a second or two while babushka contacted the web service, which would suck.
- The files can accumulate when your machine is offline, and be flushed to the web service whenever babushka is next run online.
- You can inspect the files, and see exactly what babushka is sending over the wire.

_Obviously, if this were done wrong, it would be a privacy problem._ I've designed the system in a way that I believe is completely transparent. You don't have to trust me in order to use babushka.

- _Firstly (obviously), babushka is open source._ The calls it makes to the web service are cleanly defined in the code---just grep for `Net::HTTP`.
- _Secondly, the web service is also open source_, so the code that runs `babushka.me` (a rails 3 app) is [on github](http://github.com/benhoskings/babushka.me) for all to see.
- _The run info is stored on your machine as an HTTP param string_, so you can see the exact data that will be sent before the fact. They're in `~/.babushka/runs/`. (The info for a given run is sent the next time babushka is run.)
- _Only deps from public sources are reported_---that is, sources whose URIs are `git://`-style public URIs, like the read-only URIs GitHub provides. So if you have private deps that are stored locally on your machine, or in a git repo behind ssh or similar, babushka will never submit those to the web service.
- _The web has a public API---the one babushka uses_ when it queries the database. It happily serves up JSON or YAML to anybody.
- _The database itself is public_, for anyone to download [as a postgres dump](http://babushka.me/db/babushka.me.psql). It's freshly exported by the web service whenever required via `babushka 'benhoskings:babushka.me db dump'`, so it's no older than 5 minutes. (It's going to get pretty big pretty quickly, but that's a problem for later.)
- _Finally, the data is totally anonymous anyway_, so avenues for me to appropriate the data for evil purposes are quite limited.

Here's an example. After running `babushka benhoskings:Cucumber.tmbundle`, here is the info written to `~/.babushka/runs`, which is the exact data that will be submitted as an HTTP param string to `http://babushka.me/runs.json`:

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

So, that's my idea. It's in `next`, it's working, and the database is growing as of now. I'm keen to hear your feedback, and for that to influence how babushka develops. Sharing is awesome.
