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


# ####################################################################
# PAGE TEMPLATE AND BUILDER
#
# Try these invocations with the sample files
#
# $ shite_build_page ./sample/hello.html cat
#
# $ shite_build_page ./sample/hello.md "pandoc -f markdown -t html"
#
# ####################################################################

shite_build_page() {
    # Given a file having body content, and a function to translate it
    # into HTML, return a fully formed page having the HTMLised content.
    # The page builder doesn't assume anything about the type of file.
    # We know the file type, and so we must supply the appropriate tool
    # to process the content into HTML. If the content is already HTML,
    # just pass `cat`!

    local body_content_file=${1:?"Fail. Provide file name of body content to inject into page."}
    local content_proc_fn=${2:?"Fail. Provide util to process content into HTML."}

    # We expect some outside process to set the `page_data` array for us.
    local maybe_page_id=${page_data[page_id]:+"id=\"${page_data[page_id]}\""}
    local maybe_canonical_url=${page_data[canonical_url]:+"<link rel=\"canonical\" href=\"${page_data[canonical_url]}\">"}

    cat <<EOF
<!DOCTYPE html>
<html>
    <head>
        $(shite_meta)
        $(shite_links)
        ${maybe_canonical_url}
    </head>
    <body ${maybe_page_id}>
        $(shite_header)
        <main>
          $(cat ${body_content_file} | ${content_proc_fn})
        </main>
        $(shite_footer)
    </body>
</html>
EOF
}


# ####################################################################
# CONVENTION FOR CONTENT IN HTML FILES
#
# Suppose the first line of a page is an HTML comment, having page data?
# Suppose we literally write down an associative array in Bash? Like so:
#
# <!-- ([page_id]="hello-world-page") -->
# <h1>Hello, world!</h1>
# <p>How are you doing today?</p>
# <p>I'm here.</p>
# <p>And I'm going to take you head-on...</p>
#
# Suppose you stop shivering with fear, and just play along for a bit?
# :D
#
# Now we can do something like this in our shell session:
#
#   $ declare -A page_data="$(get_html_page_data ./sample/hello-data.html)"
#
#   $ shite_build_page ./sample/hello-data.html except_html_page_data
#
# Notice that the page_id we declared in hello-data.html gets injected
# into the page. Rejoice a little!
#
# The "dumbness" of shite_build_page is so nice, that we can even...
#
#   $ declare -A page_data="$(get_html_page_data ./sample/hello-data.md)"
#
#   $ shite_build_page ./sample/hello-data.md "except_html_page_data | pandoc -f markdown -t html"
#
#
# ####################################################################

get_html_page_data() {
    local body_content_file=${1:?"Fail. We expect a valid file name."}

    # We can commandeer the HTML comment in the first line of a page,
    # to declare a Bash array of data specific to that page.
    head -1 ${body_content_file} |
        grep '^<!--' |
        sed -E "s;(<\!--\s+)(.*)(\s+-->)$;\2;"
}

except_html_page_data() {
    local content="$(cat -)"

    __spit_page_content() { printf "%s\n" "${content}"; }

    # If the first line of a page is a comment, elide it, assuming
    # it contains page data relevant only for page build process.
    if __spit_page_content | head -1 | grep -q '^<!--'
    then __spit_page_content | tail +2
    else __spit_page_content
    fi
}
