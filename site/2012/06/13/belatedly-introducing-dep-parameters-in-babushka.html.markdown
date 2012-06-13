---
layout: "/_post.haml"
title: "belatedly introducing dep parameters in babushka"
---

One weakness of babushka's DSL has always been that deps weren't parameterised.

It's nice to think of a dep as something vaguely analogous to a method&mdash;with some internal structure, that side-effects usefully in some way. But method arguments, something quite standard in plain ruby (or any language really), had no analogue in the babushka DSL. Amateur hour!

**tl;dr&mdash;** The babushka DSL supports parameterised deps now, they're production-ready, and _old-style vars are deprecated_ as of yesterday.

Here is the little design story behind dep parameters, and some details on how they work.

---

**Babushka has had shared vars since it was a prototype.**

Back when I built them, I went to great effort to make vars as clever as I could. Now that I have the intervening experience, the word "clever" makes me quite nervous.

Vars are a great example of past me [building big](/2012/05/20/fast-well-big-small) for an imagined use case. They look like this:

    dep 'rack app' do
      set :vhost_type, 'unicorn'
      requires 'vhost configured'
    end

    dep 'vhost configured' do
      met? { conf_exists?(var(:vhost_type)) }
      # and so on.
    end

Illustrated above, vars are problematic for another reason: _store-and-call_. When you set state and then invoke some other thing that makes use of that state (above, `set :vhost_type` and `var(:vhost_type)` respectively), that's store-and-call.

To store in this sense is to mutate, and mutability is the root of all evil, or at least, it's shady business. I mean you just don't want to get involved in that kind of behaviour. Passing state around directly is much better, because:

<ul class="pros">
  <li>The data is much more localised: local arguments have a narrow scope; changing something here won't break something over there.</li>
  <li>Arguments are explicit, and hence more discoverable when scanning the code.</li>
  <li>It's the functional way. I'm not working in a pure language, but a man can dream.</li>
</ul>

So vars had to go, in favour of parameters of some kind. But a dep isn't a method, so plain ruby method parameters aren't an option.


---

**I considered a few requirements.**

Bouncing ideas back and forth with [@chendo](http://twitter.com/chendo), the list of priorities emerged: the params have to feel unsurprising, while supporting lazy prompting, and some extra niceties like default values and constrained choices.

This ruled out a few possibilities, the first of which was block arguments on the dep. Had they worked, they would have looked like this:

    dep 'rack app' do
      requires Dep('vhost configured').with('unicorn')
    end

    dep 'vhost configured' do |vhost_type|
      def helper
        vhost_type # argh!
      end
      met? { conf_exists?(vhost_type) }
    end

At first, this seemed like a great idea, but it turned out to be a flawed design.

<ul class="cons">
  <li>Helper methods couldn't see the arguments (block arguments are local variables, which are inaccessible from within methods; see <code>argh!</code> above).</li>
  <li>The arguments' names can't be discovered (on ruby 1.8).</li>
  <li>Their values have to be present when the block is run&mdash;but that block is run once, to define the dep, after which it can be called like a method: repeatedly, with different arguments.</li>
</ul>

I experimented with a couple of other designs too. Per-dep instance variables would have looked nice: a little `@` badge against every var. But not so fast...

<ul class="cons">
  <li>They default to nil. I don't like to use ivars directly because of this; the prospect of typo-induced nils gives me the screaming heebie-jeebies. And since the nil default is at the language level, it's baked in.</li>
  <li>Addressing each ivar by name in order to outfit it with its dep parameter get-up is more metaprogramming than I want to do.</li>
  <li>Most importantly, supplying a value as an argument, and it appears as an instance var? Too surprising.</li>
</ul>

This wasn't going well. Talking it through with [@glenmaddern](http://twitter.com/glenmaddern), we realised that the one thing the design would have to do is side-step language-level restrictions like those above. To achieve laziness, defaults, and so on, we want to run arbitrary code, and to get into that code, the argument has to be a method call.

Once we realised that, the design fell out nicely. A couple of late nights and a few test-driven classes later, and here we are.

---

**The design uses a new notation to define dep parameters:**

    dep 'vhost configured', :vhost_type do
      met? { conf_exists?(vhost_type) }
    end

Each parameter is defined on the dep as an instance method, accessible anywhere within that dep's context. In order to supply values for the parameters, you can pass arguments along with the dep's name, just like a method call. In order to do so I've monkey-patched a core class. The method is `String#with`:

    requires 'vhost configured'.with('unicorn') # positional arguments
    requires 'vhost configured'.with(vhost_type: 'unicorn') # named arguments

<aside>
I decided it was worth polluting String in this way because it means that babushka's string-based declarative style of `requires 'more', 'deps'` can continue. It wouldn't look very nice to have to write `requires Dep('name').with('args')` every time (although you can if you like; that will work).
</aside>

Referencing the parameter (i.e. calling its method) returns a Parameter object representing the value. This object is fairly transparent&mdash;you can mostly refer to it as though it were a raw value. In particular, all of these do what you'd expect:

    "A fine steed" if vhost_type == 'unicorn'
    "A magical #{vhost_type}"
    vhost_type[/corn/]

The Parameter object is there to provide laziness. You never have to supply a parameter's value up-front: its Parameter object will prompt for the value as required (i.e. when something like `#to_s` is called on it). This is nice because values that are never used won't be asked for.

All the settings for vars are present with parameters, too, like defaults and choices. But unlike vars, which accept them as a hash of options, parameters expose them as chainable methods.

    dep 'app bundled', :path, :env do
      path.default('.')
      env.ask('Which environment should be bundled?').default('production')
      # ...
    end


---
**But it's more syntax!**

Local parameters, passed between every dep, do seem like overhead at first. If you've written more than a handful of deps before, though, you'll agree that shared vars are unmanageable over time.

In fact, parameters dotted across your deps are a good thing: think of them as explicit notation for relationships that were already there.

It's ultimately about honesty: concision is a laudable goal, but goals need constraints. In this case, the constraint is honestly representing dependencies of state. To hide that may seem concise, but all it really does is mislead.


---

**Find your messiest dep&mdash; chances are it's a var's fault.**

Firstly, I apologise for that. In hindsight, vars evolved the way they did because I was too short-sighted when I was searching for a concise DSL. In my enthusiasm to make the DSL easy to dive into, I didn't anticipate the chaos that globally accessible vars would incur. Lesson learned!

Secondly, try refactoring that dep and its friends to use dep parameters, and you'll find that `setup { }` blocks and calls to `#set` & `#define_var` and such just fall away. When you can directly pass state around, you're freed from worrying about unintended interactions between shared state that vars inevitably cause.

---

Feedback is always lovely, so direct your thoughts to [@babushka_app](http://twitter.com/babushka_app) or [the mailing list](http://babushka.me/mailing_list).

Share and enjoy! <3
