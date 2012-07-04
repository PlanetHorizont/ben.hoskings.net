---
layout: "/_post.haml"
title: "Arel scopes everywhere"
---


Model scopes are a neat way of stacking up querying logic, keeping it composable. One thing I've often wanted for, though, is a way to use those scopes in other contexts.

Arel's arbitrarily chainable are fantastic: the query built one scope at a time, and only converted to SQL when the results are enumerated. Because of this, half-assembled scope fragments and queryable result sets can all be passed around, one and the same.

One arel rule-of-thumb is that you start on the model that you'd like to return: whether you're joining or including, or supplying nested conditions, you get a list of user records by starting your query on `User` (or one of its scopes).

This is a good pattern, but it's not obvious how to employ scopes from other models. If I wanted to start on `User` for a list of user records, but filter with a `Membership` scope, then up until yesterday I thought I was up the creek. But check this out.

Here's a stylised part of our data model at [The Conversation](http://theconversation.edu.au). Say I have a User model:

    class User < ActiveRecord::Base
      has_many :collaborations
      def self.active
        where('users.locked_at IS NULL')
      end
    end

Users are joined to `Content` via `Collaboration`, which has a `role` field with a little scope on it.

    class Collaboration < ActiveRecord::Base
      belongs_to :user
      belongs_to :content
      validates_inclusion_of :role, in: %w[editor author reviewer]
      def self.editorial
        where(role: %w[editor])
      end
    end

Our `Content` has a scope of its own, returning just the published pieces of content.

    class Content < ActiveRecord::Base
      has_many :collaborations
      has_many :users, through: :collaborations
      def self.published
        where('users.published_at IS NOT NULL')
      end
    end

We're storing the role on the join table, as makes sense: role is a per-membership thing. To find all the admin users of a group, in the past, I would have written this query:

    group.users.where(memberships: {role: %w[manager admin]})

    SELECT "users".* FROM "users"
      INNER JOIN "memberships" ON "users"."id" = "memberships"."user_id"
      WHERE "memberships"."group_id" = 1
      AND "memberships"."role" IN ('manager', 'admin')

Nice SQL, but the same `#where` logic gets scattered all over the place. Surely it's better to keep things DRY?

    Membership.where(group_id: group.id).managerial.map(&:user)

    SELECT "memberships".* FROM "memberships"
      WHERE "memberships"."group_id" = 1
      AND "memberships"."role" IN ('manager', 'admin')
    SELECT "users".* FROM "users" WHERE "users"."id" = 2 LIMIT 1
    SELECT "users".* FROM "users" WHERE "users"."id" = 1 LIMIT 1
    SELECT ...

Yuck, N+1!, Hey, at least we got to use our `managerial` scope, right?

Turns out, you can have your cake and eat it too. Enter `#merge`!

    group.users.merge(Membership.managerial)

Combining queries like this (I believe the technical term is _smooshing_&mdash;to _smoosh_ the queries together) means you can re-use the scopes you have all over the place. Even better, you can push query logic into _new_ scopes for re-use.

    SELECT "users".* FROM "users"
      INNER JOIN "memberships" ON "users"."id" = "memberships"."user_id"
      WHERE "memberships"."group_id" = 1
      AND "memberships"."role" IN ('manager', 'admin')

Because `#merge` generates the same single JOIN query you'd get with the first example, you win on two fronts: keeping your querying logic DRY in this case means using your DB like a DB, too.

Even better, you can merge an arbitrary scope, or even an association, and everything falls out how you'd hope it does.

<aside>
As much as I love arel, its lack of documentation is a real problem. ([I'm one to talk.](http://babushka.me/sharing-deps)) Aside from stackoverflow, the only good resource I know of is [the AR quering guide](http://guides.rubyonrails.org/active_record_querying.html). It's well written, but it only covers the basics: it gets you started, but doesn't provide enough of a reference to really exploit arel's power.
</aside>

<aside>
Usually when I level up as a programmer, it's because of well-timed stubbornness.

I think "eyes on the prize" (in this case, shipping it) is very important. There are more rabbit holes out there than any one of us can ever leap into.

Having said that, I've always felt the desire to push on those what-ifs: sometimes it's better to say "no, there is a better way", and make finding that better way a blocker.

Of course, sometimes the process ends with a frustrating `git reset --hard`. Can't win 'em all.
</aside>
