---
layout: post
title: "adding extended_modules"
---

## {{ page.title }}

It's easy to find the modules included in a given class:

--- ruby
>> String.included_modules
=> [Enumerable, Comparable, Kernel]
---

*Quick update in case you're wondering: including a module makes its methods available as instance methods on the receiving class; extending a class with a module makes the methods available as class methods.*

There's no way to directly query the extended modules of a class, but it's easy to get at the information. There's no such thing as extending a class really—"extending a class" just means including on its metaclass. So:

--- ruby
class Module # Thanks for this fix, Adam
  def metaclass
    class << self; self end
  end
  def extended_modules
    metaclass.included_modules
  end
end
---

And then:

--- ruby
>> String.extended_modules
=> [Kernel]
---

Bam!

