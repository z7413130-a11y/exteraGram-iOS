load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExteraSettingsUI",
    module_name = "ExteraSettingsUI",
    srcs = glob(["Sources/**/*.swift"]),
    deps = [
        "//submodules/AccountContext",
        "//submodules/Display",
        "//submodules/ExteraSettings",
        "//submodules/ItemListUI",
        "//submodules/PresentationDataUtils",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/TelegramPresentationData",
        "//submodules/TranslateUI",
    ],
    visibility = ["//visibility:public"],
)
