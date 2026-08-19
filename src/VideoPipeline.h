#pragma once

#include <QString>
#include <QUrl>

namespace VideoPipeline {

// Supported URI formats:
// "tcp://<host>:<port>" -> TCP stream (container/codec auto-detected by decodebin)
// "rtsp://<url>"        -> RTSP stream over TCP
// "test"                -> Test pattern (for development)
// Raw pipeline string   -> Pass through directly (must contain appsink named "sink")
inline QString buildPipelineString(const QString &uri)
{
    if (uri.isEmpty())
        return {};

    if (uri.startsWith(QLatin1String("tcp://"))) {
        const QUrl url(uri);
        if (url.host().isEmpty() || url.port() <= 0)
            return {};

        return QStringLiteral(
            "tcpclientsrc host=%1 port=%2 "
            "! decodebin "
            "! videoconvert "
            "! video/x-raw,format=BGRA "
            "! appsink name=sink emit-signals=true sync=false drop=true max-buffers=1"
        ).arg(url.host()).arg(url.port());
    }

    if (uri.startsWith(QLatin1String("rtsp://"))) {
        return QStringLiteral(
            "rtspsrc location=\"%1\" latency=100 protocols=tcp "
            "! rtph264depay "
            "! avdec_h264 "
            "! videoconvert "
            "! video/x-raw,format=BGRA "
            "! appsink name=sink emit-signals=true sync=false drop=true max-buffers=1"
        ).arg(uri);
    }

    if (uri == QLatin1String("test")) {
        return QStringLiteral(
            "videotestsrc is-live=true pattern=smpte "
            "! video/x-raw,width=640,height=480,framerate=30/1 "
            "! videoconvert "
            "! video/x-raw,format=BGRA "
            "! appsink name=sink emit-signals=true sync=false drop=true max-buffers=1"
        );
    }

    return uri;
}

} // namespace VideoPipeline
