"""Verify Siri authorization guards and remove usage strings for sideloads."""

import argparse
from pathlib import Path
import plistlib
import re
import subprocess


KEY = "NSSiriUsageDescription"
ASSIGNMENT = re.compile(
    r'(?m)^[ \t]*"?NSSiriUsageDescription"?[ \t]*=[ \t]*"(?:[^"\\]|\\.)*"[ \t]*;[ \t]*(?:\r?\n|\Z)'
)


def read_plist(data):
    try:
        return plistlib.loads(data)
    except plistlib.InvalidFileException:
        xml = subprocess.run(
            ["/usr/bin/plutil", "-convert", "xml1", "-o", "-", "-"],
            input=data, check=True, capture_output=True,
        )
        return plistlib.loads(xml.stdout)


def without_usage_string(data):
    original = read_plist(data)
    if KEY not in original:
        return data
    expected = dict(original)
    del expected[KEY]
    if data.startswith(b"bplist"):
        result = plistlib.dumps(expected, fmt=plistlib.FMT_BINARY, sort_keys=False)
    elif data.lstrip().startswith(b"<?xml"):
        result = plistlib.dumps(expected, sort_keys=False)
    else:
        encoding = "utf-8"
        if data.startswith((b"\xff\xfe", b"\xfe\xff")):
            encoding = "utf-16"
        elif data.startswith(b"\xef\xbb\xbf"):
            encoding = "utf-8-sig"
        text, count = ASSIGNMENT.subn("", data.decode(encoding))
        if count != 1:
            raise ValueError("Expected one Siri usage assignment")
        result = text.encode(encoding)
    if read_plist(result) != expected:
        raise ValueError("Removing the Siri usage string changed another value")
    return result


def check_source():
    root = Path(__file__).resolve().parents[2]
    delegate = (root / "submodules/TelegramUI/Sources/AppDelegate.swift").read_text()
    capability = delegate.split("var canUseSiri: Bool {", 1)[1].split("var canUseICloud", 1)[0]
    if 'guard configuration.isSiriEnabled,' not in capability or (
        f'bundle.infoDictionary?["{KEY}"] as? String else' not in capability
    ):
        raise ValueError("The Siri guard must require the configuration and the main Info.plist")

    request = delegate.split("}, requestSiriAuthorization: {", 1)[1].split("}, siriAuthorization: {", 1)[0]
    status = delegate.split("}, siriAuthorization: {", 1)[1].split("}, getWindowHost:", 1)[0]
    for closure, fallback, call in (
        (request, r"completion\(false\)\s+return", "safeRequestSiriAuthorization"),
        (status, r"return \.denied", "safeSiriAuthorizationStatus"),
    ):
        guard = r"^\s*\w*\s*(?:in\s+)?guard capabilities\.canUseSiri else\s*\{[^}]*" + fallback + r"\s*\}"
        if closure.count(call) != 1 or not re.search(guard, closure.split(call, 1)[0]):
            raise ValueError("Siri calls must follow the capability guard and its early return")
    if "INPreferences." in delegate:
        raise ValueError("AppDelegate must use guarded Siri entry points")

    build = (root / "Telegram/BUILD").read_text()
    workflow = (root / ".github/workflows/build-ios-ipa.yml").read_text()
    if build.count(f"<key>{KEY}</key>") != 1 or (
        'siri_usage_fragment = "" if not telegram_enable_siri else' not in build
        or "{siri_usage_fragment}" not in build
    ):
        raise ValueError("The Siri usage string must follow the Bazel signing configuration")
    if re.findall(r"\benable_siri\s*=\s*(True|False)", workflow) != ["False"]:
        raise ValueError("Deferred signing must default to Siri authorization disabled")
    print("Verified the Siri source and deferred-signing configuration")


def prepare_localizations(root):
    paths = sorted(root.glob("*.lproj/InfoPlist.strings"))
    if not paths:
        raise ValueError("No localized Info.plist strings were found")
    changed = 0
    for path in paths:
        original = path.read_bytes()
        revised = without_usage_string(original)
        if revised != original:
            path.write_bytes(revised)
            changed += 1
    print(f"Removed Siri usage strings from {changed} localizations")


def audit_app(app):
    paths = [app / "Info.plist", *sorted(app.glob("*.lproj/InfoPlist.strings"))]
    for path in paths:
        if KEY in read_plist(path.read_bytes()):
            raise ValueError(f"Unexpected Siri usage string in {path.relative_to(app)}")
    print(f"Verified Siri usage string is absent from all {len(paths)} app metadata files")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("check-source")
    commands.add_parser("prepare-localizations").add_argument("root", type=Path)
    commands.add_parser("audit-app").add_argument("app", type=Path)
    args = parser.parse_args()
    if args.command == "check-source":
        check_source()
    elif args.command == "prepare-localizations":
        prepare_localizations(args.root)
    else:
        audit_app(args.app)


if __name__ == "__main__":
    main()
