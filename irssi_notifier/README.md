# OSX iterm2 irssi Notifier

This little bash script starts a loop trying to fetch (fnotify)[https://scripts.irssi.org/scripts/fnotify.pl] output generated from [https://irssi.org/](irssi) which you got running on a remote host that is accessible through SSH.

When it detects a new notification it tells [terminal-notifier](https://github.com/julienXX/terminal-notifier) (see [homebrew](https://github.com/Homebrew/homebrew/blob/master/Library/Formula/terminal-notifier.rb)) to show a message using OSXs Notification Center, that then can be clicked on to open the active [iterm2](https://www.iterm2.com) that you likely have irssi running in a [screen](https://www.gnu.org/software/screen) on.

## Installation

 * Drop the script in your ```~/bin/``` directory, ```chmod +x``` so that it is executeable.
 * Install the (fnotify plugin)[https://scripts.irssi.org/scripts/fnotify.pl] for irssi

## Starting

Just use:
```
~/bin/irssi_notifier your.host.example.com
```

And that is it!
