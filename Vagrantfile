# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use compatible Ubuntu box
  if `uname -m`.strip == "arm64"
    puts "Apple Silicon detected - Note: VirtualBox x86 emulation may be slow"
    puts "Consider using UTM or Parallels for better ARM64 support"
    config.vm.box = "bento/ubuntu-22.04"
  else
    config.vm.box = "ubuntu/jammy64"
    config.vm.box_version = "20231215.0.0"
  end
  
  # Parallels provider - optimal for Apple Silicon
  config.vm.provider "parallels" do |prl|
    prl.name = "my-scratch-pad-vm"
    prl.memory = 1024  # 1GB RAM
    prl.cpus = 2
    prl.update_guest_tools = true
    prl.check_guest_tools = false
    
    # Parallels-specific optimizations
    prl.customize ["set", :id, "--adaptive-hypervisor", "on"]
    prl.customize ["set", :id, "--nested-virt", "on"]
    prl.customize ["set", :id, "--pmem-limit", "auto"]
  end

  # VirtualBox provider - works on both Intel and Apple Silicon (fallback)
  config.vm.provider "virtualbox" do |vb|
    vb.name = "my-scratch-pad-vm"
    vb.memory = "1024"  # 1GB RAM
    vb.cpus = 2
    
    # Architecture-specific optimizations
    if `uname -m`.strip == "arm64"
      # ARM64 native - no emulation needed
      vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
    else
      # Intel Mac optimizations
      vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
      vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
    end
    
    # Enable verbose logging for debugging
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File.join(Dir.pwd, "ubuntu-jammy-console.log")]
  end

  # Network configuration - forward port 5001 from guest to host
  config.vm.network "forwarded_port", guest: 5001, host: 5001, host_ip: "127.0.0.1"

  # Sync the project directory to VM
  config.vm.synced_folder ".", "/home/vagrant/my-scratch-pad", 
    owner: "vagrant", group: "vagrant"

  # Provisioning script - inline for simplicity
  config.vm.provision "shell", inline: <<-SHELL
    echo "=== Provisioning My Scratch Pad VM ==="
    
    # Update system packages
    apt-get update -y
    apt-get upgrade -y
    
    # Install Python 3 and development tools
    apt-get install -y python3 python3-pip python3-venv curl wget htop sysstat
    
    # Navigate to app directory
    cd /home/vagrant/my-scratch-pad
    
    # Create virtual environment
    python3 -m venv venv
    source venv/bin/activate
    
    # Install Flask
    pip install flask
    
    # Initialize database
    python3 init_db.py
    
    # Set ownership
    chown -R vagrant:vagrant /home/vagrant/my-scratch-pad
    
    echo "=== VM Provisioning Complete ==="
    echo "Application available at: http://localhost:5001"
  SHELL

  # Start the application automatically
  config.vm.provision "shell", run: "always", privileged: false, inline: <<-SHELL
    cd /home/vagrant/my-scratch-pad
    # Kill any existing processes
    pkill -f "python.*app.py" || true
    # Start application in background
    source venv/bin/activate
    nohup python3 app.py > app.log 2>&1 &
    echo "My Scratch Pad started on port 5001"
  SHELL
end