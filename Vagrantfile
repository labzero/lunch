# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
ram_allocation = '2048'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = 'ubuntu/trusty64'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 1521, host: 1521

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.synced_folder ENV['ORACLE_INSTALLER'] || '.', '/vagrant_oracle_installer'

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider 'virtualbox' do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ['modifyvm', :id, '--memory', ram_allocation]
  end
  #
  # View the documentation for the provider you're using for more
  # information on available options.

  # Enable provisioning with CFEngine. CFEngine Community packages are
  # automatically installed. For example, configure the host as a
  # policy server and optionally a policy file to run:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.am_policy_hub = true
  #   # cf.run_file = "motd.cf"
  # end
  #
  # You can also configure and bootstrap a client to an existing
  # policy server:
  #
  # config.vm.provision "cfengine" do |cf|
  #   cf.policy_server_address = "10.0.2.15"
  # end

  # Enable provisioning with Puppet stand alone.  Puppet manifests
  # are contained in a directory path relative to this Vagrantfile.
  # You will need to create the manifests directory and a manifest in
  # the file default.pp in the manifests_path directory.
  #
  # config.vm.provision "puppet" do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "default.pp"
  # end

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding
  # some recipes and/or roles.
  #
  # config.vm.provision "chef_solo" do |chef|
  #   chef.cookbooks_path = "../my-recipes/cookbooks"
  #   chef.roles_path = "../my-recipes/roles"
  #   chef.data_bags_path = "../my-recipes/data_bags"
  #   chef.add_recipe "mysql"
  #   chef.add_role "web"
  #
  #   # You may also specify custom JSON attributes:
  #   chef.json = { mysql_password: "foo" }
  # end

  # Enable provisioning with chef server, specifying the chef server URL,
  # and the path to the validation key (relative to this Vagrantfile).
  #
  # The Opscode Platform uses HTTPS. Substitute your organization for
  # ORGNAME in the URL and validation key.
  #
  # If you have your own Chef Server, use the appropriate URL, which may be
  # HTTP instead of HTTPS depending on your configuration. Also change the
  # validation key to validation.pem.
  #
  # config.vm.provision "chef_client" do |chef|
  #   chef.chef_server_url = "https://api.opscode.com/organizations/ORGNAME"
  #   chef.validation_key_path = "ORGNAME-validator.pem"
  # end
  #
  # If you're using the Opscode platform, your validator client is
  # ORGNAME-validator, replacing ORGNAME with your organization name.
  #
  # If you have your own Chef Server, the default validation client name is
  # chef-validator, unless you changed the configuration.
  #
  #   chef.validation_client_name = "ORGNAME-validator"

  oracle_rpm_name = ENV['ORACLE_INSTALLER_NAME'] || 'oracle-xe-11.2.0-1.0.x86_64.rpm'

  chkconfig_script = <<EOS
#!/bin/bash
# Oracle 11gR2 XE installer chkconfig hack for Ubuntu
file=/etc/init.d/oracle-xe
if [[ ! `tail -n1 $file | grep INIT` ]]; then
echo >> $file
echo '### BEGIN INIT INFO' >> $file
echo '# Provides: OracleXE' >> $file
echo '# Required-Start: $remote_fs $syslog' >> $file
echo '# Required-Stop: $remote_fs $syslog' >> $file
echo '# Default-Start: 2 3 4 5' >> $file
echo '# Default-Stop: 0 1 6' >> $file
echo '# Short-Description: Oracle 11g Express Edition' >> $file
echo '### END INIT INFO' >> $file
fi
update-rc.d oracle-xe defaults 80 01
#EOF
EOS

  oracle_xe_response_file = <<EOS
ORACLE_HTTP_PORT=8080
ORACLE_LISTENER_PORT=1521
ORACLE_PASSWORD=password
ORACLE_CONFIRM_PASSWORD=password
ORACLE_DBENABLE=y
EOS

  shm_load_script = <<EOS
#!/bin/sh
case "$1" in
start) mkdir /var/lock/subsys 2>/dev/null
touch /var/lock/subsys/listener
rm /dev/shm 2>/dev/null
mkdir /dev/shm 2>/dev/null
mount -t tmpfs shmfs -o size=#{ram_allocation}m /dev/shm ;;
*) echo error
exit 1 ;;
esac
EOS

  bashrc_changes = <<EOS
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export ORACLE_SID=XE
export NLS_LANG=`$ORACLE_HOME/bin/nls_lang.sh`
export ORACLE_BASE=/u01/app/oracle
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME/bin:$PATH
EOS

  sql_seed = <<EOS
ALTER PROFILE DEFAULT LIMIT password_life_time UNLIMITED;
CREATE USER member_development IDENTIFIED BY notthatsecret;
GRANT CONNECT TO member_development;
CREATE USER member_test IDENTIFIED BY notthatsecret;
GRANT CONNECT TO member_test;
CREATE USER member_production IDENTIFIED BY notthatsecret;
GRANT CONNECT TO member_production;
EOS

  provision_script = <<EOS
  sudo /etc/init.d/oracle-xe status 2>/dev/null && exit
  if [[ ! -f /vagrant_oracle_installer/#{oracle_rpm_name} ]]; then
    echo 'Oracle Installer NOT FOUND! Make sure you exported ORACLE_INSTALLER with a path to the directory containing the RPM' 1>&2
    exit 1
  fi
  sudo apt-get update
  sudo apt-get -q -y --force-yes install alien libaio1 unixodbc openjdk-7-jre
  echo 'export JAVA_HOME=/usr/lib/jvm/java-7-oracle
export PATH=$JAVA_HOME/bin:$PATH' | cat - /etc/bash.bashrc | sudo tee /etc/bash.bashrc > /dev/null
  source /etc/bash.bashrc
  cd /vagrant_oracle_installer
  test -f "`ls *.deb`" || (echo "Building .deb, this will take A LONG TIME..."; sudo alien --scripts -k -d #{oracle_rpm_name})
  DEB_NAME=`ls *.deb`
  echo #{Shellwords.escape(chkconfig_script)} | sudo tee -a /sbin/chkconfig
  sudo chmod 755 /sbin/chkconfig
  echo '# Oracle 11g XE kernel parameters
fs.file-max=6815744
net.ipv4.ip_local_port_range=9000 65000
kernel.sem=250 32000 100 128
kernel.shmmax=536870912' | sudo tee -a /etc/sysctl.d/60-oracle.conf
  sudo service procps start

  sudo ln -s /usr/bin/awk /bin/awk
  mkdir /var/lock/subsys
  touch /var/lock/subsys/listener

  sudo dpkg --install $DEB_NAME

  sudo rm -rf /dev/shm
  sudo mkdir /dev/shm
  sudo mount -t tmpfs shmfs -o size=#{ram_allocation}m /dev/shm


  echo #{Shellwords.escape(shm_load_script)} | sudo tee -a /etc/rc2.d/S01shm_load
  sudo chmod 755 /etc/rc2.d/S01shm_load

  echo #{Shellwords.escape(oracle_xe_response_file)} > ~/xe.rsp
  sudo /etc/init.d/oracle-xe configure responseFile=~/xe.rsp

  echo #{Shellwords.escape(bashrc_changes)} | cat - /etc/bash.bashrc | sudo tee /etc/bash.bashrc > /dev/null
  source /etc/bash.bashrc

  echo #{Shellwords.escape(sql_seed)} | sqlplus SYSTEM/password@localhost:1521
EOS

  config.vm.provision "shell", inline: provision_script, privileged: false
end
