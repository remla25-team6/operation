#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e


GREEN='\033[0;32m'
NC='\033[0m' # No Color

VM_CTRL_NAME="ctrl"
VM_WORKER_NAMES="node-1 node-2" 
ALL_VM_NAMES="${VM_CTRL_NAME} ${VM_WORKER_NAMES}"
INVENTORY_PATH=".vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory"
# Ansible configuration
export ANSIBLE_CONFIG="./ansible.cfg"

HELM_RELEASE_NAME="sentiment-release" 
HELM_CHART_PATH="/vagrant/sentiment-chart"
MONITORING_ENV_FILE=".monitoring.env"

log_message() {
    echo -e "${GREEN}INFO: $1${NC}"
}

boot_vms() {
    log_message "Booting VM's"

    for vm in $ALL_VM_NAMES; do
        vagrant up $vm --no-provision
    done 

    log_message "All VM's booted"
}

error_message() {
    echo "ERROR: $1" >&2
    exit 1
}

add_host_entry() {
    local ip="$1"
    local hostname="$2"
    if ! grep -qP "^\s*${ip}\s+${hostname}\s*$" /etc/hosts; then
        log_message "Adding host entry to /etc/hosts: ${ip} ${hostname}"
        echo "${ip} ${hostname}" | sudo tee -a /etc/hosts > /dev/null
    else
        log_message "Host entry already exists in /etc/hosts: ${ip} ${hostname}"
    fi
}

setup_monitoring_secrets() {
    if [ ! -f "$MONITORING_ENV_FILE" ]; then
        log_message "Monitoring secrets file not found. Creating $MONITORING_ENV_FILE..."
        echo -e "${YELLOW}Please provide the following information for monitoring setup:${NC}"
        
        # Grafana admin password
        read -p "Enter Grafana username: " GRAFANA_USER
        while true; do
            read -sp "Enter Grafana admin password: " GRAFANA_PASSWORD
            echo
            read -sp "Confirm Grafana admin password: " GRAFANA_PASSWORD_CONFIRM
            echo
            if [ "$GRAFANA_PASSWORD" = "$GRAFANA_PASSWORD_CONFIRM" ]; then
                break
            else
                echo -e "${RED}Passwords do not match. Please try again.${NC}"
            fi
        done
        
        # SMTP Configuration
        read -p "Enter SMTP server (e.g., smtp.gmail.com:587): " SMTP_SERVER
        read -p "Enter SMTP username/email: " SMTP_USERNAME
        read -sp "Enter SMTP password: " SMTP_PASSWORD
        echo
        read -p "Enter alert recipient email: " ALERT_RECIPIENT
        ALERT_SENDER=$SMTP_USERNAME
        
        # Create the .monitoring.env file
        cat > "$MONITORING_ENV_FILE" << EOF
# Monitoring configuration - DO NOT COMMIT THIS FILE

# Grafana credentials
GRAFANA_ADMIN_USER=$GRAFANA_USER
GRAFANA_ADMIN_PASSWORD=$GRAFANA_PASSWORD

# SMTP Configuration for AlertManager
SMTP_SERVER=$SMTP_SERVER
SMTP_USERNAME=$SMTP_USERNAME
SMTP_PASSWORD=$SMTP_PASSWORD
ALERT_RECIPIENT=$ALERT_RECIPIENT
ALERT_SENDER=$ALERT_SENDER
EOF
        
        chmod 600 "$MONITORING_ENV_FILE"
        log_message "Created $MONITORING_ENV_FILE"
    else
        log_message "Found existing $MONITORING_ENV_FILE"
    fi

    if [ -f "$MONITORING_ENV_FILE" ]; then
        set -o allexport
        source "$MONITORING_ENV_FILE"
        set +o allexport
        log_message "Exported variables from $MONITORING_ENV_FILE into environment"
    else
        warning_message "Unable to find $MONITORING_ENV_FILE to export variables."
    fi
}


cleanup_system() {
    # Display warning in red and explain why cleanup is necessary
    echo -e "\033[91m⚠️  To increase stability a cleanup process could be beneficial ⚠️\033[0m"
    echo -e "\033[91mThis cleanup process will:\033[0m"
    echo -e "\033[91m• Clear system VM memory caches\033[0m"
    echo -e "\033[91m• Destroy existing operation VM's (vagrant destroy -f)\033[0m"
    echo -e "\033[91m• Clean up VirtualBox host-only networks\033[0m"
    echo ""
    echo -e "\033[91mWhy this MIGHT increase stability:\033[0m"
    echo -e "\033[91m• Prevents conflicts with existing VirtualBox instances\033[0m"
    echo -e "\033[91m• Ensures clean network configuration for new VMs\033[0m"
    echo -e "\033[91m• Frees up system resources for optimal VM deployment\033[0m"
    echo ""
    
    echo -e "\033[93mDo you want to proceed with the system cleanup? (answering no will continue the deployment) (y/N): \033[0m"
    read -r response
    
    case "${response,,}" in
        y|yes)
            echo -e "\033[92mProceeding with system cleanup...\033[0m"
            ;;
        *)
            echo -e "\033[93mSkipping system cleanup.\033[0m"
            return 0
            ;;
    esac
    
    log_message "Performing system cleanup before deployment..."

    # Destroy remaining VM's
    echo "Destroying possible operation VM's (vagrant destroy -f)...."
    vagrant destroy -f

    # Clear vbox host networks
    echo "Cleaning VirtualBox host-only networks..."
    VBoxManage list hostonlyifs | grep -E "^Name:" | sed 's/Name: *//' | while read iface; do
        VBoxManage hostonlyif remove "$iface" 2>/dev/null || true
    done

    # Clear caches
    echo "Clearing system caches..."
    echo "3" | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    # Remove .vagrant directory
    rm -rf .vagrant/
    
    # Remove vbox interface
    echo "Removing stale VirtualBox network interfaces..."
    for iface in $(VBoxManage list hostonlyifs | grep -B2 "VMs:" | grep -A2 "VMs: *$" | grep "Name:" | cut -d: -f2 | tr -d ' '); do
        VBoxManage hostonlyif remove "$iface" 2>/dev/null || true
    done

    # Clean up any existing vbox processes
    echo "Stopping VirtualBox processes..."
    sudo pkill -f VBoxHeadless || true
    
    echo -e "\033[92mSystem cleanup completed successfully!\033[0m"
}

setup_monitoring_secrets

cleanup_system

log_message "Starting infrastructure provisioning and deployment script."

log_message "Using Ansible config: $ANSIBLE_CONFIG"

# Add entries to /etc/hosts/
log_message "Updating /etc/hosts entries..."
add_host_entry "192.168.56.91" "dashboard.local"
add_host_entry "192.168.56.94" "prometheus.local"
add_host_entry "192.168.56.93" "grafana.local"

echo "This might take a few minutes."
if ! command -v parallel &> /dev/null; then
    error_message "GNU parallel is not installed. Please install it to continue."
fi

# Boot all VM's first
boot_vms

log_message "Now provisioning CTRL"

vagrant provision ctrl
log_message "Provisioned VM ctrl, now provisioning the worker nodes"

parallel --jobs 2 --tag --linebuffer --no-notice "vagrant up {}" ::: ${VM_WORKER_NAMES}
log_message "Vagrant VMs up and initial Ansible provisioning complete."

ansible-galaxy collection install -r requirements.yml # Install required Ansible collections
log_message "Installing required ansible collections"

# Finalization provision for ctrl vm
log_message "Running finalization playbook (finalization.yml) on control node (${VM_CTRL_NAME})..."
#ansible-playbook finalization.yml -i "${INVENTORY_PATH}" --limit "${VM_CTRL_NAME}" # THis uses the inventory generated by Vagrant
ansible-playbook \
  -u vagrant \
  --private-key="$(vagrant ssh-config ctrl | awk '/IdentityFile/ {print $2}')" \
  -i 192.168.56.100, \
  finalization.yml
log_message "Finalization playbook complete."

# Installing helm
log_message "Deploying application using Helm..."
if ! vagrant ssh "${VM_CTRL_NAME}" --command "
  cd ${HELM_CHART_PATH} && 
  helm dependency update && 
  helm upgrade --install ${HELM_RELEASE_NAME} . --wait --timeout=10m
"; then
    error_message "Helm deployment failed"
fi


log_message "Helm deployment complete."
log_message "Infrastructure provisioning and application deployment script finished successfully!"
log_message "The app can be accessed at: 192.168.56.90:80"
log_message "Kubernetes dashboard can be accessed at: dashboard.local"
log_message "Grafana dashboard can be accessed at: grafana.local"
log_message "Prometheus dashboard can be accessed at prometheus.local"

log_message "Your kubernetes dashboard token is:"
vagrant ssh -c "kubectl -n kubernetes-dashboard create token admin-user" ctrl

exit 0