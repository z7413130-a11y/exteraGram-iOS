load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ExteraDraftTranslation",
    module_name = "ExteraDraftTranslation",
    srcs = glob(["Sources/**/*.swift"]),
    deps = [
        "//submodules/AccountContext",
        "//submodules/Display",
        "//submodules/ExteraSettings",
        "//submodules/PresentationDataUtils",
        "//submodules/SSignalKit/SwiftSignalKit",
        "//submodules/TelegramCore",
        "//submodules/TextFormat",
        "//submodules/TranslateUI",
    ],
    visibility = ["//visibility:public"],
)
