# Detect if the vagrant-vmware-desktop plugin is available
has_vmware = Vagrant.has_plugin?("vagrant-vmware-desktop")

# Choose box based on provider availability
BOX = "bento/ubuntu-24.04"
WORKER_MEMORY = ENV.fetch("WORKER_MEM", 2048).to_i
NUM_WORKERS = ENV.fetch("NUM_WORKERS", 2).to_i
shared_folder_path = File.expand_path("./shared")

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
        vb.vmx["memsize"] = "6000"
        vb.vmx["numvcpus"] = "4"
        vb.linked_clone = false
      end
    else
      ctrl.vm.provider "virtualbox" do |vb|
        vb.memory = 4000
        vb.cpus = 4
      end
    end

    ctrl.vm.network "private_network", ip: "192.168.56.100"
    ctrl.vm.hostname = "ctrl"

    # ctrl.vm.synced_folder shared_folder_path, "/mnt/shared"

    ctrl.vm.provision "ansible" do |ansible|
      ansible.playbook = "ansible/ctrl.yml"
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

      node.vm.network "private_network", ip: "192.168.56.#{i + 100}"
      node.vm.hostname = "node-#{i}"

      # node.vm.synced_folder shared_folder_path, "/mnt/shared"

      node.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/node.yml"
        ansible.extra_vars = {
          num_workers: NUM_WORKERS
        }
      end
    end
  end
end
