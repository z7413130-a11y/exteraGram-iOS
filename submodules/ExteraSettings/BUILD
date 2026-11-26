load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExteraSettings",
    module_name = "ExteraSettings",
    srcs = glob(["Sources/**/*.swift"]),
    deps = ["//submodules/SSignalKit/SwiftSignalKit"],
    visibility = ["//visibility:public"],
)
