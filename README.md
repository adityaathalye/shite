[![justforfunnoreally.dev badge](https://img.shields.io/badge/justforfunnoreally-dev-9ff)](https://justforfunnoreally.dev)
<a href="https://www.hannahilea.com/blog/houseplant-programming">
  <img alt="Hannah's 'Houseplant Programming Badge' inspired by Ryan's 'Houseplant Programming' coinage" src="https://img.shields.io/badge/%F0%9F%AA%B4%20Houseplant%20-x?style=flat&amp;label=Project%20type&amp;color=1E1E1D">
</a>

shite
---

The little hot-reloadin' static site generator from shell. Assumes Bash 4.4+.

WARNING: Here be yaks!

`shite`'s job is to help me make my website: https://evalapply.org
Thus, `shite`'s scope, (mis)feature set, polish will always be production-grade,
where production is "works on my machine(s)" :)

![much write. such Bash. very hotreload. wow.](demo/shite-demo-02-hotreload-content-edits-5fps-1024px.gif "much write. such Bash. very hotreload. wow.")

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [shite](#shite)
- [Introduction](#introduction)
    - [Dreams and desires](#dreams-and-desires)
    - [Backstory](#backstory)
- [Usage Demo](#usage-demo)
    - [Hot-reloaded shite editing](#hot-reloaded-shite-editing)
        - [hotreload begins](#hotreload-begins)
        - [hotreload content edits](#hotreload-content-edits)
        - [hotreload style edits](#hotreload-style-edits)
        - [hotreload template edits](#hotreload-template-edits)
        - [hot rebuild indices and feeds](#hot-rebuild-indices-and-feeds)
    - [Full site builds](#full-site-builds)
    - [Environment Variables and Debug flags](#environment-variables-and-debug-flags)
- [Design and Internals](#design-and-internals)
    - [File and URL naming scheme](#file-and-url-naming-scheme)
    - [Code organisation](#code-organisation)
    - [Calling the code](#calling-the-code)
    - [Templating system](#templating-system)
    - [Metadata and front matter system](#metadata-and-front-matter-system)
        - [For orgmode content](#for-orgmode-content)
        - [For markdown content](#for-markdown-content)
        - [For html content](#for-html-content)
    - [Bashful Hot Reloading Sans Javascript](#bashful-hot-reloading-sans-javascript)
        - [The event system](#the-event-system)
        - [Liveness criterion](#liveness-criterion)
        - [Hot reload scenarios](#hot-reload-scenarios)
        - [Hot reload behaviour](#hot-reload-behaviour)
    - [Unrealised Ambitions](#unrealised-ambitions)
        - [From any source dir to any publish dir from anywhere on my box](#from-any-source-dir-to-any-publish-dir-from-anywhere-on-my-box)
        - [Hot deployment](#hot-deployment)
        - [Hot deployment with local hot reload](#hot-deployment-with-local-hot-reload)
        - [More creature comforts](#more-creature-comforts)
- [Contributing](#contributing)
- [License](#license)

<!-- markdown-toc end -->

# Introduction

Well, `shite` aims to make websites.

- It is a wee publishing system made of pipelined workflows, optionally driven
  by streams of file events (for the hotreloadin' bits).

- It will not surprise a Perl/PHP gentleperson hacker from the last century.

- It exists because one whistles silly tunes and shaves yaks.

This is baaasically what it does (ref: the `shite_templating_publish_sources` function).

``` shell
cat "${watch_dir}/sources/${url_slug}" |
    __shite_templating_compile_source_to_html ${file_type} |
    __shite_templating_wrap_content_html ${content_type} |
    __shite_templating_wrap_page_html |
    ${html_formatter_fn} |
    tee "${watch_dir}/public/${slug}.html"

```

- It publishes content from org-mode files.
- And html, and markdown.
- It hot-builds.
- It hot-reloads (no Javascript).
- It does neither if you disdain creature comforts.
- It does not _demand_ any server process for local publishing.
- It is quite small.
  ```shell
  # The complete "business logic" is 300-ish lines as of this comment,
  # counted as all lines except comments and blank lines.
  grep -E -v "\s?\#|^$" \
      ./bin/{events,metadata,templating,utils,hotreload}.sh |
     wc -l
  ```
- It is Bash-ful.
- I _like_ it.

Before you get too exshited, may I warn you that the MIT license means I don't
have to give a shite if this little shite maker fails to make your shite work.
[Contributing](#contributing) is replete with more warnings.

And last but not least, I hereby decree that all texsht herein be read in Sean
Connery voish.

## Dreams and desires

In my `shite` dreams, I desire...

- Above all, to keep it (the "business logic") _small_. Small enough to cache,
  debug, and refactor in my head.

- To install and use without superuser permission.

- To _extremely_ avoid toolchains and build dependencies. No gems / npms / venvs
  / what-have-yous. Thus, Bash is the language, because Bash is everywhere. And
  standard packages like `pandoc` or `tidy`, when one needs _specific_ advanced
  functionality.

- Dependency-free templating with plain-ol' HTML set in good ol' heredocs.

- Simple metadata system, content namespacing, static asset organisation etc.

- Web server optional (or any kind of server process for that matter). We aim
  for static sites, after all, which work just fine with `file://` navigation.

- To construct it from small, composable, purely functional, Unix-tool-like
  parts, because I like that sort of stuff a lot.

- To give myself a seamless REPL-like edit-save-build-preview workflow.
  - Hot-build page processing (compile + build on save.)
  - Javascript-free browser hot-reloading. It works. It's terrible. It's awesome!
  - TODO: Potentially also extend the same mechanism to hot-deploy, on git push
    to a private repo on my own VPS somewhere. Maybe.

## Backstory

I accidentally restarted blogging after a long haitus. Before I could get words
into the cloud, I muddled about with "modern" Static Site Generators. Because
WordPress is so last century (or so I told myself). Then I got annoyed by the
SSG Jamstack bespoke templating building etc. magic. Now I am on the dark
path of making this. It is being blogged about at:
[shite: static sites from shell: part 1/2](https://www.evalapply.org/posts/shite-the-static-sites-from-shell-part-1/)

# Usage Demo

I use shite mainly in "hotreload" mode, mainly to write posts (in orgmode) and
live preview them (in Firefox). Less mainly, to hot-preview modifications to
styles and/or page templates. Least mainly, after labouring on a post interminably,
I use it in "don't hotreload" mode to do a full site rebuild.

shite demo examples below.

## Hot-reloaded shite editing

Basically this means that if I create, update, delete any file under `sources`,
it must automatically translate to HTML, be published locally to `public`, and
cause an appropriate page navigation or reload action in the web browser, where
my site is open.

### hotreload begins

![invoke shite in hotreload mode](demo/shite-demo-01-hotreload-begins-5fps-1024px.gif "invoke shite in hotreload mode")

Call the "main" script in a clean new terminal session or tmux pane.

``` shell
./shite.sh
```

It helpfully opens the index file in Firefox, according to the defaults I've set
in `shite_global_data` array in `./shite.sh`.

### hotreload content edits

![hotreload content edits](demo/shite-demo-02-hotreload-content-edits-5fps-1024px.gif "hotreload content edits")

In your Emacs or Vim, open some content file under `sources`. Edit, save, and
watch the content appear in the browser. (Yes specifying Emacs/Vim is goofy,
because I trigger _hot_ actions based on inotify events. Apparently different
editors do file updates differently. I use Emacs or Vim, so I watch for the
events they cause, so it works on my machine. :)).

Frequently the browser remembers the scroll position, which is neat. Sometimes
the hotreload is, well, shite. So I just hit space and save the content file to
trigger hotreload again.

### hotreload style edits

![hotreload style edits](demo/shite-demo-03-hotreload-style-edits-5fps-1024px.gif "hotreload style edits")

Go to some static asset, like a CSS stylesheet. Alter a thing, like background
color value. Save and watch the color change in the browser.

### hotreload template edits

![hotreload template edits](demo/shite-demo-04-hotreload-template-updates-5fps-1024px.gif "hotreload template edits")

Tweak some template fragment in `templates.sh`---say, blog post template. Then
switch to some blog post content file and modify it to trigger page build with
the modified template (e.g. hit space and save).

### hot rebuild indices and feeds

![hot rebuild indices and feeds](demo/shite-demo-05-hotreload-rebuild-indices-feeds-5fps-1024px.gif "hot rebuild indices and feeds")

This is a hack. The root index.org page under sources is special. If I modify it,
then it means I want to rebuild posts lists for the index page, for tags, and
also rebuild related meta-files like the RSS feed, sitemap, robots.txt etc.

## Full site builds

![full site build](demo/shite-demo-06-dont-hotreload-full-site-rebuild-5fps-1024px.gif "full site build")

In a clean new terminal session call `shite.sh` with "no", and optionally
with the `base_url` of the deployment environment:

Rebuild full site for "local" file:/// navigation. Truly "serverless" :)
``` shell
./shite.sh "no"
```

Rebuild full site for publication under my domain.
``` shell
./shite.sh "no" "https://evalapply.org"
```

## Environment Variables and Debug flags

These flags alter the behaviour of the system.

- Setting `SHITE_BUILD` to "hot" will run the event system in "monitor" mode,
  which in turn drives hotreload behaviour. Setting it to "no" will suppress
  browser hotreload.
- Setting `SHITE_DEBUG_TEMPLATES` to "debug" will cause templates to be sourced
  first, before publishing any templated source content.

# Design and Internals

`shite` is quite Unixy inside. Or so I'd like to think.

Code is functional programming-style Bash. Everything is a function. Most
functions are pure functions---little Unix tools in themselves. Most logic
is pipeline-oriented. This works surprisingly well, because
[Shell ain't a bad place to FP](https://www.evalapply.org/posts/shell-aint-a-bad-place-to-fp-part-1-doug-mcilroys-pipeline/).

I also wanted a live interactive REPL-like experience when writing with `shite`,
because I like working in live/interactive runtimes like Clojure and Emacs.

So, `shite` has become this fully reactive event-driven system capable of hot
build-and-reload-on-save.

## File and URL naming scheme

There are three main directory namespaces:

- `sources` housing the "source" content, such as blog posts written in orgmode,
  as well as CSS, Javascript, and other static assets.
- `public` target for the compiled / built artefacts
- `bin` for the shite-building code

The URL naming scheme follows sub-directory structure under `sources`, and is
replicated as-is under the `pubilic` directory structure. Since this is a bog
standard URL namespacing scheme, it also, applies directly to published content.
Like so:

``` text
file:///absolute/path/to/shite/posts/slug/index.html

http://localhost:8080/posts/slug/index.html

https://your-domain-name.com/posts/slug/index.html
```

## Code organisation

All "public" functions are namespaced as `shite_the_func_name`. All "private"
functions are namespaced as `__shite_the_func_name`.

Functions exist to:

  - define common page fragments (meta, header, footer etc.)
  - compose full pages from components, metadata, and body content
  - assemble the site... build and publish sources into public targets
  - detect and process event streams to drive various site building features
    site builds, and browser hot reloading
  - react to processed events and drive hot compile of pages, hot build of site,
    and browser hot reload / navigation
  - provide convenience utilities for manual builds, local development

## Calling the code

In a clean new terminal session:

  - CD to the root of this project
  - Source the dev utility code into the environment. This will bring in all the
    business logic, templates, as well as dev utility functions.
    ```bash
    source ./bin/utils_dev.sh
    ```
  - Hit `shitTABTAB` or `__shiTABTAB` at the command line for autocompletions.
  - Enter `type -a func_name` to print the function's definition and read its API.
  - Set `shite_global_data` and `shite_page_data` as needed.
  - Call functions at the command line. Call them individually, and/or composed
    with other functions to test / exercise parts of the system.

## Templating system

Templates exist for page fragments (like header, footer, navigation), and for
full page definitions (like the default page template). These are written as
plain HTML wrapped in heredocs. `./bin/templates.sh` provides these.

Templates are filled-in with variable data from different sources:
  - Bash associative arrays: `shite_global_data` contains site-wide metadata,
    and `shite_page_data` contains page-specific metadata. Some outside process
    must pre-set these arrays prior to processing any page.
  - stdin: to inject content into the templates that are wrappers for content.
  - function calls: to expand fragments like HTML metadata, links etc.

For example, a full page may be constructed as follows:

```shell
cat ./sample/hello.md |
    pandoc -f markdown -t html |
    cat <<EOF
    <!DOCTYPE html>
    <html>
        <head>
            $(shite_template_common_meta)
            $(shite_template_common_links)
            ${shite_page_data[canonical_url]}
        </head>
        <body ${shite_page_data[page_id]}>
            $(shite_template_common_header)
            <main>
              $(cat -)
            </main>
            $(shite_template_common_footer)
        </body>
    </html>
EOF
```

## Metadata and front matter system

`shite`'s metadata system is defined as key-value pairs. Keys name the metadata
items, and would be associated with whatever value of that type. Examples below.

As noted earlier, run-time metadata is carried in the environment by the
associative arrays `shite_global_data` and `shite_page_data`. These maybe be
populated by direct construction, as well as updated from external sources.

Each page may specify its own metadata in "front matter" at the top of the page.
This will be used in addition page metadata derived from other sources.

`shite` expects us to write front matter using syntax that is compatible with
the given content type, as follows.

### For orgmode content

Use comment lines `# SHITE_META` to demarcate the org-style metadata that `shite`
should also parse as page-specific metadata.

```org
# SHITE_META
#+title: This is a Title
#+slug: this/is/a/slug
#+date: Friday 26 August 2022 03:38:01 PM IST
#+tags: foo bar baz quxx
# SHITE_META
#+more_org_metadata: but not processed as shite metadata
#+still_more_org_metadata: and still not processed as shite metadata

* this is a top level heading

this is some orgmode content

#+TOC: headlines 1 local

** this is a sub heading
   - this is a point
   - this is another point
   - a third point
```

### For markdown content

Write Jekyll-style YAML front matter, boxed between `---` separators.

``` markdown
---
TITLE: This is a Title
slug: this/is/a/slug
DATE: Friday 26 August 2022 03:38:01 PM IST
TAGS: foo BAR baz QUXX
---

# this is a heading

this is some markdown content

## this is a subheading
  - this is a point
  - this is another point
  - a third point
```

### For html content

We can simply use standard `<meta>` tags, that obey this convention:
`<meta name="KEY" content="value">`.

``` html
<meta name="TITLE" content="This is a Title">
<meta name="slug" content="this/is/a/slug">
<meta name="DATE" content="Friday 26 August 2022 03:38:01 PM IST">
<meta name="TAGS" content="foo BAR baz QUXX">

<h1>This is a heading</h1>
<p>This is some text</p>
<h2>This is a subheading</h2>
<p>
  <ul>
    <li>This is a point</li>
    <li>This is another point.</li>
    <li>This is a third point.</li>
  </ul>
</p>
```

## Bashful Hot Reloading Sans Javascript

Here be Yaks!

Being entirely spoiled by Clojure/Lisp/Spreadsheet style insta-gratifying live
interactive workflows, I want hot reload and hot navigate in shite-making too.

But there does not seem to exist a standalone live web development server / tool
that does not also want me to download half the known Internet as dependencies.
As I said before, a thing I *extremely* do *not* want to do.

DuckSearch delivered Emacs impatient-mode, which is quite hot, but I don't want
to hardwire this my Emacs. Luckily, it also delivered this exciting brainwave
featuring 'inotify-tools' and 'xdotool':
[github.com/traviscross/inotify-refresh](https://github.com/traviscross/inotify-refresh)

Hot copy!

Because what could be hotter than my computer slammin' that F5 key *for* me? As
if it *knew* what I really wanted deep down in my heart.

### The event system

The event subsystem is orthogonal to everything else, and composes with the rest
of the system.

The design is bog standard streaming architecture, viz. watch for file system
events, then filter, deduplicate, analyse, and route them (tee) to different
event processors. Currently there are just two such processors; one to compile
and publish the page or asset associated with the event, another to hot reload
the browser (or hot navigate) depending on the same event.

Baaasically this:

``` shell
# detect file events
__shite_detect_changes ${watch_dir} 'create,modify,close_write,moved_to,delete' |
    __shite_events_gen_csv ${watch_dir} |
    # hot-compile-and-publish content, HTML, static, etc.
    tee >(shite_templating_publish_sources > /dev/null) |
    # browser hot-reload
    tee >(__shite_hot_cmd_public_events ${window_id} ${base_url} |
              __shite_hot_cmd_exec)
```

Events are simply a stream of CSV records structured like this:

``` shell
unix_epoch_seconds,event_type,base_dir,sub_dir,url_slug,file_type,content_type`
```

We use different parts of the event record to cause different kinds of actions.

### Liveness criterion

The afore-linked inotify-refresh script tries to *periodically* refresh a set of
browser windows. We, however, want to be *very* eager. Any edit action on our
content files and/or static assets must insta-trigger hot reload/navigate actions
in the browser tab that's displaying our shite.

### Hot reload scenarios

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

### Hot reload behaviour

Since we are making the computer emulate our own keyboard actions, it can mess
with our personly actions. If we stick to writing our shite in our text editor,
and let the computer do the hotreloady thing, we should remain non-annoyed.

## Unrealised Ambitions

There are many Yaks in the world.

### From any source dir to any publish dir from anywhere on my box

For truly pervasive multi-site publishing mojo:

- `shite` should be available on my PATH
- I should be able to configure any source / public pair per site
- Everything else should "just work" as it does

This is a small yak. I'll probably yakshave it soon.

### Hot deployment
Obviously one can use the CI jobs of popular git hosts to trigger `shite` builds.
But why use clunky current-century tech, when we have already advanced to the
state of the art of the late 1900s... fully streaming and fully reactive?

Sarcasam aside, I don't see why the same event system cannot be used to add
hot-deploy support, on a remote machine I run.

On the remote box:

- a web server serves the public pages of the site
- a clone of the site `sources` is enshrined
- the selfsame hotreload process is live against `sources`
  (minus the browser-watching).
- a git checkout auto-triggers on receiving a git push
- which should cause hot-build against the modified sources (with some special
  case to trigger full build if a template changes)

On my local box:

- edit, preview locally with local hotreloadin'
- git commit, push sources to remote
- hit F5 on the appropriate public URL `https://mydomain.com/posts/hello/index.html`
- the hot-build should have completed in the time it takes to get to F5

### Hot deployment with local hot reload

Do something over SSH to bring browser refresh back to local box, in case of hot
deploys to remote server.

- maybe Shell "Session Portability"?
  [video](https://www.youtube.com/watch?v=uqHjc7hlqd0&t=2436s "Video: Shell Session Portability over SSH"),
  [slides](http://talk.jpnc.info/bash_oscon_2014.pdf "Slides: Shell Session Portability over SSH").
- maybe tap the browser hotreload commands and stream only those back to my box,
  with a "server-mode" for hot-publish at the remote box and a "client-mode" for
  hot-reload on my local box?
- maybe I'll find out it all "just work" with Emacs/TRAMP?

### More creature comforts
Maybe some "Dev-ing/Drafting" time setup/Teardown scenario? Maybe a 'dev_server'
function that we use to kick start a new shite writing session?

- xdg-open a new tab in the default browser (say, firefox), and goto the home
  page of the shite based on config.
- xdotool 'set_window --name' to a UUID for the life of the session.
- Close the tab when we kill the dev session.

# Contributing

If you got all the way down here, and _still_ want to contribute...

Why?

Why in the name of all that is holy and good, would you want to? Is it not
blindingly obvious that this is the work of a goofball? Haven't you heard that
Bash is Not Even A Real Programming Language? And isn't it face-slappingly
obvious that your PRs will languish eternally, and your comments will fall into
a nameless void?

Yes, sending patches is a terrible idea.

_But_ please email me your hopes and dreams about your shite maker! I read email
at my firstname dot lastname at gmail.

Together we can whistle silly tunes, and co-yak-shave our respective yaks, in
our own special ways.

May The Source be with us.

# License

This work is dual-licensed under the MIT license and the CC By-SA 4.0 license.

- The Bash source code for making shite is licensed under the MIT license.
- My website's content which I've included in this project, for demo purposes,
  commit is licensed under the Creative Commons Attribution-ShareAlike 4.0
  International License (CC By-SA 4.0).

SPDX-License-Identifier: mit OR cc-by-sa-4.0
