---
layout: "/_post.haml"
title: "better drop-in package support in babushka"
---

This week, I've started using some new logic around packages in [babushka](http://babushka.me) -- a change in what constitutes an "installed" package.

In the past, the `managed` template was the standard one for packages. It operates the package manager on your system to do its job. It considers a dep met if the appropriate packages are installed and the corresponding binaries are in the path.

_Templates are for focusing babushka's DSL, trading generality for concision by wrapping up reuseable `met?` and `meet` logic. There are more details [in the docs](http://babushka.me/how-deps-work)._

It turns out, that check is too strict in practice. What might usually be provided by a package, was built from source that one time on that one box. Across different platforms, the same binary often comes from different sources -- for example, `curl` is part of the OS X distribution, but an optional install on most VPSes.

They seemed like the right checks at the time, but over time, proved to incorrectly attempt a package install too often.

The upshot is that only one part of that check is actually appropriate: whether the correct binaries are present in the path. Where they came from, for the purposes of answering the "Is this dependency met?" question a dep encodes, doesn't matter.

Enter the new `bin` template: its `met?` logic just checks for the presence and correct versions of the binaries you specify, and the package manager is only involved if those binaries are missing and an install is required.

The logic is simple:

![The new 'bin' template](/images/the-bin-template.png)

And the best bit is that you can switch to it trivially, by just renaming existing deps.

![Renaming a 'managed' dep to 'bin'](/images/rename-managed-to-bin.png)

I've found that large trees of deps drop into existing systems much more fluidly, now that babushka exploits pre-existing dependencies no matter their origin.
