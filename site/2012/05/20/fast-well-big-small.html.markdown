---
layout: "/_post.haml"
title: "fast/well, big/small"
---

Today I read a great piece [via Twitter](https://twitter.com/mwotton/status/204135518919864320) called [The Tortoise and the Hare](http://www.artima.com/weblogs/viewpost.jsp?thread=51769). In software, it says, we do better to develop well than to develop fast; that initial momentum is quickly lost through mounting technical debt; that when we build complex software, we don't have time _not_ to do it right.

I'm on board with this. I think there's an important corrolary: just as we should build well and not fast, I think we should build small and not big.

Choosing to build well and not fast addresses _how_ we build. Distinct from that is _what_ we choose to build&mdash;or indeed, what we choose not to. In deciding on the what, we have to choose between big and small.

Think about what "building well" means to you. To me, it means organising logic in a bite-sized, functional style. Decoupling, and building for testability. Test driving where it makes sense. Preferring immutability. Minimising surprises. Aiming for simplicity, in the sense of [avoiding interleaving](http://www.infoq.com/presentations/Simple-Made-Easy).

Similarly, think about "building small". To me, building small means prioritising concision over reusability, focused code over generalised code. Thinking ahead, but not coding ahead.

As programmers, or probably more correctly, people with egos, we like to build big. Architecting a glorious shining city of an application or database or API is exciting. This is because we're tricking ourselves: building big often looks a lot like building well.

It's not until you try doing it a few times that you learn just how badly building big pans out.

Our textbooks say that code should be reuseable; that the general case, the one-size-fits-all, and the framework are better. But that's a trick too. Just as it's silly to build a product for a hypothetical market, it's a waste of time to guess at what a reuseable solution might look like: you can't triangulate what it actually is when you don't have enough data points. Better to wait until the code tells you.

So don't worry about writing big, reuseable code. Concentrate instead on writing explicit, simple, thoughtful code. It'll be nicer to work with now; it'll weigh in a lot lighter. And most importantly, if you write your small code well, the work to make it reuseable later is easier to do well too: against a concrete use case.
