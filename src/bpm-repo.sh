DEP_DIR="$RUNNER_DIR/dep"

function edit-repo/download-deps() {
  local BPM_RAW_CONTENT_URL="https://raw.githubusercontent.com/Raffa064/bpm/refs/heads/main"

  if [ ! -e "$DEP_DIR" ]; then
    echo "Downloading dependencies..."
    mkdir "$DEP_DIR"
    curl -o "$DEP_DIR/bpr.sh" "$BPM_RAW_CONTENT_URL/core/bpr.sh" >/dev/null 2>&1
    curl -o "$DEP_DIR/bpr-repo.sh" "$BPM_RAW_CONTENT_URL/core/bpr/bpr-repo.sh" >/dev/null 2>&1
  fi
  
  source $DEP_DIR/bpr.sh
  source $DEP_DIR/bpr-repo.sh
}

function edit-repo/main() {
  edit-repo/download-deps

  local repo_path="$1"

  if [ -z "$repo_path" ] || [ -d "$repo_path" ]; then
    echo "Invalid repo path: $repo_path" 
    return 1
  fi

  if [ ! -e "$repo_path" ]; then
    edit-repo/create $repo_path
  fi

  edit-repo/modify $repo_path
}

function edit-repo/create() {
  local repo_path="$1"
  echo "Creating a new repo at: $repo_path"
  echo -n "Repo name: "
  read repo_name

  echo -n "Your name: "
  read author_name

  echo "metadata name=$repo_name" > "$repo_path"
  echo "metadata author=$author_name" >> "$repo_path"
}

function edit-repo/modify() {
  local repo_path="$1"

  declare -gA repo_data
  bpr-repo repo_data "$repo_path"

  local repo_name="${repo_data[--metadata-name]}"

  while true; do
    clear

    local entry
    for entry in "${!repo_data[@]}"; do
      if [[ ! "$entry" =~ --metadata- ]]; then
        echo "${entry:6} ${repo_data[$entry]}"
      fi
    done

    echo -n "[$repo_name]: "
    read -a cmd
    
    case ${cmd[0]} in
      he|help) edit-repo/modify-help ;;
      ad|add) edit-repo/add repo_data "${cmd[1]}" "${cmd[2]}" ;;
      rn|rename) edit-repo/rename repo_data "${cmd[1]}" "${cmd[2]}" ;;
      rm|remove) edit-repo/remove repo_data "${cmd[1]}" ;;
      up|update) 
        rm -rf $DEP_DIR
        edit-repo/download-deps ;;
      ap|apply) edit-repo/apply repo_data "$repo_path" ;;
      exit) exit ;;
      *) echo -e "Invalid command.\nUse 'help' to see availiable commands" ;;
    esac
  done
}

function edit-repo/modify-help() {
  echo "Available commands:"
  echo "add <pkg> <url>          - Add or edit a package"
  echo "rename <pkg> <new-name>  - Add or edit a package"
  echo "remove <pkg>             - Remove a package"
  echo "update                   - Update external dependencies"
  echo "apply                    - Finialize interative shell and apply changes"
  echo "exit                     - Exit without saving chages"
  echo "NOTE: url could also be a path to a local package"
  read
}

function edit-repo/add() {
  local -n data="$1"
  local pkg_name="$2"
  local pkg_url="$3"

  data[entry-$pkg_name]="$pkg_url"
}

function edit-repo/rename() {
  local -n data="$1"
  local pkg_name="$2"
  local pkg_new_name="$3"

  data[entry-$pkg_new_name]="${data[entry-$pkg_name]}"
  unset data[entry-$pkg_name]
}

function edit-repo/remove() {
  local -n data="$1"
  local pkg_name="$2"
  
  unset data[entry-$pkg_name]
}

function edit-repo/apply() {
  local -n data="$1"
  local repo_path="$2"

  echo "metadata name=${data[--metadata-name]}" > "$repo_path"
  echo "metadata author=${data[--metadata-author]}" >> "$repo_path"
  
  unset data[--metadata-name]
  unset data[--metadata-author]

  local entry
  for entry in "${!data[@]}"; do
    echo "entry ${entry:6}=${data[$entry]}" >> "$repo_path"
  done

  exit
}
