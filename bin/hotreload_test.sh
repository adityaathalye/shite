#!/usr/bin/env bash

__shite_test_actions() {
    cp -f public/index.html public/deleteme.html
    echo "foo" >> public/deleteme.html
    mv public/deleteme.html public/deleteme2.html
    rm public/deleteme2.html
}

__shite_test_events() {
    cat <<EOF
1660907225,MODIFY,/home/adi/src/github/adityaathalye/shite,,about.html,html,generic
1660907225,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,,about.html,html,generic
1660907228,MODIFY,/home/adi/src/github/adityaathalye/shite,,about.html,html,generic
1660907228,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,,about.html,html,generic
1660907236,CREATE,/home/adi/src/github/adityaathalye/shite,,foo.html,html,generic
1660907236,MODIFY,/home/adi/src/github/adityaathalye/shite,,foo.html,html,generic
1660907236,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,,foo.html,html,generic
1660907253,MOVED_TO,/home/adi/src/github/adityaathalye/shite,,bar.html,html,generic
1660907255,CREATE,/home/adi/src/github/adityaathalye/shite,,bar.html,html,generic
1660907255,MODIFY,/home/adi/src/github/adityaathalye/shite,,bar.html,html,generic
1660907255,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,,bar.html,html,generic
1660907263,DELETE,/home/adi/src/github/adityaathalye/shite,,bar.html,html,generic
1660907272,CREATE,/home/adi/src/github/adityaathalye/shite,posts/,hello.html,html,blog
1660907272,MODIFY,/home/adi/src/github/adityaathalye/shite,posts/,hello.html,html,blog
1660907272,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,posts/,hello.html,html,blog
1660907277,MODIFY,/home/adi/src/github/adityaathalye/shite,posts/hello/,index.org,org,blog
1660907277,MODIFY,/home/adi/src/github/adityaathalye/shite,posts/hello/,index.org,org,blog
1660907277,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,posts/hello/,index.org,org,blog
1660907293,CREATE,/home/adi/src/github/adityaathalye/shite,posts/goodbye/,index.org,org,blog
1660907293,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,posts/goodbye/,index.org,org,blog
1660907306,CREATE,/home/adi/src/github/adityaathalye/shite,posts/goodbye/,index.org,org,blog
1660907306,MODIFY,/home/adi/src/github/adityaathalye/shite,posts/goodbye/,index.org,org,blog
1660907306,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,posts/goodbye/,index.org,org,blog
1660907319,DELETE,/home/adi/src/github/adityaathalye/shite,posts/goodbye/,index.org,org,blog
1660907328,CREATE,/home/adi/src/github/adityaathalye/shite,posts/hello/,metadata.json,json,blog
1660907328,MODIFY,/home/adi/src/github/adityaathalye/shite,posts/hello/,metadata.json,json,blog
1660907328,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,posts/hello/,metadata.json,json,blog
1660907335,MODIFY,/home/adi/src/github/adityaathalye/shite,posts/hello/,metadata.json,json,blog
1660907335,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,posts/hello/,metadata.json,json,blog
1660907392,MODIFY,/home/adi/src/github/adityaathalye/shite,static/css/,style.css,css,static
1660907392,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,static/css/,style.css,css,static
1660907404,CREATE,/home/adi/src/github/adityaathalye/shite,static/js/,bar.js,js,static
1660907404,MODIFY,/home/adi/src/github/adityaathalye/shite,static/js/,bar.js,js,static
1660907404,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,static/js/,bar.js,js,static
1660907557,DELETE,/home/adi/src/github/adityaathalye/shite,static/css/,style.css,css,static
1660907557,CREATE,/home/adi/src/github/adityaathalye/shite,static/css/,style.css,css,static
1660907557,MODIFY,/home/adi/src/github/adityaathalye/shite,static/css/,style.css,css,static
1660907557,CLOSE_WRITE:CLOSE,/home/adi/src/github/adityaathalye/shite,static/css/,style.css,css,static
1660907620,DELETE,/home/adi/src/github/adityaathalye/shite,static/js/,bar.js,js,static
EOF
}
