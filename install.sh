#!/bin/bash

# Instalação de dependências
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install psutil

# Criação do script de monitoramento
echo '
import psutil
import os
import datetime
import subprocess

portas = [80, 8080]
cpu_threshold = 80

def restart_proxy():
    for port in portas:
        os.system(f"sudo service proxy-{port} restart")
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"{current_time} - MEGGA CLOUD REINICIANDO PROXY."
    with open("/root/logfile.txt", "a") as logfile:
        logfile.write(log_entry + "\n")
    print(log_entry)

def restart_journald():
    subprocess.run(["sudo", "systemctl", "restart", "systemd-journald"])
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"{current_time} - REINICIANDO JOURNALD DEVIDO AO ALTO USO DE CPU."
    with open("/root/logfile.txt", "a") as logfile:
        logfile.write(log_entry + "\n")
    print(log_entry)

def main():
    # Monitora o uso de CPU
    cpu_usage = psutil.cpu_percent(interval=1)
    print(f"CPU Usage: {cpu_usage}")
    if cpu_usage > cpu_threshold:
        restart_proxy()

    # Monitora o processo systemd-journald
    for proc in psutil.process_iter(["pid", "name", "cpu_percent"]):
        if proc.info["name"] == "systemd-journald":
            journald_cpu_usage = proc.info["cpu_percent"]
            print(f"Journald CPU Usage: {journald_cpu_usage}")
            if journald_cpu_usage > cpu_threshold:
                restart_journald()
                break

if __name__ == "__main__":
    main()
' > /root/monitor_cpu.py

# Permissões necessárias
sudo chmod +x /root/monitor_cpu.py
sudo touch /root/logfile.txt
sudo chmod 644 /root/logfile.txt

# Adiciona comando de inicialização no cron
(crontab -l ; echo "*/3 * * * * /usr/bin/python3 /root/monitor_cpu.py > /dev/null 2>&1") | crontab -

echo "Instalação concluída com sucesso!"
