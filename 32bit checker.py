import os
import struct
import sys
from pathlib import Path

# ── PE Machine type codes ────────────────────────────────────────────────────
MACHINE_TYPES = {
    0x014C: ("x86 (32-bit)",        True,  "✅ Wine / Box86 compatible"),
    0x8664: ("x86-64 (64-bit)",     False, "❌ 64-bit only (needs Box64 / Wine64)"),
    0x01C0: ("ARM (32-bit)",        True,  "⚠️  ARM 32-bit (Box86 on ARM hosts)"),
    0xAA64: ("ARM64 (64-bit)",      False, "❌ ARM64 only"),
    0x0200: ("IA-64 (Itanium)",     False, "❌ Itanium — not supported"),
    0x01F0: ("PowerPC 32-bit",      False, "❌ PowerPC — not supported"),
    0x0166: ("MIPS R4000",          False, "❌ MIPS — not supported"),
}

OPTIONAL_MAGIC = {
    0x010B: "PE32  (32-bit)",
    0x020B: "PE32+ (64-bit)",
    0x0107: "ROM image",
}


def read_pe_architecture(filepath: str) -> dict:
    """Parse the PE header of an EXE and return architecture info."""
    result = {
        "path": filepath,
        "machine_code": None,
        "machine_label": "Unknown",
        "optional_magic": "Unknown",
        "is_32bit": False,
        "compat_note": "❓ Could not determine",
        "error": None,
    }

    try:
        with open(filepath, "rb") as f:
            # Verify MZ signature
            mz = f.read(2)
            if mz != b"MZ":
                result["error"] = "Not a valid PE file (no MZ header)"
                return result

            # Read PE header offset at 0x3C
            f.seek(0x3C)
            pe_offset = struct.unpack("<I", f.read(4))[0]

            # Verify PE signature
            f.seek(pe_offset)
            pe_sig = f.read(4)
            if pe_sig != b"PE\x00\x00":
                result["error"] = "Not a valid PE file (no PE signature)"
                return result

            # IMAGE_FILE_HEADER: Machine is the first 2 bytes
            machine_code = struct.unpack("<H", f.read(2))[0]
            result["machine_code"] = machine_code

            # Skip rest of file header (18 bytes) to reach Optional Header
            f.read(18)
            opt_magic = struct.unpack("<H", f.read(2))[0]

            label, is_32bit, note = MACHINE_TYPES.get(
                machine_code,
                (f"Unknown (0x{machine_code:04X})", False, "❓ Unrecognised architecture")
            )
            result["machine_label"] = label
            result["is_32bit"] = is_32bit
            result["compat_note"] = note
            result["optional_magic"] = OPTIONAL_MAGIC.get(opt_magic, f"0x{opt_magic:04X}")

    except Exception as e:
        result["error"] = str(e)

    return result


def scan_directory(root_path: str) -> None:
    root = Path(root_path).expanduser().resolve()

    if not root.exists():
        print(f"\n❌  Path does not exist: {root}\n")
        sys.exit(1)

    print(f"\n{'═'*70}")
    print(f"  EXE Architecture Scanner")
    print(f"  Scanning: {root}")
    print(f"{'═'*70}\n")

    exe_files = list(root.rglob("*.exe"))

    if not exe_files:
        print("  No .exe files found.\n")
        return

    compatible   = []
    incompatible = []
    errors       = []

    for exe_path in exe_files:
        info = read_pe_architecture(str(exe_path))
        if info["error"]:
            errors.append(info)
        elif info["is_32bit"]:
            compatible.append(info)
        else:
            incompatible.append(info)

    # ── Print 32-bit compatible ───────────────────────────────────────────
    print(f"{'─'*70}")
    print(f"  ✅  32-BIT COMPATIBLE  ({len(compatible)} files)  — runnable via Wine / Box86")
    print(f"{'─'*70}")
    for info in compatible:
        rel = Path(info["path"]).relative_to(root)
        print(f"  {info['compat_note']}")
        print(f"    File   : {rel}")
        print(f"    Arch   : {info['machine_label']}  |  Header: {info['optional_magic']}")
        print()

    if not compatible:
        print("  (none found)\n")

    # ── Print 64-bit / incompatible ───────────────────────────────────────
    print(f"{'─'*70}")
    print(f"  ❌  NOT 32-BIT COMPATIBLE  ({len(incompatible)} files)")
    print(f"{'─'*70}")
    for info in incompatible:
        rel = Path(info["path"]).relative_to(root)
        print(f"  {info['compat_note']}")
        print(f"    File   : {rel}")
        print(f"    Arch   : {info['machine_label']}  |  Header: {info['optional_magic']}")
        print()

    if not incompatible:
        print("  (none found)\n")

    # ── Errors ────────────────────────────────────────────────────────────
    if errors:
        print(f"{'─'*70}")
        print(f"  ⚠️   ERRORS / UNREADABLE  ({len(errors)} files)")
        print(f"{'─'*70}")
        for info in errors:
            rel = Path(info["path"]).relative_to(root)
            print(f"    File  : {rel}")
            print(f"    Error : {info['error']}")
            print()

    # ── Summary ───────────────────────────────────────────────────────────
    total = len(exe_files)
    print(f"{'═'*70}")
    print(f"  SUMMARY  |  Total: {total}  |  32-bit ✅: {len(compatible)}"
          f"  |  64-bit ❌: {len(incompatible)}  |  Errors ⚠️ : {len(errors)}")
    print(f"{'═'*70}\n")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        path = sys.argv[1]
    else:
        path = input("Enter the directory path to scan: ").strip()

    scan_directory(path)