#pragma once

#include <QString>

namespace DroneProtocol {

constexpr int COMMAND_PORT = 5555;
constexpr int VIDEO_PORT = 5060;

inline QString videoUri(const QString &host)
{
    return QStringLiteral("tcp://%1:%2").arg(host).arg(VIDEO_PORT);
}

} // namespace DroneProtocol
