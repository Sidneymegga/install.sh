#!/bin/bash

# Instalação de dependências
sudo apt-get update
sudo apt-get install -y python3-pip
sudo pip3 install psutil

# Criação do arquivo logfile.txt
sudo touch /root/logfile.txt

# Permissões necessárias para o arquivo logfile.txt
sudo chmod 644 /root/logfile.txt

# Criação do script de monitoramento
echo "
#!/usr/bin/env python3

import psutil
import os
import datetime
import subprocess
import socket
import time

host = '127.0.0.1'
ports = [80, 8080]
cpu_threshold = 90
journald_threshold = 70
verification_count = 0
log_file_path = '/root/logfile.txt'

def check_port(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0

def restart_proxy(reason):
    global verification_count
    if reason == 'cpu':
        cpu_usage = psutil.cpu_percent()
        log_entry = f'{datetime.datetime.now()} - MEGGA CLOUD REINICIANDO PROXY devido ao alto uso de CPU ({cpu_usage:.1f}%).'
    elif reason == 'journald':
        log_entry = f'{datetime.datetime.now()} - MEGGA CLOUD REINICIANDO PROXY devido ao alto uso do Journald.'
    else:
        return  # Não reinicia se a razão não for reconhecida

    for port in ports:
        os.system(f'sudo service proxy-{port} restart')
    with open(log_file_path, 'a') as logfile:
        logfile.write(log_entry + '\n')
    print(log_entry)
    verification_count = 0  # Reset the count after restarting
    time.sleep(180)  # Wait 3 minutes after restarting before resuming verification

def clean_log_file():
    # Verifica se o arquivo de log existe
    if os.path.exists(log_file_path):
        # Abre o arquivo em modo de escrita para limpar seu conteúdo
        with open(log_file_path, 'w') as logfile:
            logfile.write('')
        print(f'O arquivo de log {log_file_path} foi limpo.')

def main():
    global verification_count

    # Limpa o arquivo de log inicialmente
    clean_log_file()

    while True:
        cpu_usage = psutil.cpu_percent()
        journald_cpu_usage = 0

        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
            if proc.info['name'] == 'systemd-journald':
                journald_cpu_usage = proc.info['cpu_percent']
                break

        print(f'CPU Usage: {cpu_usage:.1f}%, Journald CPU Usage: {journald_cpu_usage:.1f}%')

        if cpu_usage > cpu_threshold:
            verification_count += 1
        elif journald_cpu_usage > journald_threshold:
            verification_count += 1
        else:
            verification_count = 0

        if verification_count == 3:
            if cpu_usage > cpu_threshold:
                restart_proxy('cpu')
            elif journald_cpu_usage > journald_threshold:
                restart_proxy('journald')
        time.sleep(5)  # Wait 5 seconds before checking again

        # Verifica se passaram 5 horas desde a última limpeza do arquivo de log
        if datetime.datetime.now().hour % 5 == 0:
            clean_log_file()
            # Espera 1 minuto antes de limpar novamente para garantir que não haja sobreposição com o próximo ciclo de limpeza
            time.sleep(60)

if __name__ == '__main__':
    main()
" > /root/monitor_cpu.py

# Permissões necessárias para o script de monitoramento
sudo chmod +x /root/monitor_cpu.py

# Configuração do cron para executar o monitoramento a cada 10 minutos
(crontab -l ; echo "@reboot sleep 120 && /usr/bin/python3 /root/monitor_cpu.py >> /root/logfile.txt 2>&1") | crontab -

echo "Instalação concluída com sucesso!"
