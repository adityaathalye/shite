#!/usr/bin/env bash
#
# ####################################################################
# FUNCTIONS TO BUILD OUR SHITE PAGES
# ####################################################################
#
# USAGE:
#
# In a new terminal session or tmux pane (i.e. a clean, throwaway environment):
#
# - cd to the root of this project
#
# - add the templates and templating functions to your shell session
#   $ source ./bin/templates.sh
#   $ source ./bin/templating.sh
#
# - call individual functions to see what happens.
#
# CONTENT FILES CONVENTIONS AND PROCESSING:
#
# Content matter can be in orgmode, markdown, or plain html formats.
#
# Each page may specify its own metadata. This will be used in addition
# to global (site-wide) metadata, to fill out templates and/or control page
# processing. Page-specific metadata should be written in syntax that is
# standard for that kind of content.
#
#   $ declare -A shite_page_data="$(__shite_get_page_front_matter ./sample/hello-data.html)"
#
#   $ cat sample/hello-data.html |
#       __shite_drop_page_front_matter |
#       shite_templates_common_default_page
#
# ####################################################################

__shite_get_page_front_matter() {
    # Parse "front matter" of content documents and return a stream of
    # Key,Value CSV pairs. These can be further processed into shite_page_data
    # array or translated to HTML metadata.
    #
    # We want our parsed keys to always be lowercase and obey snake_case. Values
    # can be any case.

    # NOTE: We expect front matter based metadata definitions to be compatible
    # with the given content type.
    #
    # For html content, we can simply use <meta> tags. Whereas, for org and
    # markdown, we define metadata between some well-defined /begin,end/ pair
    # of markers. Given these markers, we can use sed-based multiline processing
    # techniques to parse only the text between the markers.
    # cf. https://unix.stackexchange.com/a/78479
    #
    # The -n flag is required to prevent pattern space printing. This ensures:
    # a) metadata only between the begin/end markers is streamed out,
    # b) only properly demarcated values are set in the array, and
    # c) we don't accidentally set empty keys, which begets errors:
    #   `-bash: shite_page_data[${key}]: bad array subscript`
    #
    # We also use GNU sed extensions `I` to match key tokens regardless of
    # case, but we then convert all those to lowercase using '\L'token'\E'.
    local file_type=${1:?"Fail. We expect file type of the content."}
    case ${file_type} in
        org )
            # Multiline processing of org-style header/preamble syntax, boxed
            # between begin/end markers we have defined. We use org-mode's own
            # comment line syntax to write the begin/end markers.
            # cf. https://orgmode.org/guide/Comment-Lines.html
            sed -n -E \
                -e '/^\#\s+shite_meta/I,/^\#\s+shite_meta/I{/\#\s+shite_meta.*/Id; s/^\#\+(\w+)\:\s+(.*)/\L\1\E,\2/Ip}'
        ;;
        md )
            # Multiline processing of Jekyll-style YAML front matter, boxed
            # between `---` separators.
            sed -n -E \
                -e '/^\-{3,}/,/^\-{3,}/{/^\-{3,}.*/d; s/^(\w+)\:\s+(.*)/\L\1\E,\2/Ip}'
        ;;
        html )
            # Use HTML meta tags and parse them, according to this convention:
            #    <meta name="KEY" content="VALUE">
            # cf. https://developer.mozilla.org/en-US/docs/Learn/HTML/Introduction_to_HTML/The_head_metadata_in_HTML
            sed -n -E \
                -e 's;^\s?<meta\s+name="?(\w+)"?\s+content="(.*)">;\L\1\E,\2;Ip'
        ;;
    esac
}

__shite_set_page_data() {
    # We always set data afresh, because it must be page-specific.
    unset shite_page_data
    declare -Agx shite_page_data

    local file_type=${1:?"Fail. We expect file type of the content."}
    local file_path=${2:?"Fail. We expect full path to the file."}
    local optional_metadata_csv_file=${3}

    # We use input redirection to set values in the *current* environment.
    # One may be tempted to pipeline front matter CSV into this function,
    # but that causes the data to be set in a subshell, which of course,
    # does not mutate the outside environment.
    while IFS=',' read -r key val
    do 1>&2 printf "%s\n" "KEY: ${key}, VAL: ${val}"
       shite_page_data[${key}]="${val}"
    done < <(cat ${file_path} |
                 # Lift page-specific frontmatter metatdata
                 __shite_get_page_front_matter ${file_type} |
                 # Inject additional page-specific metadata
                 cat - ${optional_metadata_csv_file}
            )
}

__shite_compile_source_to_html() {
    # If content has front matter metadata, it is presumed to be
    # in a format that the content
    local file_type=${1:?"Fail. We expect file type of content like html, org, md etc."}

    case ${file_type} in
        html )
            pandoc -f html -t html
            ;;
        md )
            pandoc -f markdown -t html
            ;;
        org )
            pandoc -f org -t html
            ;;
    esac
}

__shite_wrap_content_html() {
    local content_type=${1:?"Fail. We expect content_type such as blog, index, static, or generic."}

    case ${content_type} in
        generic )
            cat -
            ;;
        blog )
            shite_template_posts_article
    esac
}

__shite_wrap_page_html() {
    # Given well-formed body HTML content, punch it into the appropriate
    # page template, to emit a complete, well-formed page.
    shite_template_common_default_page
}

# ####################################################################
# BUILD PUBLIC HTML
#
# By convention we write all processed HTML into the "public" folder.
#
# Try building the sample pages.
#
#   $ ls sample/hello*.html | shite_publish > /dev/null
#
# Also try building some detailed content, mapping to the pages linked
# in the top navigation.
#
#   $ ls content/*.html | shite_publish > /dev/null
#
# Note how this function knows the global data as well as infers / adds
# page-specific data that only it knows at build time, e.g. constructing
# the canonical URL.
#
# ####################################################################

shite_publish() {
    # Analyse events and dispatch appropriate content processing actions.
    # e.g. Punch orgmode blog content through its content processor,
    # or garbage collect a static file from public (published) targety, if its
    # source file is deleted or renamed (moved).
    while IFS=',' read -r timestamp event_type watch_dir sub_dir file_name file_type content_type
    do
        # Set page-specific data into page context, that we can infer only at
        # the time of building the page. The page builder function depends on
        # us doing so before calling it.
        local slug="${sub_dir}/${file_name%\.*}"

        __shite_set_page_data \
            ${file_type} \
            "${watch_dir}/sources/${sub_dir}/${file_name}" \
            <(cat <<<"canonical_url,${shite_global_data[base_url]}/${slug}.html")

        case "${event_type}:${file_type}:${content_type}" in
            DELETE|MOVED_FROM:*:generic )
                # GC public files corresponding to dead content files
                rm -f "${watch_dir}/public/${slug}.html"
                ;;
            *:html|org|md:generic|blog )
                # Proc known types of content files, e.g. compile org blog
                # to HTML, and write it to the public directory
                cat "${watch_dir}/sources/${sub_dir}/${file_name}" |
                    __shite_compile_source_to_html ${file_type} |
                    __shite_wrap_content_html ${content_type} |
                    __shite_wrap_page_html |
                    ${html_formatter_fn} |
                    tee "${watch_dir}/public/${slug}.html"
                ;;
            DELETE|MOVED_FROM:*:static )
                # GC dead static files
                rm -f "${watch_dir}/public/${sub_dir}/${file_name}"
                ;;
            *:*:static )
                # Overwrite public versions of any modified static files
                cp -f \
                   "${watch_dir}/sources/${sub_dir}/${file_name}" \
                   "${watch_dir}/public/${sub_dir}/${file_name}"
                ;;
        esac
    done
}
