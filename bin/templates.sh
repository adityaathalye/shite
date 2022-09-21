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
          <main id="main">
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
<link rel="stylesheet" type="text/css" href="${shite_global_data[base_url]}/static/css/style.css">
<link href="${shite_global_data[base_url]}/index.xml" rel="alternate" type="application/rss+xml" title="${shite_global_data[title]}">
EOF
}

shite_template_common_header() {
    cat <<EOF
<header id="site-header">
  <div class="box invert stack">
    <div class="with-sidebar site-header">
      <a class="box icon" href="${shite_global_data[base_url]}/index.html#main">
        <img src="${shite_global_data[base_url]}/${shite_global_data[title_icon]}" alt="${shite_global_data[title]}" />
      </a>
      <div class="stack">
        <div class="site-header">${shite_global_data[title]}</div>
        <nav class="cluster site-header site-header:nav-items">
           <a href="${shite_global_data[base_url]}/posts/hello-world/index.html#main">how it began</a>
           <a href="${shite_global_data[base_url]}/index.html#blog-index-list">how it's going</a>
           <a href="https://github.com/adityaathalye"
              target="_blank" rel="noreferrer noopener">
              who did this?
           </a>
           <a href="${shite_global_data[base_url]}/about.html#main">is he unhireable?</a>
           <a href="#site-footer">contact? feed? newsletter?</a>
        </nav>
      </div>
    </div>
  </div>
</header>
EOF
}

shite_template_common_footer() {
    cat <<EOF
<footer id="site-footer">
<hr>
<div class="box invert footer stack">
  <p> Write to <em>weblog (at) evalapply (dot) org</em>. Made with
      <a href="https://www.gnu.org/software/emacs/">GNU Emacs</a>,
      <a href="https://orgmode.org/">org-mode</a>, and
      <a href="https://github.com/adityaathalye/shite">shite</a>.
  </p>
  <hr>
  <div class="cluster">
    <span>
      <a class="site-feed" href="${shite_global_data[base_url]}/index.xml">
         Get fed
      </a>.
    </span>
  <form class="cluster"
        action="https://buttondown.email/api/emails/embed-subscribe/evalapply"
        method="post" target="popupwindow"
        onsubmit="window.open('https://buttondown.email/evalapply','popupwindow')">
      <input type="email" name="email" id="bd-email">
    <span>
      <input type="submit" value="Get occasional newsletter">
      <em>(thanks, <a href="https://buttondown.email" target="_blank">Buttondown</a>!)</em>
    </span>
  </form>
  </div>
  <hr>
  <p>&copy; copyright $(date +%Y), <a href="https://evalapply.org" target="_blank">${shite_global_data[author]}</a>.
    <span>Except where otherwise noted, content on this site is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">
    Creative Commons Attribution-ShareAlike 4.0 International License
    </a>, the same one used by Wikipedia.</span>
<span><a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">
    <img alt="Creative Commons License" style="border-width:0"
         src="https://i.creativecommons.org/l/by-sa/4.0/80x15.png" />
    </a></span>
  </p>
  <hr>
  <p>
  <script async defer src="https://www.recurse-scout.com/loader.js?t=40533398b8c93bb4f3323a170e032e91"></script>
  </p>
</div>
</footer>
EOF
}

# ####################################################################
# BLOG POST TEMPLATES
# ####################################################################

__shite_template_posts_article_toc_items() {
    # NOTE: the `sed` regex matcher is greedy, and there is no way to alter that.
    #
    sed -n -E -e 's;<(h[[:digit:]]).*\s+id="([[:graph:]]+)">([[:print:]]+)<\/h[[:digit:]]>;<a href="#\2" class="toc-heading:\1">\3<\/a>;p';
}

__shite_template_posts_article_prepend_toc() {
    local temp_shite_post_body="$(mktemp --tmpdir=$(pwd) 'shite_post_body_tmp.XXXXXXXXXX')"
    trap "rm -f ${temp_shite_post_body}" 0 HUP TERM PIPE INT

    cat - > "${temp_shite_post_body}"

    cat <<EOF
<div id="blog-post-toc" class="stack table-of-contents">
  <details class="box invert stack" open>
    <summary>
      <strong>Contents</strong>
    </summary>
    <nav class="stack">
      $(cat ${temp_shite_post_body} | __shite_template_posts_article_toc_items)
    </nav>
  </details>
</div>
<hr>
  $(cat ${temp_shite_post_body})
EOF
}

shite_template_posts_article() {
local title=${shite_page_data[title]:?"Fail. We expect title of the post."}
local summary=${shite_page_data[summary]:?"Fail. We expect a summary. Always summarise."}
local author=${shite_page_data[author]:?"Fail. We expect author."}
local tags=${shite_page_data[tags]:?"Fail. We expect at least one tag."}
local latest_published=$(date -Idate)
local first_published=${shite_page_data[date]:?"Fail. We expect date like ${latest_published} (current date)."}
local include_toc=${shite_page_data[include_toc]:-"no"}

cat <<EOF
<article id="blog-post" class="stack">
  <header>
    <div class="stack">
      <div class="title">${title}</div>
      <div class="cluster post-meta"><span>&uarr; <a href="#site-header" rel="bookmark">menu</a></span>
        $(if [[ ${include_toc} == "yes" ]]
          then printf "%s" "<span>&darr; <a href=\"#blog-post-toc\" rel=\"bookmark\">toc</a></span>"
          fi)</div>
      <div class="summary">${summary}</div>
      <div class="cluster post-meta">
        <span class="author">By: ${author}</span>
        <span class="date">Published: ${first_published}</span>
        <span class="date">Updated: ${latest_published}</span>
        <span class="tags">Tags: $(for t in ${tags}
        do printf " / %s" \
             "<a href=\"${shite_global_data[base_url]}/tags/${t}/index.html#main\">#${t}</a>"
        done)
        </span>
      </div>
      <hr>
    </div>
  </header>
  <section class="stack">
      $(if [[ ${include_toc} == "yes" ]]
        then
          __shite_template_posts_article_prepend_toc
        else
          cat -
        fi)
  </section>
  <footer class="footer">
    <nav class="cluster">
      <span>&uarr; <a href="#blog-post" rel="bookmark">title</a></span>
      <span>&uarr; <a href="#site-header" rel="bookmark">menu</a></span>
    </nav>
  </footer>
</article>
EOF
}

# ####################################################################
# PAGE INDEX CONSTRUCTION
# ####################################################################
# Given a metadata file having a deduped and sorted list of page metadata,
# these templates emit HTML listings of the posts.
#
# We add posts in the root index, and a dedicated index of posts for each tag.
# We also generate tag / topic HTML listings where appropriate.

shite_template_indices_tags_nav() {
    local posts_meta_file=${1:?"Fail. We expect posts metadata file."}

    cat <<EOF
<nav class="cluster box tag-index-items">
$(cat ${posts_meta_file} |
     cut -d ',' -f3 | tr ' ' '\n' |
     sort | uniq -c |
     while read -r tag_count tag_name
     do cat <<TAGITEM
  <a href="${shite_global_data[base_url]}/tags/${tag_name}/index.html#main"
     class="tag-index-item">
  <span class="tag-index-item:name">#${tag_name}</span>
  <span class="tag-index-item:count">/ ${tag_count}</span>
</a>
TAGITEM
  done
)
</nav>
EOF
}

shite_template_indices_posts_list() {
    # Given a metadata list for posts, emit a corresponding HTML list to use
    # as an index. We presume the incoming list is clean and sorted.
    while IFS=',' read -r first_published html_slug tags title
    do cat <<POSTITEM
<div class="post-index-item with-sidebar-narrow">
  <div class="post-index-item:date">
    ${first_published}
  </div>
  <div class="stack">
    <a href=${shite_global_data[base_url]}/${html_slug}#main
       class="post-index-item:title">
       ${title}
    </a>
    <div class="cluster">
    $(for tag in ${tags}
      do printf "%s\n" \
           "<a href=\"${base_url}/tags/${tag}/index.html#main\"
               class=\"post-index-item:tag\">#${tag}</a>"
      done)
    </div>
  </div>
</div>
<hr class="post-index-item:hr">
POSTITEM
    done
}

shite_template_indices_append_tags_posts() {
    local posts_meta_file=${1:?"Fail. We expect posts metadata file."}
    # Wrap in the section wrapper.
    cat <<EOF
<div class="stack">
$(cat -)
<section id="tags-index-list">
  <div class="title box invert">All the topics</div>
  $(shite_template_indices_tags_nav ${posts_meta_file})
</section>
<section id="blog-index-list">
  <div class="title box invert">All the posts</div>
  <div class="stack box">
    $(cat ${posts_meta_file} | shite_template_indices_posts_list)
  </div>
</section>
</div>
EOF
}

shite_template_indices_tags_root_index() {
    local posts_meta_file=${1:?"Fail. We expect posts metadata file."}

    cat <<EOF |
<div class="title">Yes, m'lorx. As you wish m'lorx. It is all here.</div>
<p><em>“I want to stay as close to the edge as I can without going over. Out on the edge you see all kinds of things you can't see from the center.”</em> ― Kurt Vonnegut</p>
EOF
    shite_template_indices_append_tags_posts "${posts_meta_file}"
}

shite_template_indices_tag_page_index() {
    local tag_name=${1:?"Fail. We expect the tag for which to generate the page."}
    local posts_meta_file=${2:?"Fail. We expect posts metadata file."}

    cat ${posts_meta_file} |
        # Filter tag according to the post meta CSV record
        # of the shape first_published,html_slug,tags,title
        stdbuf -oL grep -E -e "^[[:digit:]-]+,.*/index.html,.*${tag_name}.*,.*$" |
        shite_template_indices_posts_list |
        cat <<EOF
<div class="stack">
  <div class="title">All the posts tagged #${tag_name}</div>
  <nav class="cluster post-meta">
    <span>&larr; <a href="${shite_global_data[base_url]}/index.html">back home</a></span>
    <span>&uarr; <a href="${shite_global_data[base_url]}/tags/index.html#main">all the tags</a></span>
  </nav>
<hr>
  $(cat -)
</div>
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
