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
    declare -a argAry1=("${!1}")
    # echo "${argAry1[@]}"
    result="$(echo "${argAry1[@]}")"
    result=$(echo "$result" | sed -e "s/ /, /g")

    echo $result
}

# (local_user, remote_user, remote_ip, user_command)
function sudossh() {
    local_user="$1"
    remote_user="$2"
    remote_ip="$3"
    user_command="$4"
    sudo sudo -u ${local_user} ssh -o StrictHostKeyChecking=no ${remote_user}@${remote_ip} "$user_command"
}
