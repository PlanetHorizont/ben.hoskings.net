---
layout: post
title: "multi-line prompts in fish"
---

One thing I've missed since switching to fish is a multi-line prompt. If your prompt has newlines in it, they're stripped out when the prompt is rendered on-screen.

First things first: [here's the patch](http://github.com/benhoskings/fish/commit/3e589050b1ab69e07982fb48e8a3bc80ccf1b09b).

--- diff
  for( i=0; i<al_get_count( &prompt_list); i++ )
  {
    sb_append( &data->prompt_buff, (wchar_t *)al_get( &prompt_list, i ) );
+     if (i + 1 < al_get_count( &prompt_list))
+     {
+       sb_append( &data->prompt_buff, L"\n" );
+     }
  }

  al_foreach( &prompt_list, &free );
---

The reason the newlines are removed arises from the way fish runs subcommands. Rendering the prompt is a call to the `fish_prompt` function, which in turn runs other subcommands like `whoami`, `pwd` and `git ls-files`, depending what you have in your prompt.

When fish receives `fish_prompt`'s output, it splits on `\n` and stores each line in an array, specifically an `array_list_t`. When the output is reassembled by `exec_prompt()` for output to the terminal, however, it joins the lines in the array (that's `prompt_list` in the patch above) back together without any join token, so the line separation is gone.

My patch adds a `\n` after every line but the last, so that the newlines in the original un-split output from `fish_prompt` are re-inserted for rendering.

