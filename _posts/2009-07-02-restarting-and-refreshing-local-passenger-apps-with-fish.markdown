---
layout: post
title: "restarting and refreshing local passenger apps with fish"
---

Running passenger for development is great, but if you're hacking code within a plugin then it's cumbersome to constantly `touch tmp/restart.txt` and refresh your browser, even if you use `tou[UP]` to pick the command from your history.

Using fish and some applescript, you can do it all from your terminal by hitting ⌥R.

    function reload_webkit
      osascript -e 'tell application "WebKit" to do JavaScript \
        "window.location.reload()" in front document'
    end

    function restart_rails_app
      touch tmp/restart.txt
      reload_webkit
    end

    bind \er 'restart_rails_app >/dev/null'
