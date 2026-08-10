pragma Singleton
import QtQuick

QtObject {
    // Primary Colors
    readonly property color primary: "#f97316"
    readonly property color primaryHover: "#ea580c"
    readonly property color primaryPressed: "#c2410c"
    readonly property color accent: "#fb923c"

    // Status Colors
    readonly property color success: "#22c55e"
    readonly property color successSubtle: Qt.rgba(34/255, 197/255, 94/255, 0.12)
    readonly property color successTint: Qt.rgba(34/255, 197/255, 94/255, 0.2)
    readonly property color error: "#ef4444"
    readonly property color errorSubtle: Qt.rgba(239/255, 68/255, 68/255, 0.12)
    readonly property color errorTint: Qt.rgba(239/255, 68/255, 68/255, 0.2)
    readonly property color warning: "#f59e0b"
    readonly property color info: "#3b82f6"

    // Background Colors
    readonly property color backgroundPrimary: "#18181b"
    readonly property color backgroundSecondary: "#27272a"
    readonly property color backgroundCard: "#1e1e21"
    readonly property color backgroundElevated: "#26262b"
    readonly property color backgroundModal: "#1c1c20"
    readonly property color backgroundRaised: "#202024"
    readonly property color backgroundOverlay: Qt.rgba(24/255, 24/255, 27/255, 0.8)
    readonly property color backgroundSubtle: Qt.rgba(160/255, 160/255, 170/255, 0.1)

    // Text Colors
    readonly property color textPrimary: "#ffffff"
    readonly property color textSecondary: "#71717a"
    readonly property color textTertiary: "#a1a1aa"
    readonly property color textMuted: "#9a9aa3"

    // Border Colors
    readonly property color borderPrimary: "#3f3f46"
    readonly property color borderFocus: "#fb923c"
    readonly property color borderSubtle: Qt.rgba(63/255, 63/255, 70/255, 0.43)
    readonly property color borderRow: Qt.rgba(63/255, 63/255, 70/255, 0.4)
    readonly property color borderStrong: Qt.rgba(63/255, 63/255, 70/255, 0.6)

    // Overlay & Hover
    readonly property color overlay: Qt.rgba(0, 0, 0, 0.5)
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
    readonly property int inputHeight: 40
    readonly property int buttonHeight: 40
    readonly property int navIconSize: 48
    readonly property int navWidth: 80
    readonly property int headerHeight: 60
}
