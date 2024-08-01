#!/bin/bash

clear

# Colors
blanc="\033[1;37m"
gray="\033[0;37m"
magenta="\033[0;35m"
red="\033[1;31m"
green="\033[1;32m"
amarillo="\033[1;33m"
azul="\033[1;34m"
rescolor="\e[0m"

# Banner
printf "\n%.0s" {1..3}
echo -e "${green}  .______     ______    _______       _______.    __    __   _______     ___       __      .___________. __    __      ______  __    __   _______   ______  __  ___  _______ .______      ${rescolor}"
echo -e "${green}  |   _  \\   /  __  \\  |       \\     /       |   |  |  |  | |   ____|   /   \\     |  |     |           ||  |  |  |    /      ||  |  |  | |   ____| /      ||  |/  / |   ____||   _  \\     ${rescolor}"
echo -e "${green}  |  |_)  | |  |  |  | |  .--.  |   |   (----\`   |  |__|  | |  |__     /  ^  \\    |  |     \`---|  |----\`|  |__|  |   |  ,----'|  |__|  | |  |__   |  ,----'|  '  /  |  |__   |  |_)  |    ${rescolor}"
echo -e "${green}  |   ___/  |  |  |  | |  |  |  |    \\   \\       |   __   | |   __|   /  /_\\  \\   |  |         |  |     |   __   |   |  |     |   __   | |   __|  |  |     |    <   |   __|  |      /     ${rescolor}"
echo -e "${green}  |  |      |  \`--'  | |  '--'  |.----)   |      |  |  |  | |  |____ /  _____  \\  |  \`----.    |  |     |  |  |  |   |  \`----.|  |  |  | |  |____ |  \`----.|  .  \\  |  |____ |  |\\  \\----.${rescolor}"
echo -e "${green}  | _|       \\______/  |_______/ |_______/       |__|  |__| |_______/__/     \\__\\ |_______|    |__|     |__|  |__|    \\______||__|  |__| |_______| \\______||__|\\__\\ |_______|| _| \`.___|${rescolor}"
printf "\n%.0s" {1..2}


# Function to list all namespaces
list_namespaces() {
  echo -e "${azul}Available namespaces:${rescolor}"
  namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
  echo "$namespaces" | tr ' ' '\n'
  echo -e "\n"
}

# Function to sanitize the reason string for use in filenames
sanitize_reason() {
  local reason=$1
  # Replace spaces with underscores, and remove any other invalid characters
  sanitized_reason=$(echo "$reason" | sed 's/ /_/g' | sed 's/[^a-zA-Z0-9_-]//g')
  echo "$sanitized_reason"
}

# Function to get solution from Python script and save to Markdown file
get_solutions_from_gemini() {
  local reason=$1
  local sanitized_reason=$(sanitize_reason "$reason")
  local output_file="${sanitized_reason}.md"
  local counter=1

  # Ensure unique filename by appending a counter if file already exists
  while [[ -f "$output_file" ]]; do
    output_file="${sanitized_reason}_${counter}.md"
    ((counter++))
  done

  echo -e "${blanc}Fetching solution for: $reason${rescolor}"
  solution=$(python3 get_gemini_solution.py "$reason" 2>&1 | awk '!/WARNING: All log messages before absl::InitializeLog() is called are written to STDERR/ && !/gRPC experiments enabled:/')

  if [[ -z "$solution" ]]; then
    echo -e "${red}No solution found for the given reason.${rescolor}"
    echo "## Solution for: $reason" >> "$output_file"
    echo "No solution found for the given reason." >> "$output_file"
  else
    echo -e "${blanc}Possible Solutions:- AI Response is saved as Markdown. Please check $output_file for the solution.${rescolor}"
    echo "## Solution for: $reason" >> "$output_file"
    echo "$solution" >> "$output_file"
  fi
}

# Function to check the health of pods in a given namespace
check_pods_in_namespace() {
  local namespace=$1
  echo -e "${azul}Checking pods in namespace: ${namespace}${rescolor}\n"

  kubectl config set-context --current --namespace=$namespace
  kubectl config view --minify | grep $namespace

  listPods=$(kubectl get po | awk 'NR>1{print $1}')
  readarray arr <<< $listPods

  local ok=0
  local notok=0
  local pending=0
  local issues=()

  echo -e "${amarillo}Sit Down and Wait  \U1F602 :${rescolor}\n"
  for i in ${arr[@]}
  do
    echo -ne "$i ... "
    status=$(kubectl get po $i | grep $i | awk '{print $3}')
    if [[ ! $status =~ ^Running$|^Completed$ ]]; then
      if [[ $status =~ ^Pending$ ]]; then
        echo -e "\e[1;33mPending${rescolor}"
        let pending=pending+1
      else
        echo -e "\e[1;31m🚨 Oh No! Something went wrong! ${rescolor}"
        notify-send "Pods Health" "$i encountered an issue 😱" -t 10000
        let notok=notok+1
        reason=$(kubectl describe pod $i | grep -i 'reason' | head -n 1 | awk -F: '{print $2}')
        reason=$(echo $reason | xargs)  # Remove leading/trailing whitespace
        issues+=("$i|$reason")
      fi
    else
      echo -e "\e[1;32mOK!${rescolor}"
      let ok=ok+1
    fi
  done

  echo -e "\n${gray}STATS for namespace ${namespace}:${rescolor}\n"
  echo "+---------------+---------------+---------------+"
  printf "|${green}%-15s${rescolor}|${red}%-15s${rescolor}|${amarillo}%-15s${rescolor}|\n" "Healthy Pods" "Unhealthy Pods" "Pending Pods"
  echo "+---------------+---------------+---------------+"
  printf "|%-15s|%-15s|%-15s|\n" "$ok" "$notok" "$pending"
  echo "+---------------+---------------+---------------+"

  # Display issues and sends solutions to AI 

  if [ ${#issues[@]} -ne 0 ]; then
    echo -e "\n${red}Issues:${rescolor}\n"
    echo "+------------------------+-----------------------------+"
    printf "|%-24s|%-29s|\n" "Pod Name" "Description"
    echo "+------------------------+-----------------------------+"
    for issue in "${issues[@]}"
    do
      IFS='|' read -r pod_name description <<< "$issue"
      printf "|%-24s|%-29s|\n" "$pod_name" "$description"
    done
    echo "+------------------------+-----------------------------+"

    echo -e "\n${blanc}Fetching solutions for issues:${rescolor}\n"
    for issue in "${issues[@]}"
    do
      IFS='|' read -r pod_name description <<< "$issue"
      echo -e "\n${red}Fetching solution for pod $pod_name with issue $description:${rescolor}\n"
      get_solutions_from_gemini "$description"
    done
  fi

  echo -e "\n"
}

# Function to scan cluster-wide
check_pods_cluster_wide() {
  namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
  for namespace in $namespaces
  do
    check_pods_in_namespace $namespace
  done
}

# Function to check if there are multiple clusters and prompt to switch
check_and_switch_cluster() {
  # Count the number of clusters
  local cluster_count
  cluster_count=$(kubectl config get-clusters | tail -n +2 | wc -l)

  if (( cluster_count > 1 )); then
    # Multiple clusters detected, prompt to switch
    echo -e "${blanc}🌐✨ Multiple clusters detected! Choose the one to switch to and start your scan!${rescolor}"
    echo -e "${blanc}🔄🌟 Please select the cluster you want to switch to and continue your scan!.${rescolor}"
    ./switch_cluster.sh
  else
    # Only one cluster detected
    echo -e "${blanc}🔍✅ Only one cluster detected. No need to switch—you're all set!${rescolor}"
  fi
}

# Call the function to check and switch cluster if needed
check_and_switch_cluster

echo " "

# Menu options

echo "Choose an option:"
echo "1. Scan cluster-wide"
echo "2. Scan a specific namespace"
echo " "
read -p 'Option: ' option

case $option in
  1)
    check_pods_cluster_wide
    ;;
  2)
    list_namespaces
    read -p '🏷️✨Enter the namespace you want to choose: ' varname
    if echo "$namespaces" | grep -qw "$varname"; then
      check_pods_in_namespace $varname
    else
      echo "Invalid namespace selected."
    fi
    ;;
  *)
    echo "Invalid option selected."
    ;;
esac
