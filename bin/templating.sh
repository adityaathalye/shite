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
#   $ declare -A shite_page_data="$(__shite_templating_get_page_front_matter ./sample/hello.html)"
#
#   $ cat ./sample/hello.html |  shite_templates_common_default_page
#
# ####################################################################

__shite_templating_get_page_front_matter() {
    # Parse "front matter" of content documents and return a stream of
    # Key,Value CSV pairs. These can be further processed into shite_page_data
    # array or translated to HTML metadata.
    #
    # We want our parsed keys to always be lowercase and obey snake_case. Values
    # can be any case.
    #
    # NOTE: Metadata syntax.
    #
    # We expect front matter based metadata definitions to be compatible with
    # the given content type.
    #
    # For html content, we can simply use <meta> tags. Whereas, for org and
    # markdown, we define metadata between some well-defined /begin,end/ pair
    # of markers. Given these markers, we can use sed-based multiline processing
    # techniques to parse only the text between the markers.
    # cf. https://unix.stackexchange.com/a/78479
    #
    # NOTE: `sed` flags.
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

__shite_templating_set_page_data() {
    # We always set data afresh, because it must be page-specific.
    unset shite_page_data
    declare -Agx shite_page_data

    local file_path=${1:?"Fail. We expect full path to the file."}
    local file_type=${file_path##*\.} # Remove up to last period, geedily from left
    local optional_metadata_csv_file=${2}

    # NOTE: We use input redirection to set values in the *current* environment.
    # One may be tempted to pipeline front matter CSV into this function, but
    # that causes the data to be set in a subshell, which of course, does not
    # mutate the outside environment.
    while IFS=',' read -r key val
    do shite_page_data[${key}]="${val}"
    done < <(cat ${file_path} |
                 # Lift page-specific frontmatter metatdata
                 __shite_templating_get_page_front_matter ${file_type} |
                 # Inject additional page-specific metadata
                 cat - ${optional_metadata_csv_file}
            )
}

__shite_templating_compile_source_to_html() {
    # If content has front matter metadata, it is presumed to be in a format
    # that the content compiler can safely process and elide or ignore.
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

__shite_templating_wrap_content_html() {
    local content_type=${1:?"Fail. We expect content_type such as blog, index, static, or generic."}
    local watch_dir=${2:?"Fail. We expect watch directory."}
    local posts_meta_file=${3:-"${watch_dir}/posts_meta.csv"}

    case ${content_type} in
        generic )
            cat -
            ;;
        blog )
            shite_template_posts_article
            ;;
        rootindex )
            cat -
            ;;
        blogindex )
            shite_template_indices_append_tags_posts ${posts_meta_file}
            ;;
        * )
            __log_info "__shite_templating_wrap_content_html does not handle the given event."
            ;;
    esac
}

__shite_templating_wrap_page_html() {
    # Given well-formed body HTML content, punch it into the appropriate
    # page template, to emit a complete, well-formed page.

    local content_type=${1:?"Fail. We expect content type."}

    case ${content_type} in
        rootindex )
            shite_template_home_page
            ;;
        * )
            shite_template_common_default_page
            ;;
    esac
}

# ####################################################################
# BUILD PUBLIC HTML
#
# By convention we write all processed HTML into the "public" folder.
#
# This function references global data, and injects page-specific data
# that it gets from events (e.g. URL info) and/or metadata from page
# front matter.
# ####################################################################

shite_templating_publish_sources() {
    # Analyse events and dispatch appropriate content processing actions.
    # e.g. Punch orgmode blog content through its content processor,
    # or garbage collect a static file from public (published) targety, if its
    # source file is deleted or renamed (moved).

    local base_url=${1:?"Fail. We expect base url."}

    __shite_events_select_sources |
        while IFS=',' read -r timestamp event_type watch_dir sub_dir url_slug file_type content_type
        do
            # Set page-specific data into page context, that we can infer only at
            # the time of building the page. The page builder function depends on
            # us doing so before calling it.

            # transform content url_slug -to-> html file name
            local html_url_slug="${url_slug%\.*}.html"
            # transform content url_slug -to-> directory root for the html content
            local url_slug_root="$(dirname ${url_slug})"

            __shite_templating_set_page_data \
                "${watch_dir}/sources/${url_slug}" \
                <(cat <<<"canonical_url,${base_url}/${html_url_slug}")

            case "${event_type}:${file_type}:${content_type}" in
                DELETE:*:generic|MOVED_FROM:*:generic )
                    # GC the specific resource
                    rm -f "${watch_dir}/public/${html_url_slug}"
                    # GC the content's base dir too, IFF it becomes empty
                    # NOTE: `find` is sensitive to sequence of expressions. RTFM
                    # to make sure it is used correctly here.
                    find "$(dirname "${watch_dir}/public/${html_url_slug_root:-'.'}")" \
                         -depth -type d -empty -delete
                    # TODO: Instead of deleting the directory, write an index.html
                    # as an HTML redirect page. In the <head>, put something like...
                    # <meta http-equiv="refresh" content="5; URL=new/fully-qualified/url" />
                    # And in the body, some message like...
                    # <p>Page moved! Redirecting you in 5s. Hurried? Click here.</p>
                    ;;
                *:html:blog|*:org:blog|*:md:blog ) ;&
                *:html:generic|*:org:generic|*:md:generic ) ;&
                *:org:rootindex|*:org:blogindex )
                    # Handy trick to modify templates, without having to restart
                    # our process each time we change template functions.
                    if [[ ${SHITE_DEBUG_TEMPLATES} == "debug" ]]
                    then source "${watch_dir}/bin/templates.sh"
                    fi

                    # Idempotent. Make the slug's root directory IFF it does not exist.
                    mkdir -p "${watch_dir}/public/${url_slug_root}"

                    # Proc known types of content files, e.g. compile org blog
                    # to HTML, and write it to the public directory
                    cat "${watch_dir}/sources/${url_slug}" |
                        __shite_templating_compile_source_to_html ${file_type} |
                        __shite_templating_wrap_content_html ${content_type} ${watch_dir} |
                        __shite_templating_wrap_page_html ${content_type} \
                            > "${watch_dir}/public/${html_url_slug}"

                    # We want blogindex page updates to also mean "please hot-build
                    # other site-wide stuff like tags indices, RSS feed etc."
                    if [[ "${file_type}:${content_type}" == "org:blogindex" ]]
                    then local posts_meta_file="${watch_dir}/posts_meta.csv"

                         # PER TAG index pages of posts, from tab-separated records
                         # of post metadata
                         cut -f3 ${posts_meta_file} |
                             tr ' ' '\n' | grep -v "^$" | sort -u |
                             while read -r tag_name
                             do local tag_dir="${watch_dir}/public/tags/${tag_name}"

                                mkdir -p "${tag_dir}"

                                shite_template_indices_tag_page_index \
                                    ${tag_name} ${posts_meta_file} |
                                    __shite_templating_wrap_page_html ${content_type} \
                                        > "${tag_dir}/index.html"
                             done

                         # ALL TAGS root index page of posts
                         shite_template_indices_tags_root_index ${posts_meta_file} |
                             __shite_templating_wrap_page_html ${content_type} \
                                 > "${watch_dir}/public/tags/index.html"

                         # FEEDs and SITEMAP etc.
                         shite_template_rss_feed \
                             ${posts_meta_file} \
                             > "${watch_dir}/public/${shite_global_data[feed_xml]}"

                         shite_template_sitemap \
                             ${posts_meta_file} \
                             > "${watch_dir}/public/${shite_global_data[sitemap_xml]}"

                         shite_template_robots_txt \
                             > "${watch_dir}/public/robots.txt"
                    fi
                    ;;
                DELETE:*:static|MOVED_FROM:*:static )
                    # GC dead static files
                    rm -f "${watch_dir}/public/${url_slug}"
                    ;;
                *:*:generic ) ;&
                *:*:static )
                    # Idempotent. Make the slug's root directory IFF it does not exist.
                    mkdir -p "${watch_dir}/public/${url_slug_root}"

                    # Overwrite public versions of any modified generic, or static
                    # files, or create them if they don't exist.
                    cp -u \
                       "${watch_dir}/sources/${url_slug}" \
                       "${watch_dir}/public/${url_slug}"
                    ;;
                * )
                    __log_info "shite_templating_publish_sources does not handle the given event."
                    ;;
            esac
        done
}
