---
layout: "/_post.haml"
title: "belatedly introducing dep parameters in babushka"
---

One weakness of babushka's DSL has always been that deps weren't parameterised.

It's nice to think of a dep as vaguely analogous to a plain ruby method, in that they both encode a specific job. A dep has internal structure instead of just code, but you invoke a dep to do a job, just like a method.

But method arguments, something quite standard in plain ruby (or any language really), had no analogue in the babushka DSL. Amateur hour!

**tl;dr&mdash;** I've added dep parameters to the babushka DSL, and they're working great. Here is the little design story that led me to them, and some details on how they work.

---

**Babushka has always had shared vars of some kind.**

Back when I built them, I went to great effort to make them as clever as I could. Now that I have the intervening experience, the word "clever" makes me quite nervous.

Vars are sticky: they remember values as defaults for next time, keyed per dep and referencing other vars as required. In hindsight, a great example of me [building big](/2012/05/20/fast-well-big-small) for an imagined use case.

    dep 'rack app' do
      set :vhost_type, 'unicorn'
      requires 'vhost configured'
    end

    dep 'vhost configured' do
      met? { conf_exists?(var(:vhost_type)) }
      [ ... ]
    end

This design is problematic for a more fundamental reason, though: store and call (that is, setting state and then separately making use of that state). It's better to pass state around directly.

<ul class="pros">
  <li>The data is much more localised: local arguments have a narrow scope; changing something here won't break something over there.</li>
  <li>Arguments are explicit, and hence more discoverable when scanning the code.</li>
  <li>It's the functional way. I'm not working in a pure language, but a man can dream.</li>
</ul>

So, shared vars had to go, in favour of parameters of some kind. But a dep isn't a method, so plain ruby method parameters aren't an option.


---

**I considered a few requirements.**

I wanted my parameters to feel as much like normal ruby method args as possible, while supporting lazy prompting, and some extra niceties like default values and constrained choices.

This ruled out a few possibilities immediately, the first of which was block arguments on the outer dep. Had they worked, they would have looked like this:

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
  <li>Helper methods within deps couldn't access the arguments (block arguments are local variables, which are inaccessible from within methods; see `argh!` above).</li>
  <li>Block arguments are a language-level feature; their names can't be discovered (on ruby 1.8), and there's no control: no default values, no restricted choies.</li>
  <li>Most problematically, block args can't be lazily evaluated later; their values have to be present when the dep is defined&mdash;but deps have to be callable like methods, with different arguments each time. To support this, the dep would have to be undefined and redefined for every call. Yuck!</li>
</ul>

I experimented with a couple of other designs too. Per-dep instance variables would have looked nice: a little `@` badge against every var. But not so fast...

<ul class="cons">
  <li>They default to nil. I don't like to use ivars directly because of this; the prospect of typo-induced nils gives me the screaming heebie-jeebies. And since the nil default is at the language level, it's baked in.</li>
  <li>Addressing each ivar by name in order to outfit it with its value is more metaprogramming than I want to do.</li>
  <li>Most importantly, supplying a value as an argument, and it appears as an instance var? Surprising.</li>
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

The Parameter object is there to provide laziness. You never have to provide a parameter's value up-front: its Parameter object will prompt for the value as required (i.e. when something like #to_s is called on it). This is nice because values that are never used won't be asked for.

Local parameters, passed between every dep, does seem like overhead at first. If you've written more than a handful of deps before, though, you'll agree that shared vars are unmanageable over time.

Parameters dotted across your deps are a good thing: it's explicit notation for relationships that were already there.

All the settings for vars are present with parameters, too, like defaults and choices. But unlike vars, which accept them as a hash of options, parameters expose them as chainable methods.

    dep 'app bundled', :path, :env do
      path.default('.')
      env.ask('Which environment should be bundled?').default('production')
      # ...
    end

I've been using dep parameters for a bit now; they're ready to rock. In particular, they're ready to replace vars (deprecation is imminent).

If you find your messiest dep, chances are it's that way because of a var-related workaround you had to make. Firstly, I apologise. Secondly, try converting it to use dep parameters instead, and you'll find that a lot of setup{} blocks, calls to #set & #default, and other similar noise, become unnecessary, because you can just directly pass state around and not worry about unintended interactions between shared state that vars inevitably cause.

Vars have long been an issue. In hindsight, they evolved the way they did because I was too short-sighted when I was searching for a concise DSL. In my enthusiasm to remove as much syntax as possible I didn't anticipate the eventual mess that globally accessible vars would cause. Lesson learned!

Feedback is super welcome, as it always is, to @babushka_app or http://babushka.me/mailing_list. Bugreports are much appreciated - http://github.com/benhoskings/babushka/issues.

Share and enjoy! <3
