// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeviceMonitor",
    products: [
        .library(
            name: "DeviceMonitor",
            targets: ["DeviceMonitor"]),
    ],
    targets: [
        .target(
            name: "DeviceMonitor")
    ]
)
