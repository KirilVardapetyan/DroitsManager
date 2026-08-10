import QtLocation

Plugin {
    id: root
    name: "osm"
    PluginParameter { name: "osm.mapping.custom.host"; value: "https://basemaps.cartocdn.com/dark_all/" }
    PluginParameter { name: "osm.mapping.custom.mapcopyright"; value: "CartoDB" }
    PluginParameter { name: "osm.mapping.custom.datacopyright"; value: "OpenStreetMap" }
    PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: "true" }
    PluginParameter { name: "osm.useragent"; value: "DroidsManager" }
}
