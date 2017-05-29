#! /bin/bash

# (file, target, lines)
function lineReplace() {

    cat $1 | sed -e "1,/$2/!d" | sed '$,$d' > temp/test
    echo "$3" >> temp/test
    cat $1 | sed -e "1,/$2/d" >> temp/test

    echo "$(cat temp/test)"
}
