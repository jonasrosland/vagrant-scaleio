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
# "scaleio-gw" is optional, additional nodes with any box is also possible (select type: "none")
# "chef/centos-6.6" or "chef/centos-7.0" are supported boxes, also a mixed config
nodes = [
{hostname: "scaleio-tb", ipaddress: "#{tbip}", type: "tb", box: "chef/centos-7.0", memory: "1024"},
{hostname: 'scaleio-mdm1', ipaddress: "#{firstmdmip}", type: 'mdm1', box: "chef/centos-7.0", memory: "1024"},
{hostname: 'scaleio-mdm2', ipaddress: "#{secondmdmip}", type: 'mdm2', box: "chef/centos-7.0", memory: "1024"},
{hostname: "scaleio-gw", ipaddress: "#{network}.14", type: "gw", box: "chef/centos-7.0", memory: "512"}
]

# Install ScaleIO cluster automatically or IM only
clusterinstall = "True" #If True a fully working ScaleIO cluster is installed. False mean only IM is installed on node "gw".

# 100GB fake device
device = "/home/vagrant/scaleio1"

Vagrant.configure("2") do |config|
  # try to enable caching to speed up package installation for second run
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = "#{node[:box]}"
      node_config.vm.host_name = "#{node[:hostname]}.#{domain}"
      node_config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "#{node[:memory]}"]
      end
      node_config.vm.network "private_network", ip: "#{node[:ipaddress]}"

      # update box
      node_config.vm.provision "update", type: "shell", path: "scripts/update.sh"

      if node[:type] == "tb"
        # download latest ScaleIO bits
        node_config.vm.provision "download", type: "shell", path: "scripts/download.sh"
      end

      node_config.vm.provision "shell" do |s|
        s.path = "scripts/install.sh"
        s.args   = "-d #{device} -f #{firstmdmip} -s #{secondmdmip} -t #{tbip} -p #{password} -c #{clusterinstall} -n #{node[:type]}"
      end

    end
  end
end
