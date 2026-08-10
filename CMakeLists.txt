cmake_minimum_required(VERSION 3.16)

project(DroidsManager VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Svg Location Positioning)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appDroidsManager
    main.cpp
)

set_source_files_properties(qml/Theme/Theme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appDroidsManager
    URI DroidsManager
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES
        Main.qml
        qml/Theme/Theme.qml
        qml/Components/NavSidebar.qml
        qml/Components/NavButton.qml
        qml/Components/PageHeader.qml
        qml/Components/OsmMapPlugin.qml
        qml/Screens/LiveMapScreen.qml
        qml/Screens/DroidsScreen.qml
    RESOURCES
        assets/icons/nav_map.svg
        assets/icons/icon_droid.svg
        assets/icons/icon_user.svg
)

set_target_properties(appDroidsManager PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appDroidsManager
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Svg
        Qt6::Location
        Qt6::Positioning
)

include(GNUInstallDirs)
install(TARGETS appDroidsManager
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
