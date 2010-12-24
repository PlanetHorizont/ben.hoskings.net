---
layout: post
title: "thanks, hivemelb"
---

As some of you will remember, back in mid-November, [@nathan_scott](http://twitter.com/nathan_scott) [spoke at The Hive](http://thehive.org.au/nathan-sampimon-from-inspire9/) about his experiences founding [Inspire9](http://twitter.com/inspire9) as a freelance web developer. Someone at the event took it upon themselves to pinch my iPad. But through the generosity of the Hive attendees, I have a new one.

So this post is definitely overdue, but better late than never, right?

The iPad was sitting more or less in front of me on the stage; I was deep in conversation with Mikala of [@MiFAgallery](http://twitter.com/MiFAgallery). I happened to notice someone stand up and walk away from just next to where it was sitting, and something about it made me check my iPad was still there---which it wasn't. I glanced about to see if anyone had moved it, and by the time I turned around to spot the potential thief, they were gone.

I darted down to the street, but couldn't see them there either. So I ran back upstairs and told [@pat](http://twitter.com/pat); we grabbed his laptop and fired up [Find My iPad](http://www.apple.com/mobileme/features/find-my-iphone.html). Until then I wasn't really sure that someone had nicked it---I thought maybe a mate had put it in their bag for me---but there it was, moving along the street about a block away.

In my naïveté I thought it might be a good idea to send a message to the iPad. (You can do that with Find My iPad). So I said to the thief that if they reconsidered and brought it back, I'd really appreciate it, along with my phone number and email.

<img src="/images/thanks-hivemelb/map.png" alt="Map around The Order of Melbourne and Melbourne CBD" class="lightboxable" />

By this point [@kealey](http://twitter.com/kealey) had joined the hunt and started [tweeting](http://twitter.com/kealey/status/4475673116672000) [like](http://twitter.com/kealey/status/4475681270403072) [a](http://twitter.com/kealey/status/4476389864505344) [champ](http://twitter.com/kealey/status/4477571194421248). I loaded up Find My iPad on my iPhone and headed down to the street while Kealey and Nathan tracked the iPad's progress on Pat's laptop. We saw it head north from The Order of Melbourne along Elizabeth and onto Royal Parade, along the 19 tram route. Soon it began to move at a tram-like speed. Unbeknownst to me, Hive founder [@lukemccormack](http://twitter.com/lukemccormack) had jumped in a cab and was following the tram up the road. I was on the phone to the police, saying "I can literally pinpoint them on a map".

Our pursuit of the thief was looking promising, with tracking HQ at the order, me on foot and Luke in hot pursuit. But then suddenly, the iPad disappeared from my MobileMe account. (That's what happens if you delete the account from the iPad, or wipe it.) And that was it; there was nothing more we could do. I headed back to the order and changed my passwords.

Luke was really apologetic that something like that would happen at his event. But I doubt anyone would think badly of The Hive because of something like this---I know I certainly don't. At a public event, you get the public, not all of whom are nice like you and I :)

<img src="/images/thanks-hivemelb/chat-with-nathan.png" alt="Chat with Nathan" />

But the next bit was the best bit. The next morning I was chatting to Nathan and he nonchalantly asked me a couple of questions.

Luke and The Hive organised [a pledgie](http://pledgie.com/campaigns/13960) via twitter. Over the following couple of days The Hive community were generous enough to donate me practically enough for a new iPad, which really humbled me. I don't feel like I deserved such amazing generosity.

Later that week, I had a new iPad.

<img src="/images/thanks-hivemelb/new-ipad.jpg" alt="My new iPad" class="lightboxable" />

I believe that the best way to react to something so disproportionately nice is to pay it forward, and so, I'd like to give someone an iPad too. That is, an iPad's worth of cash. But I think it'd be nicer if you decide the cause.

<div id="vote">
  <ul class="results">
  </ul>
</div>

<style type="text/css" media="screen">
  img {
    float: right;
    margin-left: 10px;
  }
  img.lightboxable {
    width: 38%;
  }
</style>

<script type="text/javascript" charset="utf-8">
  head.ready(function() {
    String.prototype.slugify = function() {
      return this.toLowerCase().replace(' ', '-').replace(/[^a-z0-9-]/i, '')
    };
    var get_results = function(callback) {
      $.ajax({
        url: 'http://localhost:3000/results.jsonp',
        dataType: 'jsonp',
        success: callback
      });
    };
    get_results(function(data) {
      $(data).each(function(i, result) {
        $('ul.results').append(
          $('<li />').addClass(result.choice.slugify()).append(
            $('<form />')
              .attr('method', 'post')
              .attr('action', 'http://localhost:3000/vote.jsonp/' + result.choice)
              .append(
                $('<input />').attr('type', 'submit').attr('value', result.choice)
              ).submit(function() {
                var form = $(this);
                $.ajax({
                  url: form.attr('action'),
                  type: 'POST',
                  dataType: 'jsonp',
                  complete: function() {
                    get_results(function(data) {
                      $(data).each(function(i, result) {
                        var add_result_to = function(elem) {
                          return elem.append(
                            $('<p />').html(result.choice),
                            $('<div />')
                              .addClass('result')
                              .data('count', result.count)
                              .append(
                                $('<span />').html(result.count),
                                $('<div />')
                                  .addClass('count')
                                  .css({width: result.count + 'px'})
                              )
                          );
                        };
                        if (form.parents('ul').children('li').filter('.' + result.choice.slugify()).length == 0) {
                          console.log('new result: ' + result.choice);
                          $('ul.results').append(
                            add_result_to($('<li />').addClass(result.choice.slugify()))
                          );
                        } else {
                          console.log('exisitng result: ' + result.choice);
                          add_result_to($('ul.results li.' + result.choice.slugify()));
                        }
                      });
                    });
                  }
                });
                return false;
              })
          )
        );
      });
    });
  });
</script>
