# Pods Health Checker AI

## Overview

The **Pods Health Checker AI** project combines a Bash shell script and a Python script to enhance Kubernetes pod monitoring by leveraging AI to diagnose and suggest solutions for pod issues. This tool provides a comprehensive way to scan pod statuses across namespaces or cluster-wide and generates actionable insights using Google Gemini.

## Features

- **Pod Health Scanning**: Scan Kubernetes pods cluster-wide or within specific namespaces.
- **Status Reporting**: Display the status of pods (Running, Pending, and Errors) in a visually appealing table format.
- **Issue Diagnosis**: Extract and analyze pod issues (e.g., CrashLoopBackOff) and get solutions using Google Gemini.
- **Namespace Listing**: Automatically list all namespaces within the cluster for easy selection.
- **Response Storing**: The AI response is stored in `AI_Response.md` file
- **Clusters Switch**: List down all the clusters and easily switch between them
- **Multiple Error Handing**: if two or more than two errors are there then respective markdown file will be generated

## Installation

### Prerequisites

- **Python**: Version 3.x
- **Bash**: Compatible with most Unix-based systems
- **Google Gemini API Access**: Ensure you have access and an API key for Google Gemini.

### Dependencies

Create a `requirements.txt` file with the following content:

```
google-generativeai
python-dotenv
```

Install the dependencies using pip:

```bash
pip install -r requirements.txt
```

### Environment Setup

Create a .env file in the root directory of your project and add your Google Gemini API key:

```
API_KEY=your_google_gemini_api_key
```

## Usage

### Python Script

The Python script (get_gemini_solution.py) is used to get solutions for pod issues. It interacts with Google Gemini to generate solutions based on the issue description.

Example Command 

```python
python get_gemini_solution.py "CrashLoopBackOff"
```
🔔 **Note:** This Python Script is in the Shell Script so we dont need to run it as standalone


### Bash Script

The Bash script (pods_health_checker.sh) is used to scan pods, check their status, and display the results in a table format. It also integrates with the Python script to fetch and display solutions for identified issues.

#### Run the Script


```
./pods_health_checker.sh
```

#### Menu Options

1. Scan cluster-wide: Scans all namespaces in the Kubernetes cluster.
2. Scan a specific namespace: Allows the user to select a namespace and scan pods within that namespace.

## Example Output

### Cluster List and Switch
```
Available Kubernetes clusters:
kind-hack
minikube
k3d-dragon-1


🔄🗂️ Enter the name of the cluster you want to switch to: minikube
Switched to context "minikube".
Switched to cluster: minikube
```

### Namespace List 

```
Avaliable Namespaces:
default
dev
kube-node-lease
kube-public
kube-system
```


### Pod Status Table:

```
+---------------+---------------+---------------+
| Healthy Pods  | Unhealthy Pods| Pending Pods  |
+---------------+---------------+---------------+
| 5             | 2             | 1             |
+---------------+---------------+---------------+
```


### Issues Table:

```
+------------------------+-----------------------------+
| Pod Name               | Description                  |
+------------------------+-----------------------------+
| crashing-pod-1234      | CrashLoopBackOff 🛠️         |
+------------------------+-----------------------------+
```

### AI based solution 

```
Fetching solution for: CrashLoopBackOff
Possible Solutions:- AI Response is saved as Markdown. Please check CrashLoopBackOff.md for the solution.
```

### AI Response Storing

check the example CrashLoopBackOff.md to get a good understanding about the Pod Issue.

### Example Screenshot

![alt text](<Screenshot from 2024-08-01 02-01-17.png>)

## Contributing

Feel free to fork the repository and submit pull requests. Contributions to improve functionality and add features are welcome.

## License

This project is licensed under the MIT License.

