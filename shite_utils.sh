#!/usr/bin/env bash
#
# ####################################################################
# Functions to make a shite from shell.
# ####################################################################
#
# Usage:
#
# In a new terminal session or tmux pane (i.e. a clean, throwaway environment):
#
# - cd to the root of this project
#
# - add the functions to your shell session
#   $ source ./shite_utils.sh
#
# - call individual functions to see what happens.
#
# ====================================================================


# ####################################################################
# Common component templates
#
# Try calling a function at the terminal, context-free, e.g.:
#
#   shite_meta
#
# Now try calling it again with context set:
#
#   declare -A shite_data=(
#     [title]="Foo" [author]="Bar" [description]="Baz" [keywords]="quxx, moo"
#    ) && shite_meta && unset shite_data
# ####################################################################

shite_meta() {
    cat <<EOF
<!-- Some basic hygiene meta-data -->
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${shite_data[title]}</title>
<meta name="author" content="${shite_data[author]}">
<meta name="description" content="${shite_data[description]}">
<meta name="keywords" content="${shite_data[keywords]}">
EOF
}

shite_links() {
    cat <<EOF
<link rel="stylesheet" href="css/style.css">
EOF
}

shite_header() {
    cat <<EOF
<header id="site-header">
  <h1>${shite_data[title]} by ${shite_data[author]}</h1>
  <nav>
      <span><a href="index.html">Blog</a></span>
      <span><a href="about.html">About</a></span>
      <span><a href="resume.html">Resume</a></span>
  </nav>
  <hr>
</header>
EOF
}

shite_footer() {
    cat <<EOF
<footer>
<hr>
<p>Copyright, ${shite_data[author]} $(date +%Y).</p>
<p>All content is MIT licensed, except where specified otherwise.</p>
</footer>
EOF
}
