---
layout: "/_post.haml"
title: "thoughts on dedicated hosting"
---

_This started as a comment on [Mike Perham's excellent post](http://www.mikeperham.com/2014/07/23/building-systems-and-the-cloud) about dedicated hosting over le cloud, but got a bit long, so I thought I'd post it here instead._

I'm in full agreement with Mike. I left my last fulltime position at [The Conversation](http://theconversation.com) having implemented exactly the setup he describes, redundantly: a single box for everything, duplicated exactly on a second continent, with postgres replication between the two.

Before we went dedicated at TC, we'd had occasional blips and problems across a couple of different providers. I sat down one day and said, _OK, what's actually been going wrong here_, which led to a moment of clarity: we'd never seen any of our servers themselves fail. Every single piece of downtime was in the VPS host (typically IO starvation, or a blip in the host's pooled storage), or larger network issues in the datacenter (or country) unrelated to our servers. I reasoned that we could cut all that complexity out by using a single, dedicated box of high quality, and replicate that box exactly to handle the larger network issues, as well as the rare case where the hardware itself fails.

The setup is symmetrical; the boxes are identical and take turns at being the master. The current master is just the one that's currently receiving traffic (and whose database is writable), which makes the failover simple: change a DNS alias, and trigger the standby postgres to become a master. Each app is already connected to its local database, so no app-level failover is required; in fact, the apps don't even see the failover. They just suddenly start seeing traffic (from the DNS alias switch) at the same moment the database, to which they are already connected, becomes writable.

(Postgres is wonderful in that regard, as in all regards; as a standby it's a regular db server that rejects any queries that would cause writes. When triggered to become a master it just starts accepting writes, without interrupting any open connections. God I love postgres.)

I believe this setup provides very good security, because the database doesn't need to be exposed to the network, or even have passwords set: each app runs as its own unix user, so local ident auth over unix domain sockets is enough, and the replication is tunneled over an ssh connection through a dedicated user account with its own public key. Postgres is never visible on the network, and in fact is configured to not even listen on any network.

In practice, neither box has ever failed, or even ever had a hiccup; we've failed over in anger many times but always to sidestep a larger network issue. In fact, once the failing over becomes smooth enough, you can use it for other things too, like major upgrades (e.g. postgres or an app runtime): practice on staging; automate on the standby; failover to make it live.

The one disadvantage I see with this approach is that it couples two concerns together: the same machine being responsible for (possibly several) apps and the database means that diagnosing performance problems can have a couple of extra steps. When they're all on separate boxes, the part of your system having issues is more obvious. But that's a price we've never actually paid in reality, exactly because the resources (particularly IO) are predictably available in plenty.

Spinning up new virtual servers on demand to handle load is neat, but having a production box powerful enough to handle huge spikes on its own is even better.
