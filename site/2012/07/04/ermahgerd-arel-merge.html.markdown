---
layout: "/_post.haml"
title: "Ermahgerd, Arel merge"
---

*__tl;dr:__ I don't think `ActiveRecord::Relation#merge` is very widely known; I only just discovered it myself. You should use it all over the place because it is very nice.*

Model scopes are a neat way of stacking up querying logic, keeping it composable. One thing I've often wanted for, though, is a way to use those scopes in other contexts.

Arel's chainability is fantastic: build one scope at a time, and only generate the full SQL query to enumerate the results. Half-assembled scope fragments and queryable result sets can all be passed around, one and the same.

One arel rule-of-thumb is that you start on the model that you'd like to return: whether you're joining or including, or supplying nested conditions, you get a list of user records by starting your query on `User` (or one of its scopes).

This is a good pattern, but it's not obvious how to employ scopes from other models. If I wanted to start on `User` for a list of user records, but filter with a `Membership` scope, then up until yesterday I thought I was up the creek. But check this out.

Here's a stylised part of our data model at [The Conversation](http://theconversation.edu.au). Say I have a User model:

    class User < ActiveRecord::Base
      has_many :collaborations
      has_many :articles, through: :collaborations
      def self.active
        where('users.locked_at IS NULL')
      end
    end

Users are joined to `Content` via `Collaboration`, which has a `role` field with a little scope on it.

    class Collaboration < ActiveRecord::Base
      belongs_to :user
      belongs_to :article
      validates_inclusion_of :role, in: %w[editor author reviewer]
      def self.editorial
        where(role: "editor")
      end
    end

Our `Content` has a scope of its own, returning just the published pieces of content.

    class Article < ActiveRecord::Base
      has_many :collaborations
      has_many :users, through: :collaborations
      def self.drafting
        where('articles.published_at IS NULL')
      end
      def self.published
        where('articles.published_at IS NOT NULL')
      end
    end

We're storing the role on the join table, as makes sense: role is a per-membership thing. To find all the admin users of a group, in the past, I would have written this query:

    article.users.where(collaborations: {role: "editor"})

This produces nice SQL, but we had to duplicate that `#where` logic from `Collaboration.editorial`. Surely it's better to keep things DRY?

    Collaboration.where(article_id: article.id).editorial.map(&:user)

Yuck, `map` in this context is an `N+1`!, Hey, at least we got to use our `managerial` scope, right?

Turns out, you _can_ compose the proper query by re-using the scope, even though it's not defined on the query's base model. Enter `#merge`!

    article.users.merge(Collaboration.editorial)

Combining queries like this (I believe the technical term is _smooshing_&mdash;the queries have been _smooshed_ together) means you can re-use the scopes you have all over the place. Even better, `merge` lets you push much more query logic into scopes than you otherwise could.

The query is the one you'd hope for: it's the same JOIN you'd use if you were writing SQL by hand. You win on two fronts: keeping your querying logic DRY in this case means using your DB like a real DB, too.

    SELECT "users".* FROM "users"
      INNER JOIN "collaborations" ON "users"."id" = "collaborations"."user_id"
      WHERE "collaborations"."article_id" = 1
      AND "collaborations"."role" = 'editor';

Even better, when you merge an association, you merge the condition that defines it as well as the attached scopes.

Given a `Figure` model that represents figures within our articles:

    class Figure < ActiveRecord::Base
      belongs_to :article
    end

Suppose we want to retrieve all the figures associated with the drafts a given user is editing, for review. Our query starts on `Figure` because figures are what we want, drawing on the logic in `Article` and `Collaboration` scopes. No problem for `merge`.

    class User < ActiveRecord::Base
      def draft_figures
        Figure.
          joins(:article => :collaborations).
          merge(Article.drafting).
          merge(collaborations.editorial)
      end
    end

    SELECT "figures".* FROM "figures"
      INNER JOIN "articles"
        ON "articles"."id" = "figures"."article_id"
      INNER JOIN "collaborations"
        ON "collaborations"."article_id" = "articles"."id"
      WHERE "collaborations"."user_id" = 1
      AND "collaborations"."role" = 'editor'
      AND (articles.published_at IS NULL)

<aside>
As much as I love arel, its lack of documentation is a real problem. ([I'm one to talk.](http://babushka.me/sharing-deps)) Aside from stackoverflow, the only good resource I know of is [the AR quering guide](http://guides.rubyonrails.org/active_record_querying.html). It's well written, but it only covers the basics: it gets you started, but doesn't provide enough of a reference to really exploit arel's power.
</aside>

<aside>
Usually when I level up as a programmer, it's because of well-timed stubbornness.

I think "eyes on the prize" (in this case, shipping it) is very important. There are more rabbit holes out there than any one of us can ever leap into.

Having said that, I've always felt the desire to push on those what-ifs: sometimes it's better to say "no, there is a better way", and make finding that better way a blocker.

Of course, sometimes the process ends with a frustrating `git reset --hard`. Can't win 'em all.
</aside>
