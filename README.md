shite
---

The little static site generator from shell. Assumes Bash 4.4+.

- [Introduction](#introduction)
- [Backstory](#backstory)
- [Usage](#usage)
- [Design](#design)
- [Creature Comforts](#creature-comforts)
  - [Bashful Hot Reloading](#bashful-hot-reloading)
  - [Unrealised Ambitions](#unrealised-ambitions)

# Introduction

This is baaasically what it does.

``` shell
cat ${body_content_file} |
    ${content_proc_fn} |
    shite_build_page  |
    ${html_formatter_fn} |
    tee "${shite_global_data[publish_dir]}/${html_output_file_name}"
```

The demo shite looks like this:

| Index page                                                  | About page                                                  | Resume page                                                   |
| ----------------------------------------------------------- | ----------------------------------------------------------- | -----------------------------------------------------------   |
| ![Index page](sample/demo-screenshots/shite-demo-index.png) | ![About page](sample/demo-screenshots/shite-demo-about.png) | ![Resume page](sample/demo-screenshots/shite-demo-resume.png) |

Before you get too exshited, may I warn you that the MIT license means I don't
have to give a shite if this little shite maker fails to make your shite work.

Nothing here will surprise a Perl/PHP gentleperson hacker from the last century.

Also, I hereby decree that all texsht herein be read in Sean Connery voish.

# Backstory

I accidentally restarted blogging after a long haitus. Before I could get words
into the cloud, I muddled about with "modern" Static Site Generators. Because
WordPress is so last century (or so I told myself). Then I got annoyed by the
SSG Jamstack bespoke templating building etc. magic. Now I am going down the dark
path of making this. It is being blogged about at:
[shite: static sites from shell: part 1/2](https://www.evalapply.org/posts/shite-the-static-sites-from-shell-part-1/)

# Usage

## Hot-reloaded workflow

The hot-reloaded workflow expects that the website be open in a browser tab, and
that the tab be visible. It won't work if the site is open but the tab is not
active.

First, open Mozilla Firefox and navigate to, say, the content/index.html page
(file:///path/to/content/index.html).

Open a new terminal session or tmux pane, and call the "main" script.
``` shell
./shite
```

## Manually invoked page builds
In a new terminal session or tmux pane (i.e. a clean, throwaway environment):

- cd to the root of this project

- add the functions to your shell session
  ``` shell
  source ./bin/templating.sh
  ```

- call the convenience function to publish the whole site
  ``` shell
  shite_build_all_html_static
  ```

- open the public directory in your file browser, open index.html and click
  away (assuming nothing broke of course).

See how the workhorse functions ... erm ... workhorse:

- build the site with the available content
  ``` shell
  find content/ -type f -name *.html | shite_build_public_html > /dev/null
  ```

- OR, if you have an html pretty-printer like `tidy`, then:
  ``` shell
  find content/ -type f -name *.html |
      shite_build_public_html \
          shite_proc_html_content \
          shite_tidy_html > /dev/null
  ```

Play! Type `shiTABTAB` to tab-complete utility functions. They are all prefixed
`shite_`. Try calling any of them, for example:

Call the meta component generator context-free.

``` shell
  __shite_meta
```

Now try calling the same function again with context set, e.g.:

``` shell
declare -A shite_global_data=(
  [title]="Foo" [author]="Bar" [description]="Baz" [keywords]="quxx, moo"
  ) && __shite_meta && unset shite_global_data
```

# Design

The implementation is in Bash because Bash is everywhere and one goal is to avoid
dependencies as far as possible. If I manage to stop yak shaving, I hope to enjoy
the result for years and years with no breaking changes.

## FP FTW

I like to write [Functional Programming style Bash](https://www.evalapply.org/posts/shell-aint-a-bad-place-to-fp-part-1-doug-mcilroys-pipeline/).

## Functions exist for

- Common component templates (meta, header, footer etc.)

- Page templates for single pages, to compose components and body content

- Site assembly, to compose multiple pages together


## Run-time Variables include

- `shite_build_env`, which represents the build target (e.g. 'prod' or 'dev')
  This choice can control build steps as well as content/metadata injected.
  Default is 'dev'.

- `shite_global_data`, which is a Bash array of globally-relevant values like
  site title, site author name etc.

- `shite_page_data`, which is a Bash array of data presumed to be specific to the
  current page being processed

# Creature Comforts

Here be Yaks!

## Bashful Hot Reloading

Being entirely spoiled by Clojure/Lisp/Spreadsheet style insta-gratifying live
interactive workflows, I want hot reload and hot navigate in shite-making too.

But there does not seem to exist a standalone live web development server / tool
that does not also want me to download half the known Internet as dependencies.
A thing I *extremely* do *not* want to do.

DuckSearch delivered Emacs impatient-mode, which is quite hot, but I don't want
to hardwire this my Emacs. Luckily, it also delivered this exciting brainwave
featuring 'inotify-tools' and 'xdotool':
[github.com/traviscross/inotify-refresh](https://github.com/traviscross/inotify-refresh)

Hot copy!

Because what could be hotter than my computer slammin' that F5 key *for* me? As
if it *knew* what I really wanted deep down in my heart.

**Liveness criterion**

`shite` hotreload uses streaming architecture.

The afore-linked inotify-refresh script tries to *periodically* refresh a set of
browser windows. We want to be very eager. Any edit action on our content files
and/or static assets must insta-trigger hot reload/navigate actions in the browser
tab that's displaying our shite.

It's baaasically this:

``` shell
__shite_detect_changes ${watch_dir} 'create,modify,close_write,moved_to,delete' |
    __shite_distinct_events |
    __shite_xdo_cmd_gen ${window_id} ${base_url} |
    __shite_xdo_cmd_exec
```

**Hot reload scenarios**

We want to define distinct reload scenarios: Mutually exclusive, collectively
exhaustive buckets into which we can map file events we want to monitor.

If we do this, then we can model updates as a sort of write-ahead-log, punching
events through an analysis pipeline, associate them with the exact-match scenario,
and then finally cause the action. For example:

Refresh current tab when
- static asset create, modify, move, delete

Go home when
- current page deleted

Navigate to content when
- current page content modified
- any content page moved or created or modified

**Hot reload behaviour**

Since we are making the computer emulate our own keyboard actions, it can mess
with our personly actions. If we stick to writing our shite in our text editor,
and let the computer do the hotreloady thing, we should remain non-annoyed.

## Unrealised Ambitions

Maybe some "Dev-ing/Drafting" time setup/Teardown scenario? Maybe a 'dev_server'
function that we use to kick start a new shite writing session?

- xdotool open a new tab in the default browser (say, firefox).
- xdotool goto the home page of the shite based on config.
- xdotool 'set_window --name' to a UUID for the life of the session.
- xdotool close the tab when we kill the dev session
