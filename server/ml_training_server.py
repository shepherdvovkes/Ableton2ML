#!/usr/bin/env python3
"""
ML Training Data Server для сбора данных от Send Learn плагина
"""

import socket
import struct
import threading
import time
import json
import os
from datetime import datetime
from typing import Dict, List, Optional

class SendLearnServer:
    def __init__(self, host='0.0.0.0', port=8080):
        self.host = host
        self.port = port
        self.running = False
        self.clients = {}
        
        # Статистика
        self.stats = {
            'packets_received': 0,
            'bytes_received': 0,
            'clients_connected': 0,
            'errors': 0
        }
        
        # Создаем директорию для данных
        self.data_dir = "collected_data"
        os.makedirs(self.data_dir, exist_ok=True)
        
    def start_server(self):
        """Запуск сервера"""
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        try:
            self.socket.bind((self.host, self.port))
            self.socket.listen(5)
            self.running = True
            
            print(f"🚀 Send Learn Server started on {self.host}:{self.port}")
            print(f"📁 Data directory: {self.data_dir}")
            
            while self.running:
                try:
                    client_socket, address = self.socket.accept()
                    print(f"🔗 Client connected: {address}")
                    
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, address)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                    self.stats['clients_connected'] += 1
                    
                except socket.error as e:
                    if self.running:
                        print(f"❌ Connection error: {e}")
                        
        except Exception as e:
            print(f"❌ Server error: {e}")
        finally:
            self.cleanup()
            
    def handle_client(self, client_socket, address):
        """Обработка клиента"""
        client_id = f"{address[0]}:{address[1]}"
        
        try:
            while self.running:
                # Читаем заголовок пакета
                header_data = self.receive_exact(client_socket, 24)
                if not header_data:
                    break
                    
                # Парсим заголовок
                magic, packet_type, data_size, timestamp, seq_num, checksum = struct.unpack('<IIIQI I', header_data)
                
                if magic != 0x53454E44:  # "SEND"
                    continue
                    
                # Читаем данные
                packet_data = self.receive_exact(client_socket, data_size)
                if not packet_data:
                    break
                    
                # Обрабатываем пакет
                self.process_packet(packet_type, packet_data, client_id)
                self.stats['packets_received'] += 1
                self.stats['bytes_received'] += len(header_data) + len(packet_data)
                
        except Exception as e:
            print(f"❌ Client error {client_id}: {e}")
            self.stats['errors'] += 1
        finally:
            client_socket.close()
            print(f"🔌 Client disconnected: {client_id}")
            
    def receive_exact(self, sock, size):
        """Получение точного количества байт"""
        data = b''
        while len(data) < size:
            chunk = sock.recv(size - len(data))
            if not chunk:
                return None
            data += chunk
        return data
        
    def process_packet(self, packet_type, data, client_id):
        """Обработка пакета"""
        if packet_type == 1:  # Handshake
            print(f"🤝 Handshake from {client_id}")
        elif packet_type == 2:  # MIDI + Audio data
            self.process_data_packet(data, client_id)
        elif packet_type == 3:  # Heartbeat
            pass
            
    def process_data_packet(self, data, client_id):
        """Обработка пакета с данными"""
        try:
            # Простое логирование (в реальности здесь будет полный парсинг)
            timestamp = time.time()
            print(f"📊 Data packet from {client_id}: {len(data)} bytes")
            
            # Сохраняем в файл для анализа
            filename = f"{self.data_dir}/data_{client_id.replace(':', '_')}_{int(timestamp)}.bin"
            with open(filename, 'wb') as f:
                f.write(data)
                
        except Exception as e:
            print(f"❌ Data processing error: {e}")
            
    def print_stats(self):
        """Вывод статистики"""
        print("\n" + "="*50)
        print("📊 SERVER STATISTICS")
        print("="*50)
        print(f"Packets received: {self.stats['packets_received']}")
        print(f"Bytes received: {self.stats['bytes_received']:,}")
        print(f"Clients connected: {self.stats['clients_connected']}")
        print(f"Errors: {self.stats['errors']}")
        print("="*50)
        
    def cleanup(self):
        """Очистка ресурсов"""
        self.running = False
        if hasattr(self, 'socket'):
            self.socket.close()
        print("🛑 Server stopped")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Send Learn ML Training Server')
    parser.add_argument('--host', default='0.0.0.0', help='Host address')
    parser.add_argument('--port', type=int, default=8080, help='Port number')
    
    args = parser.parse_args()
    
    server = SendLearnServer(args.host, args.port)
    
    try:
        # Запускаем сервер в отдельном потоке
        server_thread = threading.Thread(target=server.start_server)
        server_thread.daemon = True
        server_thread.start()
        
        print("Press Ctrl+C to stop the server")
        print("Commands: 'stats' - show statistics, 'quit' - exit")
        
        while True:
            try:
                command = input("> ").strip().lower()
                if command == 'stats':
                    server.print_stats()
                elif command == 'quit':
                    break
                elif command == 'help':
                    print("Available commands: stats, quit, help")
            except EOFError:
                break
                
    except KeyboardInterrupt:
        pass
    finally:
        server.cleanup()
        print("👋 Goodbye!")

if __name__ == "__main__":
    main()
