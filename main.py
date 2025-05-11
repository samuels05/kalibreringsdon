import time
import os
import requests
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Define the folder to monitor and the server URL
MONITOR_FOLDER = '/path/to/your/folder'
SERVER_URL = 'http://yourserver.com/upload'  # Change this to your server's upload URL

class FileHandler(FileSystemEventHandler):
    def on_created(self, event):
        # Check if the created event is for a file
        if not event.is_directory:
            print(f'File created: {event.src_path}')
            self.send_file(event.src_path)

    def send_file(self, file_path):
        # Send the file to the server
        with open(file_path, 'rb') as f:
            files = {'file': f}
            response = requests.post(SERVER_URL, files=files)
            if response.status_code == 200:
                print(f'Successfully sent: {file_path}')
            else:
                print(f'Failed to send: {file_path}, Status code: {response.status_code}')

if __name__ == "__main__":
    event_handler = FileHandler()
    observer = Observer()
    observer.schedule(event_handler, MONITOR_FOLDER, recursive=False)

    try:
        observer.start()
        print(f'Monitoring folder: {MONITOR_FOLDER}')
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
