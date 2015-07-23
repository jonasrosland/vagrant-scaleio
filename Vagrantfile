# Created by Jonas Rosland, @virtualswede & Matt Cowger, @mcowger
# Many thanks to this post by James Carr: http://blog.james-carr.org/2013/03/17/dynamic-vagrant-nodes/

# scaleio admin password
password="Scaleio123"

# add your domain here
domain = 'scaleio.local'

# add your IPs here
network = "192.168.100"
firstmdmip = "#{network}.11"
secondmdmip = "#{network}.12"
tbip = "#{network}.13"

# modifiy hostnames if required
nodes = [
{hostname: "scaleio-tb", ipaddress: "#{tbip}", type: "tb", box: "chef/centos-6.6"},
{hostname: 'scaleio-mdm1', ipaddress: "#{firstmdmip}", type: 'mdm1', box: "chef/centos-6.6"},
{hostname: 'scaleio-mdm2', ipaddress: "#{secondmdmip}", type: 'mdm2', box: "chef/centos-7.0"}
]

# Install ScaleIO cluster automatically or IM only
clusterinstall = "True" #If True a fully working ScaleIO cluster is installed. False mean only IM is installed on node MDM1.

# package name, was ecs for 1.21, is now EMC-ScaleIO from 1.30
packagename = "EMC-ScaleIO"

# fake device
device = "/home/vagrant/scaleio1"

Vagrant.configure("2") do |config|

  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = "#{node[:box]}"
      node_config.vm.host_name = "#{node[:hostname]}.#{domain}"
      node_config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "1024"]
      end
      node_config.vm.network "private_network", ip: "#{node[:ipaddress]}"
      #node_config.vm.provision "update", type: "shell", path: "scripts/update.sh"

      if node[:type] == "tb"
        node_config.vm.provision "download", type: "shell", path: "scripts/download.sh"
      end

      node_config.vm.provision "shell" do |s|
        s.path = "scripts/install.sh"
        s.args   = "-n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -t #{tbip} -p #{password} -c #{clusterinstall} -x #{node[:type]}"
      end

    end
  end
end
