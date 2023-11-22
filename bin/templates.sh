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

shite_template_standard_page_wrapper() {
    cat <<EOF
<!DOCTYPE html>
<html lang="en" prefix="og: https://ogp.me/ns#">
  $(shite_template_common_head)
  <body>
    <div id="the-very-top" class="stack center box">
      $(cat -)
      $(shite_template_common_footer)
      <!-- Cloudflare Web Analytics -->
      <script defer src='https://static.cloudflareinsights.com/beacon.min.js'
              data-cf-beacon='{"token": "2a55df7e78f941c29a35207cedd0f66c"}'>
      </script>
      <!-- End Cloudflare Web Analytics -->
    </div>
  </body>
</html>
EOF
}

shite_template_common_default_page() {
    cat <<EOF |
  $(shite_template_common_header)
  <main id="main">
    $(cat -)
  </main>
EOF
    shite_template_standard_page_wrapper
}

shite_template_home_page() {
    cat <<EOF |
  $(shite_template_common_header "${shite_page_data[title]}")
  <main id="main">
    $(cat -)
  </main>
<script async defer src="https://www.recurse-scout.com/loader.js?t=40533398b8c93bb4f3323a170e032e91"></script>
EOF
    shite_template_standard_page_wrapper
}

shite_template_common_head() {
    cat <<EOF
<head>
    $(shite_template_common_meta)
    $(shite_template_common_links)
</head>
EOF
}

shite_template_common_meta() {
    # NOTE: Free text from title summary and tags must all be escaped.

    local og_url=${shite_page_data[canonical_url]:?"Fail. We need fully-qualified URL for opengraph page meta."}
    local title="${shite_page_data[title]:-${shite_global_data[title]}}"
    escaped_title=$(printf "%s" "${title}" | __html_escape)

    local description="${shite_page_data[summary]:-${shite_global_data[description]}}"
    escaped_description=$(printf "%s" "${description}" | __html_escape)

    cat <<EOF
<!-- Some basic hygiene meta-data -->
<title>${escaped_title}</title>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="author" content="${shite_global_data[author]}">
<meta name="description"
      content="${escaped_description}">
<meta name="keywords" content="${shite_global_data[keywords]}">
<meta property="og:title" content="${escaped_title}">
<meta property="og:description" content="${escaped_description}">
<meta property="og:locale" content="en_GB">
<meta property="og:type" content="website">
<meta property="og:url" content="${og_url}">
EOF
}

shite_template_common_links() {
    local canonical_url=${shite_page_data[canonical_url]:?"Fail. Every HTML page must have its canonical url."}
    cat <<EOF
<link rel="stylesheet preload" type="text/css" as="style" href="${shite_global_data[base_url]}/static/css/style.css">
<link href="${shite_global_data[base_url]}/${shite_global_data[feed_xml]}"
      rel="alternate" type="application/rss+xml"
      title="${shite_global_data[title]}">
<link rel="canonical" href="${canonical_url}">
<link rel="icon" type="image/vnd.microsoft.icon" href="${shite_global_data[base_url]}/${shite_global_data[favicon]}">
EOF
}

shite_template_common_header() {
    local title=${1:-${shite_global_data[title]}}
    local subtitle=${shite_page_data[subtitle]:+"<h2>${shite_page_data[subtitle]}</h2>"}
    cat <<EOF
<header id="site-header">
  <div class="box invert stack">
    <div class="with-sidebar site-header">
      <a class="box icon" href="${shite_global_data[base_url]}/index.html">
        <img src="${shite_global_data[base_url]}/${shite_global_data[title_icon]}" loading="lazy" alt="${shite_global_data[title]}">
      </a>
      <div class="stack">
        <h1 class="site-header title">${title}</h1>
        ${subtitle}
        <nav class="cluster site-header site-header:nav-items">
          $(shite_template_common_nav_items)
        </nav>
      </div>
    </div>
  </div>
</header>
EOF
}

shite_template_common_nav_items() {
    # TODO: Add dedicated pages and include into nav
    # <a href="${shite_global_data[base_url]}/talks.html#main">
    # &#10086; demos
    # </a>
    # <a href="${shite_global_data[base_url]}/teaching.html#main">
    # &#10087; workshops
    # </a>
    # <a href="${shite_global_data[base_url]}/work.html#main">
    # &fnof;() hire
    # </a>
    cat <<EOF
<a href="${shite_global_data[base_url]}/index.html">
   &lambda; hello
</a>
<a href="${shite_global_data[base_url]}/posts/index.html">
   &#9753; read
</a>
<a href="mailto:hello@evalapply.org">
   &nbsp;&#x2709; write
</a>
<a href="${shite_global_data[base_url]}/now.html#main">
   &laquo; now &raquo;
</a>
<a href="${shite_global_data[base_url]}/${shite_global_data[feed_xml]}">
   &asymp; feed
</a>
EOF
}

shite_template_common_footer() {
    cat <<EOF
<footer id="site-footer">
  <hr>
  <div class="box invert footer stack">
    <p>&copy; $(date +%Y),
      <a href="http://adityaathalye.com" target="_blank">${shite_global_data[author]}</a>.
      <span>All content licensed
        <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">
          CC BY-SA 4.0
        </a>, except where noted otherwise.
      </span>
      Built with
      <a href="https://github.com/adityaathalye/shite">shite</a>.
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
    local temp_shite_post_body
    temp_shite_post_body="$(mktemp --tmpdir=$(pwd) 'shite_post_body_tmp.XXXXXXXXXX')"
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
local first_published=${shite_page_data[date]:?"Fail. We expect date like $(date -Idate)."}
local latest_published=${shite_page_data[updated]:?"Fail. We expect date like $(date -Idate)."}
local include_toc=${shite_page_data[include_toc]:-"no"}
local canonical_url=${shite_page_data[canonical_url]:?"Fail. Provide canonical url to use for discuss at HN prompt."}

cat <<EOF
<article id="blog-post" class="stack">
  <header>
    <div class="stack">
      <div class="title">${title}</div>
      <div class="cluster post-meta">
           <span>&uarr; <a href="#site-header" rel="bookmark">menu</a></span>
           <span>&darr; <a href="#blog-post-footer" rel="bookmark">discuss</a></span>
           $(if [[ ${include_toc} == "yes" ]]
                then printf "%s" "<span>&darr; <a href=\"#blog-post-toc\" rel=\"bookmark\">toc</a></span>"
             fi)
      </div>
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
  <footer id="blog-post-footer" class="footer stack">
    <nav class="cluster">
      <span>&uarr; <a href="#blog-post" rel="bookmark">title</a></span>
      <span>&uarr; <a href="#site-header" rel="bookmark">menu</a></span>
      <span><b>Y</b> <a href="https://news.ycombinator.com/submitlink?u=$(printf "%s" "${canonical_url}" | __url_encode)&t=$(printf "%s" "${title}" | __url_encode)">discuss at HN</a></span>
      <span>&rarr; <a href="mailto:weblog@evalapply.org">email comments</a></span>
      <span><a class="site-feed"
       href="${shite_global_data[base_url]}/${shite_global_data[feed_xml]}">
       Blog feed</a></span>
    </nav>
    <hr>
    <form class="cluster"
          action="https://buttondown.email/api/emails/embed-subscribe/evalapply"
          method="post" target="popupwindow"
          onsubmit="window.open('https://buttondown.email/evalapply','popupwindow')">
      <span>Occasional newsletter</span>
      <input type="email" name="email" id="bd-email">
      <span>
        <input type="submit" value="Get the eval/apply dispatch">
        <em>(thanks, <a href="https://buttondown.email" target="_blank">Buttondown</a>!)</em>
      </span>
    </form>
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
    local posts_meta_file=${1:?"Fail. We expect posts metadata file, tab-separated fields."}

    cat <<EOF
<nav class="cluster box tag-index-items">
$(cat ${posts_meta_file} |
     cut -f3 | tr ' ' '\n' |
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
    while IFS=$'\t' read -r first_published url_slug_root tags title summary
    do cat <<POSTITEM
<div class="post-index-item with-sidebar-narrow">
  <div class="post-index-item:date">
    ${first_published}
  </div>
  <div class="stack">
    <a href=${shite_global_data[base_url]}/${url_slug_root}/index.html#main
       class="post-index-item:title">
       ${title}
    </a>
    <p class="post-index-item:summary">${summary}</p>
    <div class="cluster">
    $(for tag in ${tags}
      do printf "%s\n" \
           "<a href=\"${shite_global_data[base_url]}/tags/${tag}/index.html#main\"
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
    local posts_meta_file=${1:?"Fail. We expect posts metadata file, tab-separated fields."}
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
    local posts_meta_file=${1:?"Fail. We expect posts metadata file, tab-separated fields."}

    cat <<EOF |
<div class="title">Yes, Your Grace. As you wish, Your Grace. 'tis all here.</div>
<p><em>“I want to stay as close to the edge as I can without going over.
Out on the edge you see all kinds of things you can't see from the center.”</em>
 ― Kurt Vonnegut
</p>
EOF
    shite_template_indices_append_tags_posts "${posts_meta_file}"
}

shite_template_indices_tag_page_index() {
    local tag_name=${1:?"Fail. We expect the tag for which to generate the page."}
    local posts_meta_file=${2:?"Fail. We expect posts metadata file, tab-separated fields."}

    cat ${posts_meta_file} |
        # Filter tag according to the post meta TSV record
        # of the shape first_published$'\t'html$'\t'slug$'\t'tags$'\t'title
        # NOTE: We have to use PCRE (-P) instead of EGREP (-E), because apparently
        # EGREP doesn't have a pattern for the tab characters alone. Bah.
        stdbuf -oL grep -P -e "^[[:digit:]-]+\tposts/.*[\t\s]+${tag_name}[\s\t]+.*$" |
        shite_template_indices_posts_list |
        cat <<EOF
<div class="stack">
  <div class="title">All the posts tagged #${tag_name}</div>
  <nav class="cluster post-meta">
    <span>
      &larr; <a href="${shite_global_data[base_url]}/index.html">back home</a>
    </span>
    <span>
      &uarr; <a href="${shite_global_data[base_url]}/tags/index.html#main">all the tags</a>
    </span>
  </nav>
<hr>
  $(cat -)
</div>
EOF
}

# ####################################################################
# TODO: RSS FEED AND SITEMAP
#
# IMPORTANT: When making any of these XML files, we MUST make text html/xml safe
# Free text from title summary and tags must all be escaped.
#
# It could be a sed one-liner, but it could also be a very badly
# behaved sed one-liner, causing all manner of breakages and bugs.
#
# But we have jq, and jq is neat! Thanks to: https://stackoverflow.com/a/71191653
#
# echo "\"'&<>" | jq -Rr @html
# &quot;&apos;&amp;&lt;&gt;
#
# Maybe do this at the time of writing the metadata file, so xml generation can
# just play dumb?
#
# ####################################################################

__shite_template_rss_feed_items() {
    # Given an input stream of metadata (e.g. TSV, or JSON), return XML
    # for a collection of RSS feed items
    # NOTE: all dates must be RFC822 compliant. Use date -R to ensure this. e.g.
    # $ date -u -R -d"2022-04-29"
    # Fri, 29 Apr 2022 00:00:00 +0000
    while IFS=$'\t' read -r first_published url_slug_root tags title summary
    do
        cat <<EOF
<item>
  <title>${title}</title>
  <link>${shite_global_data[base_url]}/${url_slug_root}/index.html</link>
  <pubDate>$(date -u -R -d"${first_published}")</pubDate>
  <guid>${shite_global_data[base_url]}/${url_slug_root}/</guid>
  <description>${summary}</description>
</item>
EOF
    done
}

shite_template_rss_feed() {
    local posts_meta_file=${1:?"Fail. We expect posts metadata file, tab-separated fields."}

    # Made based on the OG xml generated by hugo.
    # Also cf. https://www.xul.fr/en-xml-rss.html
    # NOTE: use date -R, as lastBuildDate MUST be RFC822 compatible. e.g.
    #   <pubDate>Wed, 02 Oct 2002 08:00:00 EST</pubDate>
    #   <pubDate>Wed, 02 Oct 2002 13:00:00 GMT</pubDate>
    #   <pubDate>Wed, 02 Oct 2002 15:00:00 +0200</pubDate>
    # cf. https://validator.w3.org/feed/docs/error/InvalidRFC2822Date.html
    cat <<EOF |
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">
  <channel>
    <title>${shite_global_data[title]}</title>
    <link>${shite_global_data[base_url]}/</link>
    <description>${shite_global_data[description]}</description>
    <generator>shite -- https://github.com/adityaathalye/shite</generator>
    <language>en-gb</language>
    <lastBuildDate>$(date -R)</lastBuildDate>
    <atom:link href="${shite_global_data[base_url]}/${shite_global_data[feed_xml]}"
               rel="self"
               type="application/rss+xml"/>
    <image>
        <title>${shite_global_data[title]}</title>
        <url>${shite_global_data[base_url]}/${shite_global_data[title_icon_png]}</url>
        <link>${shite_global_data[base_url]}/</link>
    </image>
    $(cat ${posts_meta_file} | __shite_template_rss_feed_items)
  </channel>
</rss>
EOF
    xmllint -  # validate feed
}

__shite_template_sitemap_items() {
    # Given an input stream of metadata (e.g. TSV, or JSON), return XML
    # for a collection of sitemap url items.
    while IFS=$'\t' read -r first_published url_slug_root tags title summary
    do
        cat <<EOF
<loc>${shite_global_data[base_url]}/${url_slug_root}/</loc>
<changefreq>yearly</changefreq>
<priority>0.8</priority>
EOF
    done
}

shite_template_sitemap() {
    # Ref. sample XML sitemap:
    # https://www.sitemaps.org/protocol.html#sitemapXMLExample
    local posts_meta_file=${1:?"Fail. We expect posts metadata file, tab-separated fields."}

    cat <<EOF |
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>${shite_global_data[base_url]}/</loc>
    <lastmod>$(date -Is)</lastmod>
    <changefreq>monthly</changefreq>
    <priority>1.0</priority>
  </url>
  $(cat ${posts_meta_file} | __shite_template_sitemap_items)
</urlset>
EOF
    xmllint - # validate sitemap
}

shite_template_robots_txt() {
    # cf. https://en.wikipedia.org/wiki/Robots_exclusion_standard
    cat <<EOF
User-agent: *
Allow: /

Sitemap: ${shite_global_data[base_url]}/${shite_global_data[sitemap_xml]}
EOF
}
