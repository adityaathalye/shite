#!/usr/bin/env bash

__shite_test_actions() {
    cp -f public/index.html public/deleteme.html
    echo "foo" >> public/deleteme.html
    mv public/deleteme.html public/deleteme2.html
    rm public/deleteme2.html
    # Should produce these "distinct" events:
    # 1652008576,MODIFY,/home/adi/src/github/adityaathalye/shite/public/deleteme.html
    # 1652008576,MOVED_TO,/home/adi/src/github/adityaathalye/shite/public/deleteme2.html
    # 1652008576,DELETE,/home/adi/src/github/adityaathalye/shite/public/deleteme2.html
}

__shite_test_events() {
    cat <<EOF
1651991204,CREATE,/home/adi/src/github/adityaathalye/shite/public/,deleteme.html
1651991204,MODIFY,/home/adi/src/github/adityaathalye/shite/public/,deleteme.html
1651991204,MODIFY,/home/adi/src/github/adityaathalye/shite/public/,deleteme.html
1651991204,MOVED_FROM,/home/adi/src/github/adityaathalye/shite/public/,deleteme.html
1651991204,MOVED_TO,/home/adi/src/github/adityaathalye/shite/public/,deleteme2.html
1651991204,DELETE,/home/adi/src/github/adityaathalye/shite/public/,deleteme2.html
1651991221,CREATE,/home/adi/src/github/adityaathalye/shite/public/,deleteme.html
1651991221,MODIFY,/home/adi/src/github/adityaathalye/shite/public/,deleteme.html
1651991221,MODIFY,/home/adi/src/github/adityaathalye/shite/public/,deleteme.html
1651991222,MODIFY,/home/adi/src/github/adityaathalye/shite/public/,static/foo.css
1651991222,MOVED_FROM,/home/adi/src/github/adityaathalye/shite/public/,static/foo.css
1651991222,MOVED_FROM,/home/adi/src/github/adityaathalye/shite/public/,static/foo2.css
1651991223,CREATE,/home/adi/src/github/adityaathalye/shite/public/,static/bar.js
1651991223,MODIFY,/home/adi/src/github/adityaathalye/shite/public/,static/bar.js
1651991223,DELETE,/home/adi/src/github/adityaathalye/shite/public/,static/bar.js
EOF
}
