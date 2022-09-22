#!/usr/bin/env bash

__shite_metadata_make_posts_index_csv() {
    local watch_dir=${1:?"Fail. We expect watch dir."}
    local posts_meta_file=${2:-"posts_meta.csv"}

    # Look up only published posts, and then infer org-mode source files for those
    find ${watch_dir}/public/posts/ -type f -name index.html |
        sed -E -e 's;(.*)/public/(.*)/index.html;\1,\2;' |
        # Write metadata for each source file into a CSV record
        while IFS=',' read -r watch_dir url_slug_root
        do
            # gah, ugly hack :/ but we want to construct the CSV in a particular order
            local source_file="${watch_dir}/sources/${url_slug_root}/index.org"
            if [[ -f "${source_file}" ]]
            then
                __shite_templating_set_page_data "${source_file}"

                # Construct CSV record
                printf "%s" \
                       "${shite_page_data[date]}," \
                       "${url_slug_root}/index.html," \
                       "${shite_page_data[tags]}," \
                       "${shite_page_data[title]}"
                printf "\n"
            fi
        done |
        stdbuf -oL grep -v "^$" |
        sort -r -d -u -o "${watch_dir}/${posts_meta_file}"
}

shite_metadata_rebuild_indices() {
    # NOTE: gah, ugly hack :/
    # Use any change to the root index.org source as a trigger to
    # rebuild the public root index page, tag indices, rss feed.
    # - Collect all list-type pages (posts for now)
    # - Use post metadata to create post index to feed into the
    #   root index template
    # - Use tags metadata to create tag index to feed into the
    #   root index template

    while IFS=',' read -r timestamp event_type watch_dir sub_dir url_slug file_type content_type
    do
        case "${sub_dir}:${url_slug}" in
            sources:index.org|public:posts/*/index.html )
                __shite_metadata_make_posts_index_csv ${watch_dir}
            ;;
        esac
    done
}
