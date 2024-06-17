import os
import subprocess

def run_command(command):
    """Run a system command and check for errors."""
    print(f"Running command: {' '.join(command)}")
    result = subprocess.run(command, check=True, text=True)
    if result.returncode != 0:
        print(f"Error: Command {' '.join(command)} failed with exit code {result.returncode}")
        exit(result.returncode)

def install_3proxy():
    # Update package list and install dependencies
    run_command(['sudo', 'apt-get', 'update'])
    run_command(['sudo', 'apt-get', 'install', '-y', 'build-essential', 'wget'])

    # Download and extract 3proxy
    run_command(['wget', 'https://github.com/3proxy/3proxy/archive/refs/tags/0.9.3.tar.gz'])
    run_command(['tar', 'xzf', '0.9.3.tar.gz'])

    # Build 3proxy
    os.chdir('3proxy-0.9.3')
    run_command(['make', '-f', 'Makefile.Linux'])

    # Create necessary directories and copy files
    run_command(['sudo', 'mkdir', '-p', '/usr/local/3proxy/bin'])
    run_command(['sudo', 'mkdir', '-p', '/usr/local/3proxy/logs'])
    run_command(['sudo', 'mkdir', '-p', '/usr/local/3proxy/conf'])
    run_command(['sudo', 'cp', 'src/3proxy', '/usr/local/3proxy/bin/'])

    # Create a sample configuration file
    config = """
daemon
maxconn 1024
nserver 8.8.8.8
nserver 8.8.4.4
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
auth none
allow *
proxy -p8080
flush
"""
    with open('/tmp/3proxy.cfg', 'w') as config_file:
        config_file.write(config)
    run_command(['sudo', 'mv', '/tmp/3proxy.cfg', '/usr/local/3proxy/conf/3proxy.cfg'])

    # Create systemd service file
    service_file = """
[Unit]
Description=3proxy Proxy Server
After=network.target

[Service]
ExecStart=/usr/local/3proxy/bin/3proxy /usr/local/3proxy/conf/3proxy.cfg
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=always
Type=simple

[Install]
WantedBy=multi-user.target
"""
    with open('/tmp/3proxy.service', 'w') as service:
        service.write(service_file)
    run_command(['sudo', 'mv', '/tmp/3proxy.service', '/etc/systemd/system/3proxy.service'])

    # Reload systemd, enable and start 3proxy service
    run_command(['sudo', 'systemctl', 'daemon-reload'])
    run_command(['sudo', 'systemctl', 'enable', '3proxy'])
    run_command(['sudo', 'systemctl', 'start', '3proxy'])

    print("3proxy has been installed and started successfully.")

if __name__ == '__main__':
    install_3proxy()