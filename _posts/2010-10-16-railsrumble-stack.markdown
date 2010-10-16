---
layout: post
title: "railsrumble stack"
---

Here's how I set up a rails stack. If you're railsrumble-ing this weekend, I hope babushka can save you some time.

My deps will roll a rails3/bundler/passenger3/nginx/postgres stack. If you're using apache or mysql, there might be other deps out there

First, log into your instance as root and install babushka.

    bash -c "`wget -O - babushka.me/up`"

Then configure some basic system stuff - sshd with publickey-only logins for security, a few tools like `screen` and `nmap`, and a `sudo`ing admin group.

    babushka benhoskings:system

Don't log out yet; unless you add your publickey you'll be locked out. Use this:

    babushka 'benhoskings:passwordless ssh logins'

Next, you'll want a user account for your webapp to run as. (Of course, it's easy to configure a user account, but this is nice and consistent and gets the groups right every time.) A good convention is to name the user account after your app's domain, say `example.org`.

    babushka 'benhoskings:user exists'

Next we set up ssh logins for the app user,

    babushka 'benhoskings:passwordless ssh logins'

And then create the production git repo that we push to in order to deploy. It has a `post-receive` hook that handles the changeover.

    babushka 'benhoskings:passenger deploy repo'

Now, on your local machine, add the deploy repo as a remote and push your app to it.

    git remote add production example.org@example.org:~/current
    git push production master

Now you can babushka up a rails stack against your app. As the `example.org` user again:

    babushka 'benhoskings:rails app'


