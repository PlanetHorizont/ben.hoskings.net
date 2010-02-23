---
layout: post
title: "we can do better than meta"
---

I fixed a really tricky bug this afternoon. I took a roundabout path towards the bug's cause, and used a couple of tools from my ruby toolbox.

So ruby is dynamically typed, for better or worse. I used to think that was a great idea - who cares what something *is*, as long as you know what it *does*, right? Ducks and all that?

Not always the case. I'm starting to think ruby is too permissive. Not only can you not be sure what type an object is until runtime, you can't be sure what the types *themselves* consist of - and they can change from moment to moment.

So here's the problem:

    Scenario: Uploading after logging in
      Given I am logged in as "member@test.org"
        undefined method `context=' for #<Ambition::Adapters::ActiveRecord::Select:0x3523494>

The login step triggers a GET via webrat, and the call to ambition is far below that. About 25 method calls below:

    benhoskings-ambition-0.5.4.3/.../base.rb:122

But the request works fine when hit from the browser---so maybe something's undefining `#context` in the test environment, or similar. In ambition / `base.rb`:

    unless instance.respond_to? :context
      klass.class_eval do
        attr_accessor :context, :negated
        def owner;    @context.owner   end
        def clauses;  @context.clauses end
        def stash;    @context.stash   end
        def negated?; @negated         end
      end
    end

    instance.context = context # line 122

Turns out, it's the reverse. If we already have `#context`, `attr_accessor` (which defines it, along with `#context=`) is never called. But where the hell is `#context` coming from? This test involves rails, hammock, ambition, rspec, cucumber, webrat, machinist, and faker. Oh dear.

So first, OK. Let's just have a look at what that object can do. Just above that `respond_to?` check:

    # What methods does this object have, that aren't common to all objects?
    p instance.methods.sort - Object.methods

Which gives us

    ["both", "call", "chained_call", "dbadapter_name", "downcase", "either", "not_equal", "not_regexp", "quote", "quote_column_name", "quote_string", "quote_table_name", "quoted_date", "quoted_false", "quoted_string_prefix", "quoted_true", "sanitize", "statement", "upcase"]

Which doesn't include `#context`. But `respond_to? :context` must have returned true, otherwise all those methods would have been `class_eval`ed. We'll need a more subtle trick.

    instance.method(:method_missing).owner #=> Kernel

Damn, they must have known we'd check that first. If it's owned by `Kernel`, then no parent or mixin's `#method_missing` can be responding to the `#context` call. How about..

    instance.method(:context).owner #=> Spec::DSL::Main

Aha! `instance` responds to `Spec::DSL::Main#context`. It must have been mixed in by rspec. Let's have a look in its source:

    def describe(*args, &block)
      [ ... ]
    end
    alias :context :describe

Yep, every class responds to `#context` (and `#describe`) when rspec is in the mix. But why doesn't it appear in the `instance.methods` list?

I had to think about this for a bit. It's because *every* class responds to `#context` when rspec is in the mix, including `Object` itself. When we subtracted globally shared methods from the list (`- Object.methods`), `#context` was one of them. Sure enough,

    instance.methods.include? 'context' #=> true

[The fix](http://github.com/benhoskings/ambition/commit/22dba94f1b4ed144b57f3d8dc4a15c91a4c6f65e) is easy - the naming collision can be easily avoided in ambition by checking for `#context=` instead:

    unless instance.respond_to? :context=
      [ ... ]
    end

But there's a good lesson here. Two completely unrelated bits of metaprogramming, each innocuous on their own, colliding and causing mayhem. It might seem like an elegant way to write code, and in some situations it is—but there's got to be a better way. I'm hoping it's [this](http://www.scala-lang.org/).
