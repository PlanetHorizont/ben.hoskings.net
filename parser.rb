data = STDIN.read
slug, date, title, body = data.split("\t", 4)
date = date.split(/\s+/).first

File.open("/Users/ben/projects/benhoskin.gs/current/_posts/#{date}-#{slug}.markdown", 'w') {|f|
  f << %Q{---
layout: post
title: "#{title}"
---

## {{ page.title }}

#{body}
}
}
