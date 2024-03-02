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
import socket
import time

host = "127.0.0.1"
ports = [80, 8080]
cpu_threshold = 80
verification_count = 0

def check_port(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0

def restart_proxy():
    for port in ports:
        os.system(f"sudo service proxy-{port} restart")
    current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"{current_time} - MEGGA CLOUD REINICIANDO PROXY."
    with open("/root/logfile.txt", "a") as logfile:
        logfile.write(log_entry + "\n")
    print(log_entry)

def main():
    global verification_count

    cpu_usage = psutil.cpu_percent()
    print(f"CPU Usage: {cpu_usage}")  # Mostra o uso da CPU ao iniciar o script

    # Loop para fazer 3 verificações a cada 10 minutos
    for i in range(3):
        cpu_usage = psutil.cpu_percent(interval=1)
        print(f"CPU Usage: {cpu_usage}")

        if cpu_usage > cpu_threshold:
            verification_count += 1

        # Espera 1 minuto antes da próxima verificação
        time.sleep(60)

    # Se todas as 3 verificações tiverem um uso alto da CPU, reinicie as portas
    if verification_count == 3:
        restart_proxy()

if __name__ == "__main__":
    main()
' > /root/monitor_cpu.py

# Permissões necessárias
sudo chmod +x /root/monitor_cpu.py
sudo touch /root/logfile.txt
sudo chmod 644 /root/logfile.txt

# Adiciona comando de inicialização no cron para executar a cada 10 minutos
(crontab -l ; echo "*/10 * * * * /usr/bin/python3 /root/monitor_cpu.py > /dev/null 2>&1") | crontab -

echo "Instalação concluída com sucesso!"
