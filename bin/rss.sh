# Add RSS feed.

shite_rss_items() {
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

shite_rss_feed() {
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
