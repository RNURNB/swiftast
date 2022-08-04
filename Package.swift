// swift-tools-version:5.0

import PackageDescription

// ================
// === Products ===
// ================

let products: [Product] = [
  // Main executable.

  // Executable for running tests written in Python (from 'PyTest' directory).
  // This is what we will be running 99% of the time.
  
  // Violet as a library.
  //.library(name: "LibViolet", targets: ["VioletVM"]),
  .library(name: "BinAST", targets: ["BinAST"]),
  .library(name: "SwiftAST", targets: ["SwiftAST"])
 
]

// ====================
// === Dependencies ===
// ====================

// We try to avoid adding new dependencies because… oh so many reasons!
// Tbh. I’m still not sure if we can trust this ‘apple’ person…
let dependencies: [Package.Dependency] = [
  .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.0"))
]

// ===============
// === Targets ===
// ===============

// IMPORTANT:
// Module names have 'Violet' prefix, but directories do not
// (for example: 'VioletParser' module is inside 'Sources/Parser' directory)!
let targets: [Target] = [

  // Shared module that all of the other modules depend on.
  .target(name: "SwiftAST", dependencies: [], path: "Sources/SwiftAST"),
 

  // Apparently we have our own implementation of unlimited integers…
  // Ehh…
  .target(name: "BinAST", dependencies: ["SwiftAST"], path: "Sources/BinAST"),
 
]

// ===============
// === Package ===
// ===============

let package = Package(
  name: "swiftast",
  products: products,
  dependencies: dependencies,
  targets: targets
)
