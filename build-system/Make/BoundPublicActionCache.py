import re
import sys
from pathlib import Path
from stat import S_ISDIR, S_ISREG


MAX_BYTES = 4 * 1024**3


def bound_cache(root: Path, budget: int) -> bool:
    # The workflow has already stopped Bazel. Consider only the two trees it will upload.
    entries = []
    if not S_ISDIR(root.lstat().st_mode):
        raise ValueError("Expected a plain Bazel disk cache directory.")
    for kind in ("ac", "cas"):
        directory = root / kind
        if not directory.exists() and not directory.is_symlink():
            continue
        if not S_ISDIR(directory.lstat().st_mode):
            raise ValueError(f"Expected a plain cache directory for {kind}.")
        for shard in directory.iterdir():
            if not re.fullmatch(r"[0-9a-f]{2}", shard.name) or not S_ISDIR(shard.lstat().st_mode):
                raise ValueError(f"Unexpected entry in the {kind} cache directory.")
            for file in shard.iterdir():
                info = file.lstat()
                if not re.fullmatch(shard.name + r"[0-9a-f]{62}", file.name) or not S_ISREG(info.st_mode):
                    raise ValueError(f"Unexpected entry in the {kind} cache shard.")
                entries.append((info.st_mtime_ns, file, info.st_size, kind))

    total = sum(entry[2] for entry in entries)
    original_total = total
    action_count = sum(entry[3] == "ac" for entry in entries)
    blob_count = len(entries) - action_count
    # Bazel also evicts the oldest files first, with action records before blobs on ties.
    for _, file, size, kind in sorted(entries):
        if total <= budget:
            break
        file.unlink()
        total -= size
        action_count -= kind == "ac"
        blob_count -= kind == "cas"

    print(f"Public Swift cache: {total} bytes ({original_total} before trimming), "
          f"{action_count} action records and {blob_count} blobs.")
    return action_count > 0 and blob_count > 0


if __name__ == "__main__":
    if bound_cache(Path(sys.argv[1]), MAX_BYTES):
        with Path(sys.argv[2]).open("a") as output:
            output.write("save=true\n")
