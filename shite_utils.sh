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
          $(${content_proc_fn} ${body_content_file})
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
#   $ shite_build_page /sample/hello-data.html except_html_page_data
#
# Notice that the page_id we declared in hello-data.html gets injected
# into the page. Rejoice a little!
#
# ####################################################################

get_html_page_data() {
    local file_name=${1:?"Fail. We expect a valid file name."}

    # We can commandeer the HTML comment in the first line of a page,
    # to declare a Bash array of data specific to that page.
    sed -E "1s/(<\!--\s+)(\(.*\))(\s+-->)$/\2/;1q"
}

except_html_page_data() {
    local file_name=${1:?"Fail. We expect a valid file name."}

    # If the first line of a page is a comment, elide it, assuming
    # it contains page data relevant only for page build process.
    sed -E "1s/(<\!--\s+)(\(.*\))(\s+-->)$//1"
}


# ####################################################################
# BUILD PUBLIC HTML
#
# By convention we write all processed HTML into the "public" folder.
#
# Try building the sample pages.
#
#   $ ls sample/hello*.html | shite_build_public_html > /dev/null
#
# Also try building some detailed content, mapping to the pages linked
# in the top navigation.
#
#   $ ls content/*.html | shite_build_public_html > /dev/null
#
# Note how this function knows the global data as well as infers / adds
# page-specific data that only it knows at build time, e.g. constructing
# the canonical URL.
#
# ####################################################################

shite_build_public_html() {
    # Given a list of content files, write well-formed HTML into the
    # designated public directory.

    local page_data_fn=${1:-"get_html_page_data"} # assume HTML with expected data
    local content_proc_fn=${2:-"except_html_page_data"} # could be pandoc etc.
    local html_pretty_printer=${3:-"cat"} # could be `tidy -i` etc.

    # Set globally-relevant information that we inject into components,
    # and that we may also use to control site build behaviour.
    local -A shite_data=(
        [title]="A static shite from shell"
        [author]="Yours Truly"
        [description]="In which we work our way to world domination the hard way."
        [keywords]="blog, world domination, being awesome"
        [default_build_env]="dev"
        [url_dev]="http://localhost:8080"
        [url_prod]="https://example.com"
        [publish_dir]="public"
    )

    # Ensure global build parameters are set before processing anything.
    local build_env=${shite_build_env:-${shite_data[default_build_env]}}

    # Process pages one by one.
    while read body_content_file
    do  # Ensure page-specific data is set before processing.
        # The page builder function depends on us doing so before calling it.
        local -A page_data="$(${page_data_fn} ${body_content_file})"
        local slug=$(basename ${body_content_file} | sed -E "s;(.*)(\..*)$;\1;")
        local html_file_name="${slug}.html"

        # Inject page-specific data into page context, that we can infer or set
        # only at the time of building the page.
        page_data+=(
            [slug]="${slug}"
            [canonical_url]="${shite_data[url_${build_env}]}/${html_file_name}"
        )

        # Build page and tee it into the public directory, namespaced by the slug
        shite_build_page ${body_content_file} ${content_proc_fn} |
            ${html_pretty_printer} |
            tee "${shite_data[publish_dir]}/${html_file_name}"
    done
}


# ####################################################################
# SITE PUBLISHING
#
# Convenience functions to remind us what and how to create the full site,
# and publish it to the public directory.
#
# ####################################################################

shite_build_public_static() {
    cp -fr ./static/* ./public
}

shite_build_all_html_static() {
    mkdir -p public # ensure the public dir. exists
    shite_build_public_static
    ls content/*.html |
        shite_build_public_html > /dev/null
    printf "%s\n" \
           "Built and published HTML pages and static files to public/ directory." \
           "cd into it, open index.html and enjoy your website."
}

shite_rebuild_all_html_static() {
    # Rebuild from scratch
    rm -r public/*
    shite_build_all_html_static
}
