#pragma once

#include <QString>

namespace BoxProtocol {

constexpr int COMMAND_PORT = 5050;
constexpr int VIDEO_PORT = 8554;

inline QString videoUri(const QString &host)
{
    return QStringLiteral("tcp://%1:%2").arg(host).arg(VIDEO_PORT);
}

} // namespace BoxProtocol
