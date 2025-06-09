#!/usr/bin/env python3
"""
Простой клиент для тестирования Send Learn сервера
"""

import socket
import struct
import time

def test_connection():
    """Тест подключения к серверу"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    try:
        print("🔗 Connecting to Send Learn server...")
        sock.connect(('127.0.0.1', 8080))
        print("✅ Connected!")
        
        # Отправляем handshake
        header = struct.pack('<IIIQI I', 
                           0x53454E44,  # magic "SEND"
                           1,           # packet type (handshake)
                           0,           # data size
                           int(time.time() * 1000),  # timestamp
                           1,           # sequence number
                           0)           # checksum
                           
        sock.send(header)
        print("🤝 Handshake sent")
        
        # Отправляем тестовые данные
        test_data = b"Test data from Python client"
        data_header = struct.pack('<IIIQI I',
                                0x53454E44,     # magic
                                2,              # packet type (data)
                                len(test_data), # data size
                                int(time.time() * 1000),
                                2,              # sequence number
                                0)              # checksum
                                
        sock.send(data_header)
        sock.send(test_data)
        print(f"📊 Test data sent: {len(test_data)} bytes")
        
        time.sleep(1)
        print("✅ Test completed successfully")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        sock.close()

if __name__ == "__main__":
    test_connection()
