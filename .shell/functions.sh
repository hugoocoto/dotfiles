#!/bin/env bash

function command_not_found_handler(){echo -e "\e[31m$1??"}

function gh(){
        # Open the current repository in the browser
        url=$(git remote get-url origin)
        echo "repo url: ${url}"
        [ ! -z "$url" ] && xdg-open $url
}

function clone(){
        if [ ! -n "$1" ]; then
                printf "Repo name (e.g. user/repo): "; read -r repo_input
        else
                repo_input="$1"
        fi
        repo_url="https://github.com/${repo_input}"
        repo_name=$(basename -s .git "$repo_input")
        echo "Repo URL: $repo_url"
        echo "Cloned at: ~/code/$repo_name"
        git clone "$repo_url" ~/code/$repo_name
}

function oil(){
        nvim -c ":Oil $1"        
}

function gc(){
        if [[ -n "$*" ]]; then
                git commit -m "$*"
        else
                git commit -e
        fi
}
