---
layout: "/_post.haml"
title: "Ermahgerd, Arel merge"
---

asdsdfg

<aside>
For those new to rails, arel is rails' SQL querying engine. Core to arel is per-query / per-clause chainability: "build at your leisure, one scope at a time", it says, "and I'll lazily generate the SQL later, to enumerate the results". Half-assembled scope fragments and queryable result sets can all be passed around, one and the same.
</aside>

An arel query's starting point determines the result: you base each query on the model whose records you want in the results. Whether you're joining or including, or supplying nested conditions, you get a list of user records by starting your query on `User` (or one of its scopes).

This is a good pattern, but I've long wondered how to introduce scopes from other models. If I wanted to start on `User` for a list of user records, but filter with a `Membership` scope, then up until yesterday I thought I was up the creek. But check this out.

---

_To illustrate, here's a stylised portion of our data model at [The Conversation](http://theconversation.edu.au)._

    class User < ActiveRecord::Base
      has_many :collaborations
      has_many :articles, through: :collaborations
    end

Our `User`s are joined to `Article` via `Collaboration`, which has a `role` field with a little scope on it.

    class Collaboration < ActiveRecord::Base
      belongs_to :user
      belongs_to :article
      validates_inclusion_of :role, in: %w[editor author reviewer]
      def self.editorial
        where(role: "editor")
      end
    end

Our `Article` has a scope of its own, returning the articles currently being drafted.

    class Article < ActiveRecord::Base
      has_many :collaborations
      has_many :users, through: :collaborations
      def self.drafting
        where(published_at: nil)
      end
    end

We're storing the role on the join table, as makes sense: role is a per-membership thing. To find all the admin users of a group, in the past, I would have written this query:

    article.users.where(collaborations: {role: "editor"})

This produces nice SQL, but we had to duplicate that `#where` logic from `Collaboration.editorial`. Surely it's better to keep things DRY?

    Collaboration.where(article_id: article.id).editorial.map(&:user)

Yuck, `map` in this context is an `N+1`!, Hey, at least we got to use our `managerial` scope, right?

And here's the problem. To return user records, the query has to start on `User`, and I was under the impression that that meant I couldn't use the `Collaboration.editorial` scope.

Turns out, you _can_ compose the proper query by re-using that scope, even though it's not defined on `User`. Enter `#merge`!

    article.users.merge(Collaboration.editorial)

Combining queries like this (I believe the technical term is _smooshing_&mdash;the queries have been _smooshed_ together) means you can re-use the scopes you have all over the place. Even better, `merge` lets you push much more query logic into scopes than you otherwise could.

The query is the one you'd hope for: it's the same JOIN you'd use if you were writing SQL by hand. You win on two fronts: keeping your querying logic DRY in this case means using your DB like a real DB, too.

    SELECT "users".* FROM "users"
      INNER JOIN "collaborations" ON "users"."id" = "collaborations"."user_id"
      WHERE "collaborations"."article_id" = 1
      AND "collaborations"."role" = 'editor';

Even better, when you merge an association, you merge the condition that defines it as well as the attached scopes.

Given a `Figure` model, to represent the figures within articles:

    class Figure < ActiveRecord::Base
      belongs_to :article
    end

Suppose we want to retrieve all the figures associated with the drafts that a given user is editing. Our constraints: we have to start on on `Figure` because figures are what we want, and we want to pull in logic from `Article` and `Collaboration` scopes. 

    class User < ActiveRecord::Base
      def draft_figures
        Figure.
          joins(:article => :collaborations).
          merge(Article.drafting).
          merge(collaborations.editorial)
      end
    end

Note well: this isn't a class-level scope, it's a list of figures corresponding to a specific user. Even so, we started the query `Figure`-wide, and scoped it to the user by merging the `collaborations` association. That's what narrows this query to the user in question.

It's clean and DRY, and it generates the SQL that you want too:

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
