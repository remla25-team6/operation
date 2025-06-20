# Detect if the vagrant-vmware-desktop plugin is available
has_vmware = Vagrant.has_plugin?("vagrant-vmware-desktop")

# Choose box based on provider availability
BOX = "bento/ubuntu-24.04"
WORKER_MEMORY = ENV.fetch("WORKER_MEM", 4000).to_i
NUM_WORKERS = ENV.fetch("NUM_WORKERS", 2).to_i
shared_folder_path = File.expand_path("./shared")

CTRL_IP = "192.168.56.100"
NODE_IPS = (1..NUM_WORKERS).map { |i| "192.168.56.#{100 + i}" }
INVENTORY_PATH = "ansible/inventory.cfg"

Vagrant.configure("2") do |config|
  config.vm.box = BOX

  if has_vmware
    config.vm.provider "vmware_desktop" do |vb|
      vb.force_vmware_license = "workstation"
      vb.ssh_info_public = "true"
      vb.vmx["vhv.enable"] = "true"
      vb.vmx["mem.hotplug"] = "false"
      vb.vmx["cpu.hotplug"] = "false"
    end
  end

  unless has_vmware
    config.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
    end
  end

  config.vm.define "ctrl" do |ctrl|
    if has_vmware
      ctrl.vm.provider "vmware_desktop" do |vb|
        vb.vmx["memsize"] = "4000"
        vb.vmx["numvcpus"] = "4"
        vb.linked_clone = false
      end
    else
      ctrl.vm.provider "virtualbox" do |vb|
        vb.memory = 3000
        vb.cpus = 4
      end
    end

    ctrl.vm.network "private_network", ip: CTRL_IP
    ctrl.vm.hostname = "ctrl"
    ctrl.vm.synced_folder shared_folder_path, "/mnt/shared"

    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/ctrl.yml"
      ansible.inventory_path = INVENTORY_PATH
      ansible.extra_vars = {
        num_workers: NUM_WORKERS
      }
    end
  end
  
  (1..NUM_WORKERS).each do |i|
    config.vm.define "node-#{i}" do |node|
      if has_vmware
        node.vm.provider "vmware_desktop" do |vb|
          vb.linked_clone = false
          vb.vmx["memsize"] = WORKER_MEMORY
          vb.vmx["numvcpus"] = "2"
        end
      else
        node.vm.provider "virtualbox" do |vb|
          vb.memory = WORKER_MEMORY
          vb.cpus = 2
        end
      end

      node.vm.network "private_network", ip: NODE_IPS[i - 1]
      node.vm.hostname = "node-#{i}"
      node.vm.synced_folder shared_folder_path, "/mnt/shared"

      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/node.yml"
        ansible.inventory_path = INVENTORY_PATH
        ansible.extra_vars = { num_workers: NUM_WORKERS }
      end
    end
  end

  config.trigger.after [:up, :reload] do |trigger|
    trigger.name = "Generate Ansible inventory"
    trigger.ruby do
      File.open(INVENTORY_PATH, "w") do |file|
        file.puts "[controller]"
        file.puts "ctrl ansible_host=#{CTRL_IP} ansible_ssh_private_key_file=.vagrant/machines/ctrl/virtualbox/private_key ansible_ssh_common_args='-o IdentitiesOnly=yes'"
        file.puts ""

        file.puts "[nodes]"
        NODE_IPS.each_with_index do |ip, i|
          file.puts "node-#{i + 1} ansible_host=#{ip} ansible_ssh_private_key_file=.vagrant/machines/node-#{i + 1}/virtualbox/private_key ansible_ssh_common_args='-o IdentitiesOnly=yes'"
        end

        file.puts ""
        file.puts "[all:children]"
        file.puts "controller"
        file.puts "nodes"

        file.puts ""
        file.puts "[all:vars]"
        file.puts "ansible_user=vagrant"
        file.puts "ansible_python_interpreter=/usr/bin/python3"
      end
    end
  end
end
