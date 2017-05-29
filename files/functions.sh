#! /bin/bash

# (title, sub-title)
function title() {
    printf '\n'
    printf '\n'
    printf "===============================================\n"
    printf "  %s\n" "$1"
    if [[ $2 != '' ]]; then
        printf "    - %s\n" "$2"
    fi
    printf "===============================================\n"
    printf '\n'
    printf '\n'
}

# (file, target, lines)
function lineReplace() {

    cat $1 | sed -e "1,/$2/!d" | sed '$,$d' > temp/lineReplace
    echo "$3" >> temp/lineReplace
    cat $1 | sed -e "1,/$2/d" >> temp/lineReplace

    cp temp/lineReplace  $1
    rm temp/lineReplace
}

# (array, delimiter)
function arrayToString() {
    declare -a array=("${!1}")
    result=''

    for (( i=0; i<${#array[@]}-1; i++ )); do
        result+="${array[i]}$2"
    done
    result+="${array[i]}"

    echo $result
}
