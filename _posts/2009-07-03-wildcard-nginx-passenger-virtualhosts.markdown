---
layout: post
title: "wildcard nginx / passenger virtualhosts"
---

## {{ page.title }}

Hosting passenger apps on nginx is easy. If they don't need any specific webserver config, though, it's even easier.

---
server {
  listen 80;
  server_name *.com *.com.au *.net *.org;
  root /home/$host/current/public;
  passenger_enabled on;
}
---

This is particularly useful in a development environment - just set `rails_env development` in the `server { }` block, and [ghost](http://github.com/bjeanes/ghost) the domain to localhost.

You should deploy your app to a directory, and as a user, with the same name as the app's root domain. (You should do this anyway, because it's neat and consistent.)

Don't forget to `chown $host /home/$host/current/config/environment.rb`, to run each app as its own user. (You should do this anyway, because it's good security practice.)

You can't use `server_name *` -- you can only wildcard a domain prefix, not the whole thing.


