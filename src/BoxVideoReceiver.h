#pragma once

#include <QMutex>
#include <QObject>
#include <QTimer>
#include <QVideoFrame>
#include <QVideoFrameFormat>
#include <QVideoSink>
#include <QtQml/qqmlregistration.h>

#include <atomic>
#include <gst/app/gstappsink.h>
#include <gst/gst.h>

class BoxVideoReceiver : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVideoSink* videoSink READ videoSink WRITE setVideoSink NOTIFY videoSinkChanged)
    Q_PROPERTY(bool receiving READ receiving NOTIFY receivingChanged)
    Q_PROPERTY(QString uri READ uri WRITE setUri NOTIFY uriChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)

public:
    explicit BoxVideoReceiver(QObject *parent = nullptr);
    ~BoxVideoReceiver() override;

    QVideoSink *videoSink() const;
    void setVideoSink(QVideoSink *sink);

    bool receiving() const;

    QString uri() const;
    void setUri(const QString &uri);

    bool active() const;
    void setActive(bool active);

signals:
    void videoSinkChanged();
    void receivingChanged();
    void uriChanged();
    void activeChanged();

private:
    void startPipeline();
    void stopPipeline();
    void restartIfNeeded();
    void handlePipelineError(const QString &message);
    void handleEndOfStream();

    static GstFlowReturn onNewSample(GstAppSink *sink, gpointer data);
    static GstBusSyncReply onBusSyncMessage(GstBus *bus, GstMessage *msg, gpointer data);
    void deliverFrame(GstSample *sample);

    GstElement *m_pipeline = nullptr;
    GstAppSink *m_appsink = nullptr;

    // Lock ordering: m_sinkMutex is a leaf lock — never acquire any other lock while holding it.
    QVideoSink *m_videoSink = nullptr;
    QMutex m_sinkMutex;

    // Bumped on every startPipeline()/stopPipeline()/setVideoSink() transition.
    // Queued lambdas capture the generation at post time and bail if it no longer matches.
    std::atomic<int> m_generation{0};

    std::atomic<bool> m_receiving{false};
    bool m_firstFrameLogged = false;
    std::atomic<bool> m_running{false};
    bool m_active = false;
    QString m_uri;

    // Reset on every delivered frame; fires receivingChanged(false) after 2 s of silence.
    QTimer m_receiveTimeoutTimer;
};
