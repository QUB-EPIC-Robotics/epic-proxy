#!/bin/bash


# Function to parse TOML and get the value for a given key using grep and sed
get_toml_value() {
    local file="$1"
    local key="$2"
    local value=""

    # Search for the key using grep and get the line number
    local line_number=$(grep -nE "^$key[[:space:]]*=" "$file" | cut -d: -f1)

    # Check if the key was found
    if [[ -n "$line_number" ]]; then
        # Read from the file starting at the line number
        local line=$(sed -n "${line_number}p" "$file")
        value=$(echo "$line" | sed -E "s/^$key[[:space:]]*=[[:space:]]*(.*)/\1/")

        # Handle multi-line strings
        if [[ "$value" =~ ^\"\"\" ]]; then
            value="${value#\"\"\"}"
            while IFS= read -r line || [[ -n "$line" ]]; do
                value+="$line"$'\n'
                [[ "$line" =~ \"\"\"$ ]] && break
            done < <(sed -n "$((line_number+1)),$ p" "$file")
            value="${value%\"\"\"$'\n'}"
        elif [[ "$value" =~ ^\'\'\' ]]; then
            value="${value#\'\'\'}"
            while IFS= read -r line || [[ -n "$line" ]]; do
                value+="$line"$'\n'
                [[ "$line" =~ \'\'\'$ ]] && break
            done < <(sed -n "$((line_number+1)),$ p" "$file")
            value="${value%\'\'\'$'\n'}"
        fi

        # Remove surrounding quotes for single-line strings
        if [[ "$value" =~ ^\".*\"$ ]]; then
            value="${value:1:-1}"
        elif [[ "$value" =~ ^\'.*\'$ ]]; then
            value="${value:1:-1}"
        fi


        # Handle arrays
        if [[ "$value" =~ ^\[.*\]$ ]]; then
            # value=$(echo "$value" | sed 's/^\[\(.*\)\]$/\1/')

            # Remove surrounding brackets and split into elements
            value="${value:1:-1}"

            IFS=',' read -r -a value_array <<< "$value"

            echo "${value_array[@]}" | sed 's/"//g'
            return

        fi

        # Handle boolean values
        if [[ "$value" =~ ^(true|false)$ ]]; then
            value=$(echo "$value" | sed 's/true/1/;s/false/0/')
        fi
    fi

    echo "$value"
}


parse_config() {
    local file="$1"
    local prefix="$2"

    while IFS= read -r line; do
        # Remove comments and trim whitespace
        line=$(echo "$line" | sed 's/#.*//' | xargs)

        # Skip empty lines
        [ -z "$line" ] && continue

        # Handle section headers
        if [[ "$line" =~ ^\[(.*)\]$ ]]; then
            section=$(echo "${BASH_REMATCH[1]}" | xargs | tr '[:lower:]' '[:upper:]')
            prefix="${section}__"
            continue
        fi

        # Handle key-value pairs
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            key=$(echo "${BASH_REMATCH[1]}" | xargs | tr '[:lower:]' '[:upper:]')
            value=$(echo "${BASH_REMATCH[2]}" | xargs)

            # Remove quotes from value
            value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')

            # Replace dots in key with underscores
            key=$(echo "$key" | sed 's/\./_/g')

            # Export as environment variable
            export "${prefix}${key}=${value}"
        fi
    done < "$file"
}


is_file_app() {
    local file=$1
    local path=$(find "$epic_proxy_d/apps" -type f -name "$file.toml")

    if [[ -z $path ]]; then
        return 1
    else
        return 0
    fi
}


is_file_collection() {
    local file=$1
    local path=$(find "$epic_proxy_d/collections" -type f -name "$file.toml")

    if [[ -z $path ]]; then
        return 1
    else
        return 0
    fi
}

enable_app() {
    local app="$1"
    local enable_command=$(get_toml_value "$epic_proxy_d/apps/$app.toml" "enable_command")
    eval "$enable_command"
}

enable_collection() {
    local collection="$1"
    local apps=($(get_toml_value "$epic_proxy_d/collections/$collection.toml" "apps"))
    for app in "${apps[@]}"; do
        local enable_command=$(get_toml_value "$epic_proxy_d/apps/$app.toml" "enable_command")
        eval "$enable_command"
    done
}

disable_app() {
    local app="$1"
    local disable_command=$(get_toml_value "$epic_proxy_d/apps/$app.toml" "disable_command")
    eval "$disable_command"
}

disable_collection() {
    local collection="$1"
    local apps=($(get_toml_value "$epic_proxy_d/collections/$collection.toml" "apps"))
    for app in "${apps[@]}"; do
        local disable_command=$(get_toml_value "$epic_proxy_d/apps/$app.toml" "disable_command")
        eval "$disable_command"
    done
}

info_app() {
    local app="$1"

    local name=$(get_toml_value "$epic_proxy_d/apps/$app.toml" "name")
    local description=$(get_toml_value "$epic_proxy_d/apps/$app.toml" "description")

    echo -e "$name\n"
    echo -e "$description"
}

info_collection() {
    local collection="$1"

    local name=$(get_toml_value "$epic_proxy_d/collections/$collection.toml" "name")
    local description=$(get_toml_value "$epic_proxy_d/collections/$collection.toml" "description")
    local apps=($(get_toml_value "$epic_proxy_d/collections/$collection.toml" "apps"))

    echo -e "$name\n"
    echo -e "$description"
    echo -e "\nApps:"

    for app in "${apps[@]}"; do
        local app_name=$(get_toml_value "$epic_proxy_d/apps/$app.toml" "name")
        echo - "$app_name"
    done
}

proxy_enable() {
    local file=$1

    if is_file_app $file; then
        enable_app $file
    elif is_file_collection $file; then
        enable_collection $file
    else
        echo Name is not valid
        exit -1
    fi
}

proxy_disable() {
    local file=$1

    if is_file_app $file; then
        disable_app $file
    elif is_file_collection $file; then
        disable_collection $file
    else
        echo Name is not valid
        exit -1
    fi
}

info() {
    local file=$1

    if is_file_app $file; then
        info_app "$file"
    elif is_file_collection $file; then
        info_collection "$file"
    else
        echo Name is not valid
        exit -1
    fi
}

list() {
    echo "Apps"
    local apps=($(ls "$epic_proxy_d/apps"))
    for app in "${apps[@]}"; do
        echo "    $app" | sed 's/.toml//g'
    done

    echo "Collections"
    local collections=($(ls "$epic_proxy_d/collections"))

    for collection in "${collections[@]}"; do
        echo "    $collection" | sed 's/.toml//g'
    done
}


function show_help {
    echo "Usage: epic-proxy.sh [command] [options]"
    echo "Commands:"
    echo "  enable [APPNAME|COLLECTIONNAME]       Enable proxy for the specified app or collection"
    echo "  disable [APPNAME|COLLECTIONNAME|all]  Disable proxy for the specified app, collection, or all"
    echo "  app list                              List all apps"
    echo "  app info [APPNAME|COLLECTIONNAME]     Show info for the specified app or collection"
    echo "  help                                  Show this help message"
}


epic_proxy_d=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/epic-proxy.d
parse_config "$epic_proxy_d/config.toml"


case "$1" in
    enable)
        proxy_enable "$2"
        ;;
    disable)
        if [ "$2" == "all" ]; then
            echo "Feature not yet available"
        else
            proxy_disable "$2"
        fi
        ;;
    app)
        case "$2" in
            list)
                list "$3"
                ;;
            info)
                info "$3"
                ;;
            *)
                echo "Invalid option for app command"
                show_help
                ;;
        esac
        ;;
    help)
        show_help
        ;;
    *)
        echo "Invalid command"
        show_help
        ;;
esac

