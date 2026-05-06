# Camera Pi Zero Setup

## MediaMTX Service

`/etc/systemd/system/mediamtx.service`

```ini
[Unit]
Description=MediaMTX
After=network-online.target
Wants=network-online.target

[Service]
User=mediamtx
Group=mediamtx
SupplementaryGroups=video
ExecStart=/usr/local/bin/mediamtx /etc/mediamtx/mediamtx.yml
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

## MediaMTX Config

`/etc/mediamtx/mediamtx.yml`

```yaml
logLevel: info
rtspTransports: [tcp]

# WebRTC (port 8889)
webrtc: yes

paths:
  cam:
    source: rpiCamera
    sourceOnDemand: no  # keeps camera awake so snapshot can always pull a frame
    rpiCameraWidth: 1280
    rpiCameraHeight: 720
    rpiCameraFPS: 15
    rpiCameraCodec: hardwareH264
    rpiCameraIDRPeriod: 30
    rpiCameraBitrate: 1500000
```

## Camera Snapshot Loop Service

`/etc/systemd/system/camsnap-loop.service`

```ini
[Unit]
Description=Camera snapshot writer
After=network-online.target mediamtx.service
Wants=network-online.target
Requires=mediamtx.service

[Service]
Type=simple
ExecStartPre=-/usr/bin/pkill -f ffmpeg.*rtsp://127.0.0.1:8554/cam
ExecStart=/usr/bin/flock /run/camsnap-loop.lock /usr/bin/ffmpeg \
  -hide_banner -loglevel warning \
  -rtsp_transport tcp \
  -i rtsp://127.0.0.1:8554/cam \
  -vf fps=1 -update 1 -y /dev/shm/snapshot.jpg
Restart=on-failure
RestartSec=5
KillMode=control-group
User=root

[Install]
WantedBy=multi-user.target
```

## Flask Snapshot Service

`/etc/systemd/system/camsnap.service`

```ini
[Unit]
Description=Flask snapshot service
After=network-online.target mediamtx.service
Wants=network-online.target

[Service]
User=scott
WorkingDirectory=/opt/camsnap
ExecStart=/opt/camsnap/venv/bin/gunicorn \
  --workers 1 --threads 1 --worker-class sync \
  --bind 0.0.0.0:8080 app:app
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
```

`/opt/camsnap/app.py`

```python
import os
from flask import Flask, Response

app = Flask(__name__)
SNAPSHOT_PATH = "/dev/shm/snapshot.jpg"

@app.get("/snapshot")
def snapshot():
    if os.path.exists(SNAPSHOT_PATH):
        with open(SNAPSHOT_PATH, "rb") as f:
            return Response(f.read(), mimetype="image/jpeg", headers={"Cache-Control": "no-cache"})
    return "Not ready", 503

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
```

## Moonraker Config

`moonraker.conf` — trust home network and Tailscale:

```ini
[authorization]
trusted_clients:
  127.0.0.1
  192.168.0.0/16
  100.64.0.0/10
```

## Network / WiFi Tuning

`/etc/sysctl.d/99-tailscale.conf` — Tailscale recommends disabling GRO offloads.

`/etc/rc.local`

```bash
sudo ethtool -K wlan0 rx-udp-gro-forwarding on rx-gro-list off
sudo iw dev wlan0 set power_save off
```

Tailscale admin: https://login.tailscale.com/admin/users

## Reload Services

```bash
sudo systemctl daemon-reload
sudo systemctl restart mediamtx
```
