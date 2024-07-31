#!/bin/bash 

# Define color variables
azul='\033[0;34m'    # Blue
blanc='\033[0;37m'   # White
rescolor='\033[0m'   # Reset

# Function to list all clusters
list_clusters() {
  echo -e "${azul}Available Kubernetes clusters:${rescolor}"
  clusters=$(kubectl config get-clusters)
  echo "$clusters" | tail -n +2  # Remove header
  echo -e "\n"
}

# Function to switch cluster context
switch_cluster() {
  local cluster=$1
  kubectl config use-context "$cluster"
  echo -e "${blanc}Switched to cluster: $cluster${rescolor}"
}

# Main script
list_clusters
read -p "🔄🗂️ Enter the name of the cluster you want to switch to: " cluster_name
if kubectl config get-clusters | grep -q "$cluster_name"; then
  switch_cluster "$cluster_name"
else
  echo -e "${azul}Cluster not found: $cluster_name${rescolor}"
fi


