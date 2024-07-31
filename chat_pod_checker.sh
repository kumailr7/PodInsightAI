#!/bin/bash

# Colors
blanc="\033[1;37m"
gray="\033[0;37m"
magenta="\033[0;35m"
red="\033[1;31m"
green="\033[1;32m"
amarillo="\033[1;33m"
azul="\033[1;34m"
rescolor="\e[0m"

# Header
echo -e "${green}####################################${rescolor}"
echo -e "${green}#${rescolor}        ${green}PODS HEALTH CHECKER${rescolor}        ${green}#${rescolor}"
echo -e "${green}####################################${rescolor}\n"

# Function to list all namespaces
list_namespaces() {
  echo -e "${azul}Available namespaces:${rescolor}"
  namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
  echo "$namespaces" | tr ' ' '\n'
  echo -e "\n"
}

# Function to get solution from Python script
get_solutions_from_gemini() {
  local reason=$1
  solution=$(python3 get_gemini_solution.py "$reason")
  
  if [[ -z "$solution" ]]; then
    echo -e "${red}No solution found for the given reason.${rescolor}"
  else
    echo -e "${blanc}Possible solution:${rescolor}\n$solution"
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

# Menu options
echo "Choose an option:"
echo "1. Scan cluster-wide"
echo "2. Scan a specific namespace"

read -p 'Option: ' option

case $option in
  1)
    check_pods_cluster_wide
    ;;
  2)
    list_namespaces
    read -p 'Enter the namespace you want to choose: ' varname
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
