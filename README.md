# Droits Manager

Desktop control center for Droit delivery boxes and drones. Qt 6 / QML application with a live map, box connection management, live video, and order tracking.

## Features

- **Live Map** — OSM map with delivery box and drone markers. Clicking the box marker opens a drawer with a live video preview and Open/Close box controls.
- **Droids screen** — table of connected delivery boxes backed by SQLite. Adding a box pings it first; it is only saved once it replies. While the screen is open, every box is pinged every 3 seconds and its status badge updates automatically. Each online box has a **Video** button that opens its live stream.
- **Drones / Orders screens** — drone connection table and order list (in-memory for now).

## Box communication

Boxes run [box-core](../box-core/README.md): a TCP server on port `5050` speaking one JSON object per line:

```json
→ {"id": 1, "command": "ping"}
← {"id": 1, "command": "ping", "status": "ok", "data": {"name": "droit-box-01"}}
```

Commands used by the app: `ping` (reachability + status polling), `open`, `close` (box mechanism, sent from the map drawer).

Each box also serves a TCP video stream on port `8554`. The app plays it with a GStreamer pipeline (`tcpclientsrc ! decodebin ! … ! appsink`) rendered into a QML `VideoOutput`. `rtsp://` URIs and a `test` pattern source are also supported by the pipeline builder.

## Architecture

```
Main.qml                     window, nav, screen stack
qml/Screens/                 LiveMap, Droids, Orders, Drones
qml/Components/              tables, modals, markers, drawer
qml/Controls/                buttons, text field
qml/Theme/Theme.qml          design tokens (singleton)
src/
  BoxProtocol.h              shared constants: command port 5050, video port 8554
  BoxStore.{h,cpp}           QML singleton model of saved boxes: SQLite persistence,
                             connect-with-ping, 3 s status polling
  BoxClient.{h,cpp}          QML singleton for open/close commands (JSON protocol)
  BoxVideoReceiver.{h,cpp}   GStreamer appsink -> QVideoSink bridge (QML element)
  VideoPipeline.h            URI -> gst-launch pipeline string builder
```

Boxes are stored in `boxes.db` under the platform app-data directory (on Linux: `~/.local/share/Droits/DroidsManager/`). Rows carry `id`, `name`, `ip_address`; connection status is runtime-only and always starts as Offline until the first ping.

## Building

Requirements:

- Qt 6.8+ (Quick, QuickControls2, Svg, Location, Positioning, Network, Multimedia, Sql)
- GStreamer 1.0 development packages: `gstreamer-1.0`, `gstreamer-app-1.0`, `gstreamer-video-1.0`
  (plus runtime plugins for the codecs in use, e.g. gst-plugins-good/bad and gst-libav)

```bash
cmake -S . -B build -G Ninja -DCMAKE_PREFIX_PATH=~/Qt/6.10.3/gcc_64
cmake --build build
./build/appDroidsManager
```

## Testing against a local box

Run the box server from `box-core` (mock GPIO/GPS via `.env`), then connect to `127.0.0.1` from the Droids screen. For video, serve any stream on port 8554, e.g.:

```bash
gst-launch-1.0 videotestsrc is-live=true ! x264enc tune=zerolatency \
  ! mpegtsmux ! tcpserversink host=0.0.0.0 port=8554
```
