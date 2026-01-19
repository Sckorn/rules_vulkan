load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@rules_7zip//:repo.bzl", "http_7z")

_VULKAN_VERSION = "1.4.335.0"

# https://sdk.lunarg.com/sdk/download/1.4.335.0/windows/vulkansdk-windows-X64-1.4.335.0.exe
# https://sdk.lunarg.com/sdk/download/1.4.335.0/linux/vulkansdk-linux-x86_64-1.4.335.0.tar.xz

_vulkan_sdk_well_knowns = {
    _VULKAN_VERSION: struct(
        windows = struct(
            url = "https://sdk.lunarg.com/sdk/download/{0}/windows/vulkansdk-windows-X64-{0}.exe".format(_VULKAN_VERSION),
            strip_prefix = "",
            sha256 = "acb4ae0786fd3e558f8b3c36cc3eba91638984217ba8a6795ec64d2f9ffd8c4b",
        ),
        linux = struct(
            url = "https://sdk.lunarg.com/sdk/download/{0}/linux/vulkansdk-linux-x86_64-{0}.tar.xz".format(_VULKAN_VERSION),
            strip_prefix = "{}/x86_64".format(_VULKAN_VERSION),
            sha256 = "79b0a1593dadc46180526250836f3e53688a9a5fb42a0e5859eb72316dc4d53e",
        ),
        macos = struct(
            url = "https://vertexwahn.de/lfs/v1/vulkansdk-macos-{}.zip".format(_VULKAN_VERSION),
            strip_prefix = "VulkanSDK/{}/macOS".format(_VULKAN_VERSION),
            sha256 = "393fd11f65a4001f12fd34fdd009c38045220ca3f735bc686d97822152b0f33c",
        ),
    ),
}

def _vulkan_sdk_repo_impl(rctx):
    commonTargets = [
        # Pre-built executables
        "glslangValidator",
        "glslc",
        "spirv-as",
        "spirv-cfg",
        "spriv-cross",
        "spriv-dis",
        "spirv-opt",
        "spirv-remap",
        "spirv-val",

        # C/C++ Libraries
        "vulkan",
    ]

    build_file_content = ""

    for commonTarget in commonTargets:
        commonTargetVarName = commonTarget.replace("-", "_")
        build_file_content += """
_windows_{targetVarName} = "@vulkan_sdk_windows//:{targetName}"
_linux_{targetVarName} = "@vulkan_sdk_linux//:{targetName}"
_macos_{targetVarName} = "@vulkan_sdk_macos//:{targetName}"
alias(
    name = "{targetName}",
    visibility = ["//visibility:public"],
    actual = select({{
        # Windows
        "@bazel_tools//src/conditions:windows": _windows_{targetVarName},
        "@bazel_tools//src/conditions:windows_msvc": _windows_{targetVarName},

        # Linux
        "@bazel_tools//src/conditions:linux_x86_64": _linux_{targetVarName},

        # MacOS
        "@bazel_tools//src/conditions:darwin": _macos_{targetVarName},
        #"@bazel_tools//src/conditions:darwin_x86_64": _macos_{targetVarName},
    }}),
)
""".format(targetName = commonTarget, targetVarName = commonTargetVarName)

    rctx.file("WORKSPACE", content = "workspace(name = \"vulkan_sdk\")\n")
    rctx.file("BUILD.bazel", build_file_content)

_vulkan_sdk_repo = repository_rule(
    implementation = _vulkan_sdk_repo_impl,
    attrs = {
        "version": attr.string(),
    },
)

def vulkan_repos(version = _VULKAN_VERSION):
    ws = "@com_github_zaucy_rules_vulkan//"

    vulkan_sdk_info = _vulkan_sdk_well_knowns[version]

    http_7z(
        name = "vulkan_sdk_windows",
        url = vulkan_sdk_info.windows.url,
        # strip_prefix = vulkan_sdk_info.windows.strip_prefix,
        sha256 = vulkan_sdk_info.windows.sha256,
        build_file = ws + ":vulkan_sdk_windows.BUILD",
    )

    http_archive(
        name = "vulkan_sdk_linux",
        url = vulkan_sdk_info.linux.url,
        strip_prefix = vulkan_sdk_info.linux.strip_prefix,
        sha256 = vulkan_sdk_info.linux.sha256,
        build_file = ws + ":vulkan_sdk_linux.BUILD",
    )

    http_archive(
        name = "vulkan_sdk_macos",
        url = vulkan_sdk_info.macos.url,
        strip_prefix = vulkan_sdk_info.macos.strip_prefix,
        sha256 = vulkan_sdk_info.macos.sha256,
        build_file = ws + ":vulkan_sdk_macos.BUILD",
    )

    _vulkan_sdk_repo(name = "vulkan_sdk", version = version)
