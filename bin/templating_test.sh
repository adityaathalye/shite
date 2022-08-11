#!/usr/bin/env bash

source ./templating.sh

# Test metadata parsing for org, md, html formats. We want our
# parsed keys to always be lowercase. Values can be any case.

# orgmode metada parsing:
# We rely on standard org buffer header metadata syntax.
cat <<'EOF' |
# SHITE_META
#+TITLE: This is a Title
#+slug: this/is/a/slug
#+DATE: Friday 26 August 2022 03:38:01 PM IST
#+TAGS: foo BAR baz QUXX
# SHITE_META
#+more_org_metadata: but not processed as shite metadata
#+still_more_org_metadata: and still not processed as shite metadata

* this is a heading

this is some orgmode content

#+TOC: headlines 1 local

** this is a subheading
- this is a point
- this is another point
- a third point
EOF
__shite_get_page_front_matter org


# markdown metada parsing:
# We rely on Jekyll-styl YAML front matter syntax.
cat <<'EOF' |
---
TITLE: This is a Title
slug: this/is/a/slug
DATE: Friday 26 August 2022 03:38:01 PM IST
TAGS: foo BAR baz QUXX
---
TAGS: these should not appear in our metadata
date: Friday 26 August 2022 05:32:36 PM
title: This is not a Title
slug: this/is/NOT/a/slug

# this is a heading

this is some markdown content

## this is a subheading
  - this is a point
  - this is another point
  - a third point
EOF
__shite_get_page_front_matter md


# html metadata parsing:
# We rely on standard meta tags with this convention for key/value pair:
# <meta name="KEY" content="value">
cat <<'EOF' |
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
EOF
__shite_get_page_front_matter html
