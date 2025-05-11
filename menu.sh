#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# shellcheck disable=SC2059,SC2034
function selection_menu {
  clear
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "${ESC}[?25h"; }
    cursor_blink_off()  { printf "${ESC}[?25l"; }
    cursor_to()         { printf "${ESC}[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  ${ESC}[7m $1 ${ESC}[27m"; }
    local ROW COL
    get_cursor_row()    { IFS=';' read -rsdR -p $'\E[6n' ROW COL; echo "${ROW#*[}"; }
    clear_lines()       { for ((i=0; i<$1; i++)); do printf "\n"; done; }

    local return_value=$1
    local selection_mode=$2
    shift 2
    local options=("$@")

    local items_per_page=7
    local total_items=${#options[@]}
    local total_pages=$(( (total_items + items_per_page - 1) / items_per_page ))
    local current_page=1

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        selected+=("false")
    done

    if [[ "$selection_mode" == "multiple" ]]; then
        echo -e "${BLUE}Controls:${NC} ${YELLOW}Arrows, j/k:${NC} Navigate - ${YELLOW}Space:${NC} Toggle - ${YELLOW}i:${NC} Invert - ${YELLOW}a:${NC} Select all - ${YELLOW}n:${NC} None"
        echo -e "${BLUE}Page Navigation:${NC} ${YELLOW}<:${NC} Prev Page - ${YELLOW}>:${NC} Next Page - ${GREEN}Enter:${NC} Confirm"
    else
        echo -e "${BLUE}Controls:${NC} ${YELLOW}Arrows, j/k:${NC} Navigate - ${GREEN}Enter/Space:${NC} Select"
        echo -e "${BLUE}Page Navigation:${NC} ${YELLOW}<:${NC} Prev Page - ${YELLOW}>:${NC} Next Page"
    fi

    clear_lines $((items_per_page + 2))

    local lastrow
    lastrow=$(get_cursor_row)
    local startrow=$((lastrow - items_per_page - 2))

    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ "$key" = "" ]]; then echo enter; fi
        if [[ "$key" = $'\x20' ]]; then echo space; fi
        if [[ "$key" = "k" ]]; then echo up; fi
        if [[ "$key" = "j" ]]; then echo down; fi
        if [[ "$key" = "i" ]]; then echo invert; fi
        if [[ "$key" = "a" ]]; then echo all; fi
        if [[ "$key" = "n" ]]; then echo none; fi
        if [[ "$key" = "<" ]]; then echo prev_page; fi
        if [[ "$key" = "," ]]; then echo prev_page; fi
        if [[ "$key" = ">" ]]; then echo next_page; fi
        if [[ "$key" = "." ]]; then echo next_page; fi
        if [[ "$key" = $'\x1b' ]]; then
            read -rsn2 key
            if [[ "$key" = "[A" ]]; then echo up; fi
            if [[ "$key" = "[B" ]]; then echo down; fi
            if [[ "$key" = "[D" ]]; then echo prev_page; fi
            if [[ "$key" = "[C" ]]; then echo next_page; fi
        fi
    }

    toggle_option() {
        local option=$1
        local real_idx=$(( (current_page - 1) * items_per_page + option ))
        if [[ $real_idx -lt ${#options[@]} ]]; then
            if [[ "$selection_mode" == "single" ]]; then
                for ((i=0; i<${#options[@]}; i++)); do
                    selected[i]=false
                done
                selected[real_idx]=true
            else
                if [[ ${selected[real_idx]} == true ]]; then
                    selected[real_idx]=false
                else
                    selected[real_idx]=true
                fi
            fi
        fi
    }

    print_options() {
        local start_idx=$(( (current_page - 1) * items_per_page ))
        local end_idx=$(( start_idx + items_per_page - 1 ))
        if [[ $end_idx -ge ${#options[@]} ]]; then
            end_idx=$(( ${#options[@]} - 1 ))
        fi

        for ((i=0; i<items_per_page; i++)); do
            cursor_to $((startrow + i))
            printf "%-60s" " "
        done

        local idx=0
        for ((i=start_idx; i<=end_idx; i++)); do
            local option="${options[i]}"
            local prefix="[ ]"
            if [[ ${selected[i]} == true ]]; then
                prefix="[\e[38;5;46m\u2718\e[0m]"
            fi

            cursor_to $((startrow + idx))
            if [[ $idx -eq $1 ]]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done

        cursor_to $((startrow + items_per_page + 1))
        printf "%-60s" " "
        cursor_to $((startrow + items_per_page + 1))
        local selected_count=0
        for ((i=0; i<${#selected[@]}; i++)); do
            if [[ ${selected[i]} == true ]]; then
                ((selected_count++))
            fi
        done

        if [[ "$selection_mode" == "multiple" ]]; then
            printf "${PURPLE}Page ${current_page}/${total_pages} - ${CYAN}Items ${start_idx+1}-$((end_idx+1))/${total_items} - ${GREEN}Selected: ${selected_count}${NC}"
        else
            printf "${PURPLE}Page ${current_page}/${total_pages} - ${CYAN}Items ${start_idx+1}-$((end_idx+1))/${total_items}${NC}"
        fi
    }

    invert_all() {
        if [[ "$selection_mode" == "multiple" ]]; then
            for ((i=0; i<${#options[@]}; i++)); do
                if [[ ${selected[i]} == true ]]; then
                    selected[i]=false
                else
                    selected[i]=true
                fi
            done
        fi
    }

    select_all() {
        if [[ "$selection_mode" == "multiple" ]]; then
            for ((i=0; i<${#options[@]}; i++)); do
                selected[i]=true
            done
        fi
    }

    unselect_all() {
        if [[ "$selection_mode" == "multiple" ]]; then
            for ((i=0; i<${#options[@]}; i++)); do
                selected[i]=false
            done
        fi
    }

    change_page() {
        local direction=$1
        if [[ "$direction" == "next" ]]; then
            if [[ $current_page -lt $total_pages ]]; then
                ((current_page++))
                active=0
            fi
        elif [[ "$direction" == "prev" ]]; then
            if [[ $current_page -gt 1 ]]; then
                ((current_page--))
                active=0
            fi
        fi
    }

    local active=0
    while true; do
        print_options $active

        case $(key_input) in
            space)
                    toggle_option $active
                    if [[ "$selection_mode" == "single" ]]; then
                        print_options -1
                        break
                    fi;;
            enter)
                    if [[ "$selection_mode" == "single" ]]; then
                        toggle_option $active
                    fi
                    print_options -1
                    break;;
            up)     ((active--))
                    if [ $active -lt 0 ]; then
                        local page_items=$(( current_page == total_pages ? total_items - (current_page - 1) * items_per_page : items_per_page ))
                        active=$((page_items - 1))
                    fi;;
            down)   ((active++))
                    local page_items=$(( current_page == total_pages ? total_items - (current_page - 1) * items_per_page : items_per_page ))
                    if [ $active -ge $page_items ]; then active=0; fi;;
            invert) if [[ "$selection_mode" == "multiple" ]]; then invert_all; fi; print_options $active;;
            all)    if [[ "$selection_mode" == "multiple" ]]; then select_all; fi; print_options $active;;
            none)   if [[ "$selection_mode" == "multiple" ]]; then unselect_all; fi; print_options $active;;
            next_page) change_page "next"; print_options $active;;
            prev_page) change_page "prev"; print_options $active;;
        esac
    done

    cursor_to $((lastrow + 1))
    printf "\n"
    cursor_blink_on

    local -a result=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${selected[i]} == true ]]; then
            result+=("${options[i]}")
        fi
    done

    eval "$return_value"='("${result[@]}")'
}
