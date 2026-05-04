#!/usr/bin/env python3
"""Decode Google Authenticator migration QRs into individual otpauth:// URIs.

Usage:
    nix shell nixpkgs#zbar -c python3 scripts/otp-migration/decode.py qr1.png [qr2.png ...]

Each line of output is an otpauth://totp/... URI suitable for re-rendering as
a single-account QR (e.g. with `qrencode -o out.png 'otpauth://...'`) which
Authenticator can then ingest via "Scan from image".

When done, scrub anything that touched plaintext secrets:
    shred -u /tmp/otp-*.png /tmp/otp-uris.txt
"""

import base64
import subprocess
import sys
import urllib.parse


def read_varint(buf, pos):
    result, shift = 0, 0
    while True:
        b = buf[pos]
        pos += 1
        result |= (b & 0x7F) << shift
        if not (b & 0x80):
            return result, pos
        shift += 7


def read_field(buf, pos):
    tag, pos = read_varint(buf, pos)
    field, wire = tag >> 3, tag & 0x7
    if wire == 0:
        val, pos = read_varint(buf, pos)
        return field, val, pos
    if wire == 2:
        length, pos = read_varint(buf, pos)
        return field, buf[pos:pos + length], pos + length
    raise ValueError(f"unsupported wire type {wire}")


def decode_otp(buf):
    otp = {"secret": b"", "name": "", "issuer": "", "algo": 1, "digits": 1, "type": 2, "counter": 0}
    pos = 0
    keys = {1: "secret", 2: "name", 3: "issuer", 4: "algo", 5: "digits", 6: "type", 7: "counter"}
    while pos < len(buf):
        f, v, pos = read_field(buf, pos)
        if f in keys:
            otp[keys[f]] = v.decode("utf-8") if isinstance(v, bytes) and f in (2, 3) else v
    return otp


def to_uri(otp):
    algo_map = {1: "SHA1", 2: "SHA256", 3: "SHA512", 4: "MD5"}
    digit_map = {1: 6, 2: 8}
    type_map = {1: "hotp", 2: "totp"}

    secret_b32 = base64.b32encode(otp["secret"]).rstrip(b"=").decode()
    label = f"{otp['issuer']}:{otp['name']}" if otp["issuer"] else otp["name"]
    params = {
        "secret": secret_b32,
        "algorithm": algo_map.get(otp["algo"], "SHA1"),
        "digits": str(digit_map.get(otp["digits"], 6)),
    }
    if otp["issuer"]:
        params["issuer"] = otp["issuer"]
    typ = type_map.get(otp["type"], "totp")
    if typ == "hotp":
        params["counter"] = str(otp["counter"])
    return f"otpauth://{typ}/{urllib.parse.quote(label)}?{urllib.parse.urlencode(params)}"


def decode_migration_payload(payload_b64):
    pad = "=" * (-len(payload_b64) % 4)
    buf = base64.b64decode(payload_b64 + pad)
    pos, otps = 0, []
    while pos < len(buf):
        f, v, pos = read_field(buf, pos)
        if f == 1:
            otps.append(decode_otp(v))
    return otps


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    for img in sys.argv[1:]:
        try:
            raw = subprocess.check_output(["zbarimg", "-q", "--raw", img]).decode()
        except subprocess.CalledProcessError as e:
            print(f"# {img}: no QR detected ({e})", file=sys.stderr)
            continue

        for line in raw.splitlines():
            if not line.startswith("otpauth-migration://"):
                if line.startswith("otpauth://"):
                    print(line)
                continue
            qs = urllib.parse.urlparse(line).query
            data = urllib.parse.parse_qs(qs).get("data", [""])[0]
            for otp in decode_migration_payload(data):
                print(to_uri(otp))


if __name__ == "__main__":
    main()
