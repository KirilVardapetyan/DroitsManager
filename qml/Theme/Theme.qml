pragma Singleton
import QtQuick

QtObject {
    // Primary Colors
    readonly property color primary: "#155dfc"
    readonly property color primaryHover: "#1d4ed8"
    readonly property color primaryPressed: "#1e40af"
    readonly property color accent: "#51a2ff"

    // Status Colors
    readonly property color success: "#22c55e"
    readonly property color error: "#ef4444"
    readonly property color warning: "#f59e0b"
    readonly property color info: "#3b82f6"
    readonly property color errorTint: Qt.rgba(239/255, 68/255, 68/255, 0.2)
    readonly property color successTint: Qt.rgba(34/255, 197/255, 94/255, 0.2)

    // Background Colors
    readonly property color backgroundPrimary: "#16171b"
    readonly property color backgroundSecondary: "#0f172b"
    readonly property color backgroundCard: "#1a1f2e"
    readonly property color backgroundElevated: "#162034"
    readonly property color backgroundOverlay: Qt.rgba(17/255, 24/255, 38/255, 0.8)
    readonly property color backgroundSubtle: Qt.rgba(116/255, 147/255, 200/255, 0.1)

    // Text Colors
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#62748e"
    readonly property color textTertiary: "#8fafc1"
    readonly property color textMuted: "#90a1b9"

    // Border Colors
    readonly property color borderPrimary: "#314158"
    readonly property color borderSubtle: Qt.rgba(39/255, 51/255, 70/255, 0.43)

    // Overlay & Hover
    readonly property color hoverLight: Qt.rgba(1, 1, 1, 0.1)
    readonly property color hoverSubtle: Qt.rgba(1, 1, 1, 0.05)

    // Spacing
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 12
    readonly property int spacingLg: 16
    readonly property int spacingXl: 24
    readonly property int spacingXxl: 32

    // Border Radius
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16

    // Typography
    readonly property string fontFamily: "Roboto"
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeNormal: 14
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeXLarge: 18
    readonly property int fontSizeTitle: 30

    // Z-order layers
    readonly property int zModal: 1000
    readonly property int zOverlay: 500

    // Component Sizes
    readonly property int navIconSize: 48
    readonly property int navWidth: 80
    readonly property int headerHeight: 60
}
