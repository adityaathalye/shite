#!/usr/bin/env bash

# ####################################################################
# TEMPLATES AS HEREDOCS
# ####################################################################
#
# Because, why not?
#
# We expect some outside process to set page-level data and global data
# for us, in arrays `shite_page_data`, and `shite_global_data`. So set
# that data before calling individual functions. e.g.
#
# ( declare -A shite_page_data=([title]=foo [author]=bar [date]=baz);
#   echo "BODY CONTENT" | shite_template_posts_article; )

# ####################################################################
# WHOLE-PAGE TEMPLATES
# ####################################################################
#
# Define heredocs that describe well-formed HTML pages, and fill them out
# using other page fragments / components, global/local data, and (presumably
# well-formed) HTML content received at stdin.
#
# e.g. Set global, page-local data, and call these (from the project root dir):
#
#   cat ./sample/hello.html |
#     shite_template_common_default_page
#
#   cat ./sample/hello.md |
#     pandoc -f markdown -t html |
#     shite_template_common_default_page

shite_template_common_default_page() {
    local maybe_page_id=${shite_page_data[page_id]:+"id=\"${shite_page_data[page_id]}\""}
    local maybe_canonical_url=${shite_page_data[canonical_url]:+"<link rel=\"canonical\" href=\"${shite_page_data[canonical_url]}\">"}

    cat <<EOF
<!DOCTYPE html>
<html lang="en">
    <head>
        $(shite_template_common_meta)
        $(shite_template_common_links)
        ${maybe_canonical_url}
    </head>
    <body ${maybe_page_id}>
      <div id="the-very-top" class="stack center box">
          $(shite_template_common_header)
          <main>
            $(cat -)
          </main>
          $(shite_template_common_footer)
      </div>
    </body>
</html>
EOF
}

shite_template_common_meta() {
    cat <<EOF
<!-- Some basic hygiene meta-data -->
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${shite_global_data[title]}</title>
<!-- <base href="${shite_global_data[base_url]}/./">  -->
<meta name="author" content="${shite_global_data[author]}">
<meta name="description" content="${shite_global_data[description]}">
<meta name="keywords" content="${shite_global_data[keywords]}">
EOF
}

shite_template_common_links() {
    cat <<EOF
<link rel="stylesheet" type="text/css" href="static/css/style.css">
EOF
}

shite_template_common_header() {
    cat <<EOF
<header id="site-header">
  <div class="box invert stack">
    <div class="with-sidebar site-header">
      <a class="box icon" href="index.html">
        <img src="${shite_global_data[base_url]}/static/img/220px-Lisplogo.png" alt="eval/apply" />
      </a>
      <div class="stack">
        <div class="site-header">${shite_global_data[title]}</div>
        <nav class="cluster site-header site-header:nav-items">
           <a href="https://github.com/adityaathalye">who did this?</a>
           <a href="${shite_global_data[base_url]}/posts/hello-world/index.html">why?</a>
           <a href="index.html">how it's going</a>
           <a href="index.xml">occasional RSS feed</a>
           <a href="#footer">occasional newsletter</a>
        </nav>
      </div>
    </div>
  </div>
</header>
EOF
}

shite_template_common_footer() {
    cat <<EOF
<footer>
<hr>
<div class="box invert footer">
  <p>All content is copyright, ${shite_global_data[author]} $(date +%Y),
except where specified otherwise.</p>
  <form class="cluster"
        action="https://buttondown.email/api/emails/embed-subscribe/evalapply"
        method="post" target="popupwindow"
        onsubmit="window.open('https://buttondown.email/evalapply','popupwindow')">
    <label for="bd-email">Occasional newsletter (thanks, <a href="https://buttondown.email"
           target="_blank">Buttondown</a>)</label>
    <input type="email" name="email" id="bd-email">
    <input type="submit" value="Subscribe">
  </form>
</div>
</footer>
EOF
}

# ####################################################################
# BLOG POST TEMPLATES
# ####################################################################

__shite_template_posts_article_toc_items() {
    sed -n -E -e 's;<(h[[:digit:]]).*\s+id="(.*)".*>(.*)</h[[:digit:]]>;<span class="heading:\1"><a href="#\2">\3<\\a></span>;p;'
}

shite_template_posts_article_toc() {
    cat <<EOF
<nav class="table-of-contents">
     $(cat - | __shite_template_posts_article_toc_items)
</nav>
EOF
}

shite_template_posts_article() {
local title=${shite_page_data[title]:?"Fail. We expect title of the post."}
local summary=${shite_page_data[summary]}
local author=${shite_page_data[author]:?"Fail. We expect author."}
local latest_published=$(date -Idate)
local first_published=${shite_page_data[date]:?"Fail. We expect date like ${latest_published} (current date)."}

cat <<EOF
<article id="blog-post" class="stack">
  <header>
    <div class="stack">
      <div class="title">${title}</div>
      <div class="summary">${summary}</div>
      <div class="cluster post-meta">
        <span class="author">By: ${author}</span>
        <span class="date">Published: ${first_published}</span>
        <span class="date">Updated: ${latest_published}</span>
        <span class="tags">Tags: ${shite_page_data[tags]}</span>
      </div>
      <hr>
    </div>
  </header>
  <section class="stack">
      $(cat -)
  </section>
  <footer class="footer">
    <nav>
      <span>^ <a href="#blog-post" rel="bookmark">title</a></span>
      <span>^ <a href="#site-header" rel="bookmark">menu</a></span>
    </nav>
  </footer>
</article>
EOF
}

# ####################################################################
# TODO: RSS FEED
# ####################################################################

shite_template_rss_items() {
    # Given an input stream of metadata (e.g. JSON), return XML
    # for a collection of RSS feed items
    while read shite_post_meta
    do
        cat <<EOF
<item>
  <title>${shite_data[title]}</title>
  <link>${shite_data[title]}</link>
  <link>$(shite_data_get link ${shite_post_meta})</link>
  <description>$(shite_data_get description ${shite_post_meta})</description>
</item>
EOF
    done
}

shite_template_rss_feed() {
    # pinched from https://www.xul.fr/en-xml-rss.html
    <<EOF
<?xml version="1.0" ?>
<rss version="2.0">
<channel>
  <title>$(shite_data_get title)</title>
  <link>$(shite_data_get url)</link>
  <description>$(shite_data_get description)</description>
  <image>
      <url>$(shite_data_get icon)</url>
      <link>$(shite_data_get homeurl)</link>
  </image>
  $(cat -)
</channel>
</rss>
EOF
}
