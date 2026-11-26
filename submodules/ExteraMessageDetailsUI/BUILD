load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExteraMessageDetailsUI",
    module_name = "ExteraMessageDetailsUI",
    srcs = glob(["Sources/**/*.swift"]),
    deps = [
        "//submodules/AccountContext",
        "//submodules/Display",
        "//submodules/ExteraSettings",
        "//submodules/PresentationDataUtils",
        "//submodules/TelegramCore",
    ],
    visibility = ["//visibility:public"],
)
