shite
---

The little static site generator from shell.

Before you get too exshited, may I warn you that the MIT license means I don't
have to give a shite if this little shite maker fails to make your shite work.

Also, I hereby decree that all texsht herein be read in Sean Connery voish.

# Usage

In a new terminal session or tmux pane (i.e. a clean, throwaway environment):

- cd to the root of this project

- add the functions to your shell session
  $ source ./shite_utils.sh

- build the site with the available content
  $ ls content/*.html | shite_build_public_html > /dev/null

- OR, if you have an html pretty-printer like `tidy`, then:
  $ ls content/*.html |
       shite_build_public_html get_html_page_data except_html_page_data "tidy -q -i" > /dev/null

Play: Try calling a function at the terminal, context-free, e.g.:

  shite_meta

Now try calling it again with context set:

  declare -A shite_data=(
    [title]="Foo" [author]="Bar" [description]="Baz" [keywords]="quxx, moo"
   ) && shite_meta && unset shite_data


# Functions exist for

- Common component templates (meta, header, footer etc.)

- Page templates for single pages, to compose components and body content

- Site assembly, to compose multiple pages together


RUN-TIME VARIABLES INCLUDE:

- `shite_build_env`, which represents the build target (e.g. 'prod' or 'dev')
  This choice can control build steps as well as content/metadata injected.
  Default is 'dev'.

- `shite_data`, which is a Bash array of globally-relevant values like
  site title, site author name etc.

- `page_data`, which is a Bash array of data presumed to be specific to the
  current page being processed
