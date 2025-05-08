# Vagrantfile

NUM_WORKERS = 2

Vagrant.configure("2") do |config|
    # Define the base box to use
    config.vm.box = "bento/ubuntu-24.04"
    
    # Control node configuration
    config.vm.define "ctrl" do |ctrl|
        ctrl.vm.provider "virtualbox" do |vb|
            vb.memory = 4096
            vb.cpus = 1
        end
        ctrl.vm.network "private_network", ip: "192.168.56.100"
        ctrl.vm.hostname = "ctrl"

        ctrl.vm.provision "ansible" do |ansible|
            ansible.playbook = "ansible/ctrl.yml"
        end
    end
 
    # Worker nodes configuration
    (1..NUM_WORKERS).each do |i|
        config.vm.define "node-#{i}" do |node|
            node.vm.provider "virtualbox" do |vb|
                vb.memory = 6144 # Updated to 6144
                vb.cpus = 2      # Updated to 2
            end
            node.vm.network "private_network", ip: "192.168.56.#{i + 100}"
            node.vm.hostname = "node-#{i}"

            node.vm.provision "ansible" do |ansible|
                ansible.playbook = "ansible/node.yml"
            end
        end
    end
end