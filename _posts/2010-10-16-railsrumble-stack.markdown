---
layout: post
title: "railsrumble stack"
---

Here's how I set up a rails stack. If you're railsrumbling this weekend, I hope babushka can save you some time. I'll be loitering around the nearest twitter, so please direct any questions towards [@babushka_app](http://twitter.com/babushka_app) and I'll do my best to help out.

My deps will roll a bundler/passenger3/nginx/postgres stack. If you're using apache or mysql, there might be other deps out there. Or you might be out of luck. I recommend using nginx and/or postgres instead. :)

First, the tl;dr version, to host an app on `example.org`. The commands are for the server except where it says otherwise.

    # as root, on a fresh instance
    bash -c "`wget -O - babushka.me/up/hard`"      # install babushka

    # then, also as root
    babushka 'benhoskings:passwordless ssh logins'
    babushka benhoskings:system                    # publickey-only sshd, etc
    babushka 'benhoskings:user exists'             # create the app's account
    passwd example.org                             # for sudoing later
    su - example.org

    # as example.org
    babushka 'benhoskings:passwordless ssh logins'
    babushka 'benhoskings:passenger deploy repo'   # ~/current deploy target

    # (within your local repo)
    git remote add production example.org@<linode IP>:~/current
    git push production master                     # do a deploy

    # as example.org
    babushka 'benhoskings:rails app'               # The big one

To deploy, just push to the production remote. The deploy repo will accept any branch, and handles creating or switching to it as required, so you can just push any old crap and it will be live.

I recommend creating a branch named `deploy` for this purpose, and merging into it locally before pushing.

---
_Those instructions again, with some commentary_

First, log into your instance as root and install babushka.

    bash -c "`wget -O - babushka.me/up`"

Right, that's ruby, git and babushka all installed. Next, ssh public key. (If you're on a Mac, throw it on your clipboard by running `cat ~/.ssh/id_dsa.pub | pbcopy` locally.)

    babushka 'benhoskings:passwordless ssh logins'

Next, configure some basic system stuff - `sshd` with publickey-only logins for security, a few tools like `screen` & `nmap`, and a `sudo`ing admin group. Since this turns off password logins, if you didn't add your publickey in the previous step, this will lock you out of the server.

    babushka benhoskings:system

Right, that's the system done. Next, you want a user account for your webapp to run as. (Of course, it's easy to configure a user account, but this is nice and consistent and gets the groups right every time.) A good convention is to name the user account after your app's domain, say `example.org`.

    babushka 'benhoskings:user exists'
    passwd example.org
    su - example.org

Next we set up ssh logins for the app user. Everyone who wants to be able to deploy should run this step. (Remember, `cat ~/.ssh/id_dsa.pub | pbcopy`.)

    babushka 'benhoskings:passwordless ssh logins'

And then create the production git repo that we push to in order to deploy. (It has a `post-receive` hook that handles the changeover.)

    babushka 'benhoskings:passenger deploy repo'

Now, on your local machine (for each teammate), add the deploy repo as a remote and push your app to it. You'll see some extra output during the push as the production repo does its thing.

    git remote add production example.org@<linode IP>:~/current
    git push production master

Now you can babushka up a rails stack against your app. As the `example.org` user again:

    babushka 'benhoskings:rails app'

---
To deploy your app, just push to the `production` branch. If you want to add custom deploy-time tasks, you could add them to `~/current/.git/hooks/post-receive`. Or if you like, use capistrano or a similar tool; anything that results in the app being deployed to `~/current` (or whatever path you chose) will work fine.

---
If it fails because you forgot something, remember babushka can run from any start state. So once you've corrected the problem, just run babushka again, and it'll skip everything that's already complete from previous runs. If you're having trouble, or babushka is complaining and you don't think it's your fault, ping [@babushka_app](http://twitter.com/babushka_app) and I'll do my best to help out.

---
_There are some things you'll have to do manually_, like scheduling background tasks.

---
_Once the 'rails app' dep has run_, you'll have to add a DNS entry for your domain. If you just browse to your linode IP, the virtualhost won't match and you'll see 'Welcome to nginx!'. Which is lovely, but won't win you any rails rumbles.

