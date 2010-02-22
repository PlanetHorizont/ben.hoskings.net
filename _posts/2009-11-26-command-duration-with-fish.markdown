---
layout: post
title: "command duration with fish"
---

## {{ page.title }}

It's often useful to see how long a command took to run. I used to have the date and time in my prompt for that reason--I could do some mental arithmetic to find out how long a command took.

But, I've been trying to make my prompt more minimal after being inspired by [@topfunky](http://twitter.com/topfunky)'s zen-like prompt, and the date and time clutter it up.

So, I patched fish to measure how long commands take to run, and write the duration to an environment variable when it's useful (i.e. more than a second).

The patch is in [my fish fork](http://github.com/benhoskings/fish/commit/b7d172719fc0321f384aa1cfb5a68f3295be6a17). Here's the high-level part of it:

--- c
    term_donate();

+   gettimeofday(&time_before, NULL);
+
    eval( cmd, 0, TOP );
    job_reap( 1 );

+   gettimeofday(&time_after, NULL);
+   set_env_cmd_duration(&time_after, &time_before);
+
    term_steal();
---

The call to `eval()` is where the command is run, so that's the call that will block and take time. I'm using `gettimeofday()` to grab a unix timestamp directly before and after the call, and then a new function `set_env_cmd_duration()` to write the `CMD_DURATION` environment variable.

The value in the var is pretty-printed using tiered rounding already, so it's ready to echo as a string in your prompt. For example, for commands that take between 10 seconds and 1 minute:

--- c
swprintf(buf, 16, L"%lu.%01us", secs, usecs / 100000);
---

Which produces output like this, running a `rake spec`:

![fish CMD_DURATION example](/images/fish-cmd-duration.png)


