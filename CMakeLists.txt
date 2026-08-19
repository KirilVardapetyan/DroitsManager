cmake_minimum_required(VERSION 3.16)

project(DroitsManager VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Svg Location Positioning Network Multimedia Sql)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GST REQUIRED
    gstreamer-1.0
    gstreamer-app-1.0
    gstreamer-video-1.0
)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appDroitsManager
    main.cpp
)

set_source_files_properties(qml/Theme/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appDroitsManager
    URI DroitsManager
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        Main.qml
        qml/Theme/Theme.qml
        qml/Components/NavSidebar.qml
        qml/Components/NavButton.qml
        qml/Components/PageHeader.qml
        qml/Components/OsmMapPlugin.qml
        qml/Components/ModalShell.qml
        qml/Components/DeliveryBoxMarker.qml
        qml/Components/DroneMarker.qml
        qml/Components/DeliveryBoxDrawer.qml
        qml/Components/DroidStatusBadge.qml
        qml/Components/DroidsTable.qml
        qml/Components/ConnectDroidModal.qml
        qml/Components/BoxVideoModal.qml
        qml/Components/DroneShellModal.qml
        qml/Components/FlightPrepFlow.qml
        qml/Components/OrderStatusBadge.qml
        qml/Components/OrdersTable.qml
        qml/Controls/CloseButton.qml
        qml/Controls/PrimaryActionButton.qml
        qml/Controls/SecondaryActionButton.qml
        qml/Controls/AppTextField.qml
        qml/Screens/LiveMapScreen.qml
        qml/Screens/DroidsScreen.qml
        qml/Screens/OrdersScreen.qml
        qml/Screens/DronesScreen.qml
    SOURCES
        src/BoxProtocol.h
        src/BoxClient.h
        src/BoxClient.cpp
        src/BoxStore.h
        src/BoxStore.cpp
        src/DroneProtocol.h
        src/DroneStore.h
        src/DroneStore.cpp
        src/DroneShell.h
        src/DroneShell.cpp
        src/VideoPipeline.h
        src/BoxVideoReceiver.h
        src/BoxVideoReceiver.cpp
    RESOURCES
        assets/icons/nav_map.svg
        assets/icons/nav_orders.svg
        assets/icons/nav_drone.svg
        assets/icons/icon_user.svg
        assets/icons/icon_box.svg
)

set_target_properties(appDroitsManager PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_include_directories(appDroitsManager
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${GST_INCLUDE_DIRS}
)

target_link_libraries(appDroitsManager
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Svg
        Qt6::Location
        Qt6::Positioning
        Qt6::Network
        Qt6::Multimedia
        Qt6::Sql
        ${GST_LIBRARIES}
)

target_link_directories(appDroitsManager PRIVATE ${GST_LIBRARY_DIRS})

include(GNUInstallDirs)
install(TARGETS appDroitsManager
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
