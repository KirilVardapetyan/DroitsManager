#include "BoxVideoReceiver.h"
#include "VideoPipeline.h"

#include <QDebug>
#include <gst/video/video-info.h>

namespace {
constexpr auto VIDEO_LOG_PREFIX = "[BoxVideo]";

void ensureGstInitialized()
{
    static const bool initialized = []() {
        gst_init(nullptr, nullptr);
        return true;
    }();
    Q_UNUSED(initialized);
}

void videoInfo(const QString &message)
{
    qInfo().noquote() << VIDEO_LOG_PREFIX << message;
}

void videoWarning(const QString &message)
{
    qWarning().noquote() << VIDEO_LOG_PREFIX << message;
}
}

BoxVideoReceiver::BoxVideoReceiver(QObject *parent)
    : QObject(parent)
{
    ensureGstInitialized();

    m_receiveTimeoutTimer.setSingleShot(true);
    m_receiveTimeoutTimer.setInterval(2000);
    connect(&m_receiveTimeoutTimer, &QTimer::timeout, this, [this]() {
        if (m_receiving.exchange(false))
            emit receivingChanged();
    });
}

BoxVideoReceiver::~BoxVideoReceiver()
{
    stopPipeline();
}

QVideoSink *BoxVideoReceiver::videoSink() const
{
    return m_videoSink;
}

void BoxVideoReceiver::setVideoSink(QVideoSink *sink)
{
    {
        QMutexLocker lock(&m_sinkMutex);
        if (m_videoSink == sink)
            return;
        if (m_videoSink)
            QObject::disconnect(m_videoSink, &QObject::destroyed, this, nullptr);
        m_videoSink = sink;
        if (m_videoSink) {
            // DirectConnection so the pointer is nulled immediately on the destroying thread
            // (always main thread for QML-owned sinks). The destroyed handler only swaps
            // m_videoSink under m_sinkMutex — no other lock is taken inside, keeping
            // m_sinkMutex a true leaf lock. The generation bump ensures any queued lambdas
            // that raced past the m_running check drop themselves before they reach m_videoSink.
            QObject::connect(m_videoSink, &QObject::destroyed, this, [this]() {
                m_generation.fetch_add(1, std::memory_order_relaxed);
                QMutexLocker lock(&m_sinkMutex);
                m_videoSink = nullptr;
            }, Qt::DirectConnection);
        }
        // Bump generation whenever the sink identity changes so stale queued frames
        // targeting the old sink are discarded.
        m_generation.fetch_add(1, std::memory_order_relaxed);
    }
    emit videoSinkChanged();
}

bool BoxVideoReceiver::receiving() const
{
    return m_receiving;
}

QString BoxVideoReceiver::uri() const
{
    return m_uri;
}

void BoxVideoReceiver::setUri(const QString &uri)
{
    if (m_uri == uri)
        return;
    m_uri = uri;
    videoInfo(QStringLiteral("receiver URI set to %1").arg(m_uri));
    emit uriChanged();
    restartIfNeeded();
}

bool BoxVideoReceiver::active() const
{
    return m_active;
}

void BoxVideoReceiver::setActive(bool active)
{
    if (m_active == active)
        return;
    m_active = active;
    emit activeChanged();

    if (m_active)
        restartIfNeeded();
    else
        stopPipeline();
}

void BoxVideoReceiver::restartIfNeeded()
{
    stopPipeline();
    if (m_active && !m_uri.isEmpty())
        startPipeline();
}

void BoxVideoReceiver::startPipeline()
{
    if (m_running.load())
        return;

    QString pipelineStr = VideoPipeline::buildPipelineString(m_uri);
    if (pipelineStr.isEmpty()) {
        videoWarning(QStringLiteral("invalid video URI: %1").arg(m_uri));
        return;
    }

    videoInfo(QStringLiteral("connecting receiver to %1").arg(m_uri));

    GError *error = nullptr;
    m_pipeline = gst_parse_launch(pipelineStr.toUtf8().constData(), &error);
    if (!m_pipeline) {
        videoWarning(QStringLiteral("failed to create pipeline for %1: %2")
                         .arg(m_uri, QString::fromUtf8(error ? error->message : "unknown")));
        if (error) g_error_free(error);
        return;
    }
    if (error) {
        videoWarning(QStringLiteral("pipeline warning for %1: %2")
                         .arg(m_uri, QString::fromUtf8(error->message)));
        g_error_free(error);
    }

    GstElement *sink = gst_bin_get_by_name(GST_BIN(m_pipeline), "sink");
    if (!sink) {
        videoWarning(QStringLiteral("appsink not found for %1").arg(m_uri));
        gst_object_unref(m_pipeline);
        m_pipeline = nullptr;
        return;
    }

    m_appsink = GST_APP_SINK(sink);

    GstAppSinkCallbacks callbacks = {};
    callbacks.new_sample = &BoxVideoReceiver::onNewSample;
    gst_app_sink_set_callbacks(m_appsink, &callbacks, this, nullptr);

    GstStateChangeReturn ret = gst_element_set_state(m_pipeline, GST_STATE_PLAYING);
    if (ret == GST_STATE_CHANGE_FAILURE) {
        videoWarning(QStringLiteral("failed to start pipeline for %1").arg(m_uri));
        GstAppSinkCallbacks nullCallbacks = {};
        gst_app_sink_set_callbacks(m_appsink, &nullCallbacks, nullptr, nullptr);
        gst_object_unref(GST_OBJECT(m_appsink));
        gst_object_unref(m_pipeline);
        m_pipeline = nullptr;
        m_appsink = nullptr;
        return;
    }

    GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE(m_pipeline));
    if (bus) {
        gst_bus_set_sync_handler(bus, &BoxVideoReceiver::onBusSyncMessage, this, nullptr);
        gst_object_unref(bus);
    }

    m_firstFrameLogged = false;
    // Bump generation before setting m_running so any lambda posted against the old
    // generation is already stale when the new pipeline fires its first frame.
    m_generation.fetch_add(1, std::memory_order_relaxed);
    m_running.store(true);
    videoInfo(QStringLiteral("receiver pipeline started for %1").arg(m_uri));
}

GstBusSyncReply BoxVideoReceiver::onBusSyncMessage(GstBus *, GstMessage *msg, gpointer data)
{
    auto *self = static_cast<BoxVideoReceiver *>(data);
    const GstMessageType type = GST_MESSAGE_TYPE(msg);
    if (type != GST_MESSAGE_EOS && type != GST_MESSAGE_ERROR)
        return GST_BUS_PASS;
    if (!self->m_running.load())
        return GST_BUS_PASS;

    QString errorText;
    if (type == GST_MESSAGE_ERROR) {
        GError *error = nullptr;
        gst_message_parse_error(msg, &error, nullptr);
        errorText = QString::fromUtf8(error ? error->message : "unknown error");
        if (error)
            g_error_free(error);
    }

    // This runs on a GStreamer streaming thread. Seeking or tearing down here
    // deadlocks the pipeline (a flushing seek joins the task it runs on), which
    // then wedges the next set_state(NULL) and freezes the GUI thread — hop to
    // the main thread, and drop the hop if the pipeline was replaced meanwhile.
    const int generation = self->m_generation.load(std::memory_order_relaxed);
    QMetaObject::invokeMethod(self, [self, type, errorText, generation]() {
        if (self->m_generation.load(std::memory_order_relaxed) != generation)
            return;
        if (type == GST_MESSAGE_ERROR)
            self->handlePipelineError(errorText);
        else
            self->handleEndOfStream();
    }, Qt::QueuedConnection);
    return GST_BUS_PASS;
}

// An errored pipeline never recovers on its own and would otherwise keep
// m_running true forever, blocking every later restart. Tearing it down is what
// lets the next activation rebuild it.
void BoxVideoReceiver::handlePipelineError(const QString &message)
{
    videoWarning(QStringLiteral("pipeline error on %1: %2 — stopping").arg(m_uri, message));
    stopPipeline();
}

// For a live source EOS means the far end went away, so tear the pipeline down
// while it is still in a sane state.
void BoxVideoReceiver::handleEndOfStream()
{
    if (!m_running.load() || !m_pipeline)
        return;
    videoWarning(QStringLiteral("end of stream on %1 — stopping").arg(m_uri));
    stopPipeline();
}

void BoxVideoReceiver::stopPipeline()
{
    if (!m_running.exchange(false))
        return;

    // Bump generation first so any lambdas already queued on the main thread will
    // see a stale generation and drop themselves before touching m_videoSink.
    m_generation.fetch_add(1, std::memory_order_relaxed);

    if (m_pipeline) {
        // Detach appsink callbacks before transitioning to NULL so GStreamer's
        // streaming threads cannot invoke onNewSample during or after the drain.
        if (m_appsink) {
            GstAppSinkCallbacks nullCallbacks = {};
            gst_app_sink_set_callbacks(m_appsink, &nullCallbacks, nullptr, nullptr);
        }
        GstBus *bus = gst_pipeline_get_bus(GST_PIPELINE(m_pipeline));
        if (bus) {
            gst_bus_set_sync_handler(bus, nullptr, nullptr, nullptr);
            gst_object_unref(bus);
        }
        // GST_STATE_NULL is synchronous — blocks until all streaming threads have drained.
        gst_element_set_state(m_pipeline, GST_STATE_NULL);
        if (m_appsink) {
            gst_object_unref(GST_OBJECT(m_appsink));
            m_appsink = nullptr;
        }
        gst_object_unref(m_pipeline);
        m_pipeline = nullptr;
    }

    m_receiveTimeoutTimer.stop();
    if (m_receiving.exchange(false))
        emit receivingChanged();

    m_firstFrameLogged = false;
    videoInfo(QStringLiteral("receiver pipeline stopped for %1").arg(m_uri));
}

GstFlowReturn BoxVideoReceiver::onNewSample(GstAppSink *sink, gpointer data)
{
    auto *self = static_cast<BoxVideoReceiver *>(data);
    if (!self->m_running.load())
        return GST_FLOW_OK;
    GstSample *sample = gst_app_sink_pull_sample(sink);
    if (sample) {
        self->deliverFrame(sample);
        gst_sample_unref(sample);
    }
    return GST_FLOW_OK;
}

void BoxVideoReceiver::deliverFrame(GstSample *sample)
{
    if (!m_running.load())
        return;

    GstCaps *caps = gst_sample_get_caps(sample);
    if (!caps)
        return;

    GstVideoInfo info;
    if (!gst_video_info_from_caps(&info, caps))
        return;

    int width = GST_VIDEO_INFO_WIDTH(&info);
    int height = GST_VIDEO_INFO_HEIGHT(&info);

    GstBuffer *buffer = gst_sample_get_buffer(sample);
    if (!buffer)
        return;

    GstMapInfo map;
    if (!gst_buffer_map(buffer, &map, GST_MAP_READ))
        return;

    QVideoFrameFormat format(QSize(width, height), QVideoFrameFormat::Format_BGRA8888);
    QVideoFrame frame(format);

    if (frame.map(QVideoFrame::WriteOnly)) {
        int srcStride = GST_VIDEO_INFO_PLANE_STRIDE(&info, 0);
        int dstStride = frame.bytesPerLine(0);
        int copyStride = qMin(srcStride, dstStride);
        const uchar *src = map.data;
        uchar *dst = frame.bits(0);

        for (int y = 0; y < height; ++y) {
            memcpy(dst + y * dstStride, src + y * srcStride, copyStride);
        }
        frame.unmap();
    }

    gst_buffer_unmap(buffer, &map);

    // Snapshot generation at enqueue time. If stopPipeline()/setVideoSink() fires before
    // this lambda is dispatched, the generation will have been bumped and the lambda drops.
    int capturedGen = m_generation.load(std::memory_order_relaxed);

    QMetaObject::invokeMethod(this, [this, frame = std::move(frame), capturedGen]() mutable {
        if (m_generation.load(std::memory_order_relaxed) != capturedGen)
            return;

        QMutexLocker lock(&m_sinkMutex);
        if (m_videoSink)
            m_videoSink->setVideoFrame(frame);
    }, Qt::QueuedConnection);

    bool expected = false;
    if (m_receiving.compare_exchange_strong(expected, true)) {
        if (!m_firstFrameLogged) {
            m_firstFrameLogged = true;
            videoInfo(QStringLiteral("receiving video frames on %1 (%2x%3)")
                          .arg(m_uri)
                          .arg(width)
                          .arg(height));
        }
        QMetaObject::invokeMethod(this, [this, capturedGen]() {
            if (m_generation.load(std::memory_order_relaxed) != capturedGen)
                return;
            if (m_receiving.load())
                emit receivingChanged();
        }, Qt::QueuedConnection);
    }

    // Keep the timeout running from the main thread.
    QMetaObject::invokeMethod(&m_receiveTimeoutTimer, [this, capturedGen]() {
        if (m_generation.load(std::memory_order_relaxed) == capturedGen)
            m_receiveTimeoutTimer.start();
    }, Qt::QueuedConnection);
}
