#!/bin/bash

usage() {
    cat << EOF
  $(basename $0) prints the link count per leaf or spine module in an Omni-Path director switch

    -h| --help          help
    -x                  show links per module
    -m module_name      only show info about the specified leaf/spine module
    -e                  list modules without links
    -s                  show spine modules instead of leaf modules
EOF
}

while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;  
        -x) 
            show_extended=1
            shift
            ;;  
        -m) 
            modules="$2"
            shift
            shift
            ;;  
        -e) 
            show_empty=1
            shift
            ;;  
        -s) 
            show_spine=1
            shift
            ;;
        *)  
            usage
            exit 1
            ;;
    esac
done

if [ -z "$modules" ]; then
    if [ -n "$show_spine" ]; then
        prefix="S2"
        num_modules=8
    else
        prefix="L1"
        num_modules=19
    fi

    modules="$(for num in `seq 1 $num_modules`; do
                for side in A B; do
                    printf '%s%02d%s\n' $prefix $num $side
                done
            done)"
fi

all_links="$(opareport -o links -q | awk '/^[0-9]+g/{line1=$0} /^<->/{print line1,$0}')"

while read module; do
    if [ -z "$show_spine" ]; then
        filter="-v"
    fi

    links=$(echo "$all_links" | grep $filter S2 | grep -i $module)
    num_links=$(echo "$links" | grep -c .)

    if [ -z "$show_empty" ]; then
        if [ $num_links -eq 0 ]; then
            continue
        fi
    fi

    echo "$module: $num_links"

    if [ -n "$show_extended" ]; then
        if [ $num_links -eq 0 ]; then
            continue
        fi

        while read link; do
            echo "  $link"
        done <<< "$links"
    fi
done <<< "$modules"
