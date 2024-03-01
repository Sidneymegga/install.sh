import psutil
import os
import datetime
import subprocess
import socket

host = '127.0.0.1'
ports = [80, 8080]
cpu_threshold = 70

def check_port(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0

def restart_proxy():
    for port in ports:
        os.system(f'sudo service proxy-{port} restart')
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f'{current_time} - MEGGA CLOUD REINICIANDO PROXY.'
    with open('/root/logfile.txt', 'a') as logfile:
        logfile.write(log_entry + '\n')
    print(log_entry)  

def restart_journald():
    subprocess.run(['sudo', 'systemctl', 'restart', 'systemd-journald'])
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f'{current_time} - REINICIANDO JOURNALD DEVIDO AO ALTO USO DE CPU.'
    with open('/root/logfile.txt', 'a') as logfile:
        logfile.write(log_entry + '\n')
    print(log_entry)

def main():
    cpu_usage = psutil.cpu_percent(interval=1)
    journald_cpu_usage = 0
    print(f'CPU Usage: {cpu_usage}')
    
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
        if proc.info['name'] == 'systemd-journald':
            journald_cpu_usage = proc.info['cpu_percent']
            print(f'Journald CPU Usage: {journald_cpu_usage}')
            break

    if cpu_usage > cpu_threshold:
        restart_proxy()

    if journald_cpu_usage > cpu_threshold:
        restart_journald()

if __name__ == '__main__':
    main()
