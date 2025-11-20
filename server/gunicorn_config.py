bind = "127.0.0.1:5000"
workers = 4
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5

# Logging
import os
basedir = os.path.abspath(os.path.dirname(__file__))
log_dir = os.path.join(basedir, "logs")
os.makedirs(log_dir, exist_ok=True)

accesslog = os.path.join(log_dir, "gunicorn-access.log")
errorlog = os.path.join(log_dir, "gunicorn-error.log")
loglevel = "info"

# Process naming
proc_name = "bhp-poc-file-upload-api"

# Server mechanics
daemon = False
pidfile = os.path.join(basedir, "gunicorn.pid")

# Max requests per worker (prevents memory leaks)
max_requests = 1000
max_requests_jitter = 50
