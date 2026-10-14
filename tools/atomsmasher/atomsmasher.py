#!/usr/bin/env python3
"""atomsmasher: shrink an XCOM 2 War of the Chosen tactical save so it can load again.

    python atomsmasher.py <save file>

Collapses the mission's history the way the game's own archive does, and writes
`<save file>_archived`, shown as "(archived)" in the Load Game list. Prints a report of the
save before and after.
"""
import bisect
import re
import struct
import time
import zlib
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterator

# ==== lzo.py ============================================================
class LzoError(Exception):
    pass


def lzo1x_decompress(src: bytes, expected: int | None = None) -> bytes:
    """LZO1X decompression (reference algorithm, with the end-of-stream marker)."""
    out = bytearray()
    ip = 0
    n = len(src)

    def need(k):
        if ip + k > n:
            raise LzoError(f"LZO input ends mid-instruction at {ip} of {n}")

    def copy_back(dist, length):
        if dist > len(out) or dist <= 0:
            raise LzoError(f"LZO match distance {dist} reaches before the start (have {len(out)})")
        start = len(out) - dist
        if dist >= length:
            out.extend(out[start:start + length])
        else:  # overlapping copy repeats the pattern
            for i in range(length):
                out.append(out[start + i])

    state = "loop"
    t = 0
    if n and src[0] > 17:
        t = src[0] - 17
        ip = 1
        if t < 4:
            state = "match_next"  # match_next copies the t literals itself
        else:
            need(t)
            out.extend(src[ip:ip + t])
            ip += t
            state = "first_literal_run"
    while True:
        if state == "loop":
            need(1)
            t = src[ip]
            ip += 1
            if t >= 16:
                state = "match"
                continue
            if t == 0:
                need(1)
                while src[ip] == 0:
                    t += 255
                    ip += 1
                    need(1)
                t += 15 + src[ip]
                ip += 1
            need(t + 3)
            out.extend(src[ip:ip + t + 3])
            ip += t + 3
            state = "first_literal_run"
        if state == "first_literal_run":
            need(2)
            t = src[ip]
            ip += 1
            if t >= 16:
                state = "match"
            else:
                dist = 1 + 0x0800 + (t >> 2) + (src[ip] << 2)
                ip += 1
                copy_back(dist, 3)
                state = "match_done"
        if state == "match":
            if t >= 64:
                need(1)
                dist = 1 + ((t >> 2) & 7) + (src[ip] << 3)
                ip += 1
                copy_back(dist, (t >> 5) - 1 + 2)
            elif t >= 32:
                t &= 31
                if t == 0:
                    need(1)
                    while src[ip] == 0:
                        t += 255
                        ip += 1
                        need(1)
                    t += 31 + src[ip]
                    ip += 1
                need(2)
                v = src[ip] | (src[ip + 1] << 8)
                ip += 2
                copy_back(1 + (v >> 2), t + 2)
            elif t >= 16:
                far = (t & 8) << 11
                t &= 7
                if t == 0:
                    need(1)
                    while src[ip] == 0:
                        t += 255
                        ip += 1
                        need(1)
                    t += 7 + src[ip]
                    ip += 1
                need(2)
                v = src[ip] | (src[ip + 1] << 8)
                ip += 2
                dist = far + (v >> 2)
                if dist == 0:
                    break  # end-of-stream marker
                copy_back(dist + 0x4000, t + 2)
            else:
                need(1)
                dist = 1 + (t >> 2) + (src[ip] << 2)
                ip += 1
                copy_back(dist, 2)
            state = "match_done"
        if state == "match_done":
            t = src[ip - 2] & 3
            if t == 0:
                state = "loop"
                continue
            state = "match_next"
        if state == "match_next":
            need(t + 1)
            out.extend(src[ip:ip + t])
            ip += t
            t = src[ip]
            ip += 1
            state = "match"
    if expected is not None and len(out) != expected:
        raise LzoError(f"LZO produced {len(out)} bytes, header said {expected}")
    return bytes(out)


# ---- compression -----------------------------------------------------------------------
#
# A small LZO1X compressor, so a rewritten save carries blocks smaller than their data, as
# the game's own writer produces. It emits only literal runs and the M2 and M3 match forms
# (distance up to 16,384), never the rarer M1 and M4 forms, and every instruction after a
# literal run is a match, which is the shape the decoder above (and the reference decoder)
# reads without any special case. Each block is compressed on its own, as the container
# requires.

_MIN_MATCH = 4
_MAX_DIST = 16384  # M3 reaches 16,384 back; M2 only 2,048


def _extension(n: int) -> bytes:
    """Length extension: a run of zero bytes (255 each) and one non-zero byte, for n >= 1."""
    k = (n - 1) // 255
    return b"\x00" * k + bytes([n - 255 * k])


def _literal_run(count: int) -> bytes:
    """The instruction that introduces `count` (>= 4) literals mid-stream."""
    if count <= 18:
        return bytes([count - 3])
    return b"\x00" + _extension(count - 18)


def lzo1x_compress(block: bytes) -> bytes:
    n = len(block)
    out = bytearray()
    table: dict[bytes, int] = {}
    ip = 0
    lit_start = 0  # start of the pending literals
    last_match_state_at = -1  # offset in `out` of the byte whose low two bits carry the literal count
    first = True

    def flush_literals(end: int) -> None:
        """Write the pending literals block[lit_start:end] in the form the position calls for."""
        count = end - lit_start
        if count == 0:
            return
        data = block[lit_start:end]
        if first:
            if count <= 238:
                out.append(17 + count)
            else:
                out.extend(b"\x00" + _extension(count - 18))
            out.extend(data)
        elif count <= 3:
            out[last_match_state_at] |= count
            out.extend(data)
        else:
            out.extend(_literal_run(count))
            out.extend(data)

    while ip + _MIN_MATCH <= n:
        key = block[ip:ip + _MIN_MATCH]
        cand = table.get(key)
        table[key] = ip
        if cand is not None and ip - cand <= _MAX_DIST:
            length = _MIN_MATCH
            limit = n - ip
            while length + 64 <= limit and block[ip + length:ip + length + 64] == block[cand + length:cand + length + 64]:
                length += 64
            while length < limit and block[ip + length] == block[cand + length]:
                length += 1
            dist = ip - cand
            flush_literals(ip)
            first = False
            d = dist - 1
            if length <= 8 and dist <= 2048:
                out.append(((length - 1) << 5) | ((d & 7) << 2))
                last_match_state_at = len(out) - 1
                out.append(d >> 3)
            else:
                if length - 2 <= 31:
                    out.append(0x20 | (length - 2))
                else:
                    out.append(0x20)
                    out.extend(_extension(length - 2 - 31))
                out.append((d << 2) & 0xFF)
                last_match_state_at = len(out) - 1
                out.append((d << 2) >> 8)
            ip += length
            lit_start = ip
            if ip + _MIN_MATCH <= n:
                table[block[ip - 1:ip - 1 + _MIN_MATCH]] = ip - 1
        else:
            ip += 1
    flush_literals(n)
    out.extend(b"\x11\x00\x00")
    return bytes(out)

# ==== unreal.py ============================================================
class ParseError(Exception):
    pass


def read_fstring(buf: bytes, pos: int, end: int | None = None) -> tuple[str, int]:
    """FString: i32 length including the NUL (negative means UTF-16 code units), then bytes.

    `end` bounds the string (the end of the enclosing object); it defaults to the buffer end.
    """
    limit = len(buf) if end is None else end
    (n,) = struct.unpack_from("<i", buf, pos)
    pos += 4
    if n == 0:
        return "", pos
    size = -2 * n if n < 0 else n
    if pos + size > limit:
        raise ParseError(f"FString of {size} bytes at {pos - 4} runs past its end ({limit})")
    if n < 0:
        return buf[pos:pos + size].decode("utf-16-le").rstrip("\0"), pos + size
    return buf[pos:pos + size].decode("latin-1").rstrip("\0"), pos + size


def read_name(buf: bytes, pos: int, end: int | None = None) -> tuple[str, int]:
    """FName: an FString plus the i32 instance number."""
    name, pos = read_fstring(buf, pos, end)
    return name, pos + 4


def write_fstring(text: str) -> bytes:
    if not text:
        return struct.pack("<i", 0)
    raw = text.encode("latin-1") + b"\0"
    return struct.pack("<i", len(raw)) + raw


@dataclass
class Property:
    name: str
    type: str
    size: int
    array_index: int
    extra: str | None  # struct name or enum name
    value_pos: int  # offset of the value in the buffer
    value: Any  # decoded for the scalar types, else None
    tag_pos: int  # offset of the property's name, where its tag starts


def read_properties(buf: bytes, pos: int, end: int) -> tuple[list[Property], int]:
    """Read tagged properties up to and including `None`. Returns (properties, position after)."""
    props = []
    while pos < end:
        tag_pos = pos
        name, pos = read_name(buf, pos, end)
        if name == "None":
            return props, pos
        ptype, pos = read_name(buf, pos, end)
        size, array_index = struct.unpack_from("<ii", buf, pos)
        pos += 8
        extra = None
        if ptype in ("StructProperty", "ByteProperty"):
            extra, pos = read_name(buf, pos, end)
        value_pos = pos
        value: Any = None
        if ptype == "BoolProperty":
            value = bool(buf[pos])
            pos += 1
            props.append(Property(name, ptype, 0, array_index, extra, value_pos, value, tag_pos))
            continue
        raw = buf[pos:pos + size]
        if ptype == "IntProperty":
            value = struct.unpack("<i", raw)[0]
        elif ptype == "FloatProperty":
            value = struct.unpack("<f", raw)[0]
        elif ptype in ("NameProperty", "StrProperty"):
            value = read_fstring(raw, 0)[0]
        elif ptype == "ByteProperty" and size > 1:
            value = read_fstring(raw, 0)[0]  # an enum value, stored by name
        elif ptype == "ByteProperty":
            value = raw[0]
        pos += size
        props.append(Property(name, ptype, size, array_index, extra, value_pos, value, tag_pos))
    raise ParseError(f"property list ran past its object end ({end}) without None")


@dataclass
class UnitValue:
    key: str
    value: float
    cleanup: int


def read_unit_values(buf: bytes, pos: int) -> tuple[list[UnitValue], int]:
    """XComGameState_Unit's native trailer: i32 count, then (FName, f32, u8) each."""
    (count,) = struct.unpack_from("<I", buf, pos)
    pos += 4
    values = []
    for _ in range(count):
        key, pos = read_name(buf, pos)
        value, cleanup = struct.unpack_from("<fB", buf, pos)
        pos += 5
        values.append(UnitValue(key, value, cleanup))
    return values, pos

# ==== container.py ============================================================
TAG = 0x9E2A83C1


class ContainerError(Exception):
    pass


@dataclass
class Chunk:
    offset: int
    compressed: int
    uncompressed: int
    blocks: list[tuple[int, int]]
    data_offset: int


def chunks(buf: bytes, start: int) -> Iterator[Chunk]:
    pos = start
    while pos < len(buf):
        if pos + 16 > len(buf):
            raise ContainerError(f"truncated chunk header at {pos}")
        tag, block_size, comp, uncomp = struct.unpack_from("<IIII", buf, pos)
        if tag != TAG:
            raise ContainerError(f"expected a chunk tag at {pos}, found 0x{tag:08X}")
        count = (uncomp + block_size - 1) // block_size
        pairs = struct.unpack_from(f"<{2 * count}I", buf, pos + 16)
        data = pos + 16 + 8 * count
        yield Chunk(pos, comp, uncomp, list(zip(pairs[0::2], pairs[1::2])), data)
        pos = data + comp


def decompress_chunk(buf: bytes, chunk: Chunk) -> bytes:
    out = bytearray()
    pos = chunk.data_offset
    for comp, uncomp in chunk.blocks:
        out += lzo1x_decompress(buf[pos:pos + comp], uncomp)
        pos += comp
    return bytes(out)


def read_body(buf: bytes, start: int) -> bytes:
    """Every chunk from `start`, decompressed and joined."""
    return b"".join(decompress_chunk(buf, c) for c in chunks(buf, start))

# ==== header.py ============================================================
# header version -> bytes after the mission type; None: no mission block at all
TAILS: dict[int, int | None] = {20: None, 21: 12, 22: 16}


class HeaderError(Exception):
    pass


@dataclass
class SaveHeader:
    version: int
    history_position: int
    checksum: int
    campaign_number: int
    save_slot: int
    description: str
    created: str
    map_command: str
    tactical: int
    ironman: int
    autosave: int
    unread: int
    language: str
    checksum2: int
    checksum2_offset: int
    campaign_start: str
    map_image: str
    name: str
    dlc_names: list[str] = field(default_factory=list)
    dlc_friendly_names: list[str] = field(default_factory=list)
    mission_number: int = 0
    campaign_month: int = 0
    tactical_turn: int = 0
    tactical_action: int = 0
    mission_type: str = ""


def _read_strings(buf: bytes, pos: int) -> tuple[list[str], int]:
    (count,) = struct.unpack_from("<I", buf, pos)
    pos += 4
    strings = []
    for _ in range(count):
        text, pos = read_fstring(buf, pos)
        strings.append(text)
    return strings, pos


def parse_header(buf: bytes) -> SaveHeader:
    version, history_position, checksum, _zero, campaign, slot = struct.unpack_from("<IIIIii", buf, 0)
    if version not in TAILS:
        raise HeaderError(f"header version {version}: only {sorted(TAILS)} are known")
    if not 0 < history_position <= len(buf):
        raise HeaderError(f"history position {history_position} is outside the file ({len(buf)} bytes)")
    try:
        description, pos = read_fstring(buf, 24)
        created, pos = read_fstring(buf, pos)
        map_command, pos = read_fstring(buf, pos)
        tactical, ironman, autosave, unread = struct.unpack_from("<IIII", buf, pos)
        language, pos = read_fstring(buf, pos + 16)
        checksum2_offset = pos
        (checksum2,) = struct.unpack_from("<I", buf, pos)
        campaign_start, pos = read_fstring(buf, pos + 16)
        map_image, pos = read_fstring(buf, pos)
        name, pos = read_fstring(buf, pos)
        names, pos = _read_strings(buf, pos)
        friendly, pos = _read_strings(buf, pos)
        mission_number = month = turn = action = 0
        mission_type = ""
        if TAILS[version] is not None:
            mission_number, month, turn, action = struct.unpack_from("<iiii", buf, pos)
            mission_type, pos = read_fstring(buf, pos + 16)
            pos += TAILS[version]
    except (ParseError, struct.error, UnicodeDecodeError) as e:
        raise HeaderError(f"header does not parse: {e}") from e
    if pos != history_position:
        raise HeaderError(f"header parse ended at {pos}, history starts at {history_position}")
    return SaveHeader(version, history_position, checksum, campaign, slot, description, created,
                      map_command, tactical, ironman, autosave, unread, language, checksum2, checksum2_offset,
                      campaign_start, map_image, name, names, friendly, mission_number, month,
                      turn, action, mission_type)


def _fstring(text: str, like: bytes) -> bytes:
    """`text` as an FString in the encoding of the FString `like` starts with (UTF-16 if its length is negative)."""
    if not text:
        return struct.pack("<i", 0)
    if struct.unpack_from("<i", like, 0)[0] < 0:
        raw = text.encode("utf-16-le") + b"\0\0"
        return struct.pack("<i", -(len(raw) // 2)) + raw
    raw = text.encode("latin-1") + b"\0"
    return struct.pack("<i", len(raw)) + raw


def relabel(header: bytes, suffix: str) -> bytes:
    """The header with `suffix` added to the save name the Load Game list shows.

    The list shows the description, whose lines are the date, the time, the save name, then the
    mission; the header's `name` field holds the save name again. A crash folder's recovery save
    has a one-line description ("Error Report Save") and an empty name, so the suffix goes on
    that line. The history position moves by the change in length; the checksums are not
    updated here (`smash.seal` writes them).
    """
    parse_header(header)  # refuses a header this module does not understand
    spans = []  # (start, end, new bytes)
    description, after = read_fstring(header, 24)
    lines = description.split("\n")
    lines[2 if len(lines) >= 3 else 0] += suffix
    spans.append((24, after, _fstring("\n".join(lines), header[24:])))
    _, pos = read_fstring(header, after)  # creation time
    _, pos = read_fstring(header, pos)  # map command
    _, pos = read_fstring(header, pos + 16)  # four u32 flags, then the language
    _, pos = read_fstring(header, pos + 16)  # checksum, 0, 0x34D, 0x78, then the campaign start time
    _, pos = read_fstring(header, pos)  # map image
    name, end = read_fstring(header, pos)
    if name:
        spans.append((pos, end, _fstring(name + suffix, header[pos:])))
    out = bytearray(header)
    for start, stop, new in sorted(spans, reverse=True):
        out[start:stop] = new
    struct.pack_into("<I", out, 4, len(out))
    parse_header(bytes(out))
    return bytes(out)

# ==== history.py ============================================================
HISTORY_CLASS = "XComGameStateHistory"
FRAME_CLASS = "XComGameState"  # a frame's own record in the object table
RULE_CONTEXT = "XComGameStateContext_TacticalGameRule"
CONTEXT_PREFIX = "XComGameStateContext_"
# Frame lists, arrays of table indexes: SDK XComGameState.uc:123, XComGameStateHistory.uc:16.
# `XComGameState_KismetVariable.GameStates` shares the name but holds StateObjectReference structs.
LISTS = {("XComGameState", "GameStates"), ("XComGameStateHistory", "History")}


class HistoryError(Exception):
    pass


@dataclass
class Entry:
    index: int  # position in the list that omits the history record
    cls: str
    frame: int  # index of the entry that caused this one to be serialized: its XComGameState, 0 for a frame
    size: int  # the class's in-memory object size, not the serialized length
    previous: int  # list position of the previous version, -1 for none
    offset: int  # start of the object's data after its i32 -1
    length: int  # length of the data after that i32
    unknown: int = 0  # the i32 after the frame field (meaning unknown), kept so a rewrite can reproduce it
    previous_raw: int = -1  # the previous-version field as stored, kept for the same reason


@dataclass
class Context:
    index: int
    frame: int
    cls: str  # without the XComGameStateContext_ prefix
    rule: str  # eGameRule_* without the prefix, empty for other contexts
    player: int | None
    unit: int | None
    source: int | None  # SourceObject of an ability's input context
    ability: str | None  # AbilityTemplateName of an ability's input context


@dataclass
class Unit:
    root: int
    template: str | None
    player: int | None
    object_id: int | None
    states: list[int]  # entry indexes, oldest version first


class History:
    def __init__(self, body: bytes):
        self.body = body
        try:
            (_, _, count) = struct.unpack_from("<III", body, 0)
            name, pos = read_fstring(body, 12)
        except (struct.error, ParseError) as e:
            raise HistoryError(f"body does not start with a history table: {e}") from e
        if name != HISTORY_CLASS:
            raise HistoryError(f"body starts with {name!r}, expected {HISTORY_CLASS}")
        self.declared_count = count
        self.history_fields = body[pos:pos + 16]  # the history record's own four fields, kept verbatim
        pos += 16  # the history record carries the same four fields as any record
        raw = []
        for _ in range(count - 1):
            cls, pos = read_fstring(body, pos)
            frame, unknown, size, previous = struct.unpack_from("<IiIi", body, pos)
            if not cls.isidentifier():
                raise HistoryError(f"record {len(raw)} has class name {cls!r}: the table is out of step")
            raw.append((cls, frame, size, previous, unknown))
            pos += 16
        (history_length,) = struct.unpack_from("<I", body, pos)
        self.history_object = (pos + 8, history_length - 4)  # data after the length and the -1
        pos += 4 + history_length
        self.entries: list[Entry] = []
        for i, (cls, frame, size, previous, unknown) in enumerate(raw):
            (length,) = struct.unpack_from("<I", body, pos)
            self.entries.append(Entry(i, cls, frame, size, previous - 1 if previous > 0 else -1,
                                      pos + 8, length - 4, unknown, previous))
            pos += 4 + length
        self.data_end = pos
        self._props: dict[int, dict[str, Property]] = {}
        self._root: dict[int, int] = {}
        self._contexts: list[Context] | None = None
        self._units: dict[int, Unit] | None = None
        self._player_teams: dict[int, str] | None = None

    def props(self, index: int) -> dict[str, Property]:
        if index not in self._props:
            e = self.entries[index]
            props, _ = read_properties(self.body, e.offset, e.offset + e.length)
            self._props[index] = {p.name: p for p in props}
        return self._props[index]

    def reference(self, prop: Property) -> int:
        inner, _ = read_properties(self.body, prop.value_pos, prop.value_pos + prop.size)
        return int(next((p.value for p in inner if p.name == "ObjectID"), 0))

    def root(self, index: int) -> int:
        """Entry index of the first version of this object's chain."""
        if index not in self._root:
            path = []
            at = index
            while at not in self._root and self.entries[at].previous >= 0:  # chains run about 2,000 deep, so no recursion
                path.append(at)
                at = self.entries[at].previous
            top = self._root.get(at, at)
            for node in path + [at]:
                self._root[node] = top
        return self._root[index]

    @property
    def contexts(self) -> list[Context]:
        """Every context, in time order (descending frame number)."""
        if self._contexts is None:
            out = []
            for e in self.entries:
                if not e.cls.startswith(CONTEXT_PREFIX):
                    continue
                d = self.props(e.index)
                rule = str(d["GameRuleType"].value).removeprefix("eGameRule_") if "GameRuleType" in d else ""
                source = ability = None
                if "InputContext" in d:
                    ic = d["InputContext"]
                    inner, _ = read_properties(self.body, ic.value_pos, ic.value_pos + ic.size)
                    named = {p.name: p for p in inner}
                    source = self.reference(named["SourceObject"]) if "SourceObject" in named else None
                    ability = str(named["AbilityTemplateName"].value) if "AbilityTemplateName" in named else None
                out.append(Context(e.index, e.frame, e.cls.removeprefix(CONTEXT_PREFIX), rule,
                                   self.reference(d["PlayerRef"]) if "PlayerRef" in d else None,
                                   self.reference(d["UnitRef"]) if "UnitRef" in d else None,
                                   source, ability))
            out.sort(key=lambda c: -c.frame)
            self._contexts = out
        return self._contexts

    @property
    def units(self) -> dict[int, Unit]:
        """Unit chains keyed by the entry index of their first version."""
        if self._units is None:
            units: dict[int, Unit] = {}
            for e in self.entries:
                if e.cls != "XComGameState_Unit":
                    continue
                unit = units.setdefault(self.root(e.index), Unit(self.root(e.index), None, None, None, []))
                unit.states.append(e.index)
                d = self.props(e.index)
                if unit.template is None and "m_TemplateName" in d:
                    unit.template = str(d["m_TemplateName"].value)
                if unit.player is None and "ControllingPlayer" in d:
                    unit.player = self.reference(d["ControllingPlayer"])
                if unit.object_id is None and "ObjectID" in d:
                    unit.object_id = int(d["ObjectID"].value)
            self._units = units
        return self._units

    @property
    def player_teams(self) -> dict[int, str]:
        """Each XComGameState_Player's ObjectID to its TeamFlag, without the eTeam_ prefix."""
        if self._player_teams is None:
            found: dict[int, dict[str, str]] = defaultdict(dict)  # chain root to the fields seen in any version
            for e in self.entries:
                if e.cls != "XComGameState_Player":
                    continue
                d = self.props(e.index)
                for name in ("ObjectID", "TeamFlag"):
                    if name in d:
                        found[self.root(e.index)].setdefault(name, str(d[name].value))
            teams = {}
            for root, fields in found.items():
                if "ObjectID" not in fields or "TeamFlag" not in fields:
                    raise HistoryError(f"player chain at entry {root} has no {'ObjectID' if 'ObjectID' not in fields else 'TeamFlag'}")
                teams[int(fields["ObjectID"])] = fields["TeamFlag"].removeprefix("eTeam_")
            self._player_teams = teams
        return self._player_teams

    def frame_labels(self) -> dict[int, str]:
        """Frame number to a label for the context that created it."""
        return {c.frame: (c.rule or c.cls) for c in self.contexts}

# ==== report.py ============================================================
# Bytes the engine's post-load StaticDuplicateObject writes per object: about 930 MB
# over about 140,000 objects, measured on three crash dumps (docs/largesavecrash.md).
# An estimate for ranking saves, not a prediction to the byte.
COPY_BYTES_PER_OBJECT = 6600
SLACK_OVERFLOW_BYTES = 715_827_883  # CalculateSlack's int32 n*3 overflows from here
ARRAY_LIMIT_BYTES = 2**31 - 1  # TArray counts are int32

# Properties that every state carries or that say nothing about a change.
NO_CHANGE_PROPS = {"PreviousHistoryFrameIndex", "bReadOnly"}


@dataclass
class Table:
    title: str
    headers: list[str]
    rows: list[list[str]]
    notes: list[str] = field(default_factory=list)

    def render(self) -> str:
        widths = [max(len(h), *(len(r[i]) for r in self.rows)) if self.rows else len(h)
                  for i, h in enumerate(self.headers)]
        def line(cells: list[str]) -> str:
            return "  ".join(c.rjust(w) if i and _numeric(c) else c.ljust(w)
                             for i, (c, w) in enumerate(zip(cells, widths))).rstrip()
        out = [f"== {self.title}", line(self.headers), line(["-" * w for w in widths])]
        out += [line(r) for r in self.rows]
        out += [f"   {n}" for n in self.notes]
        return "\n".join(out)


def _numeric(text: str) -> bool:
    return bool(text) and (text[0].isdigit() or text[0] in "-+")


def _n(value: int) -> str:
    return f"{value:,}"


def _pct(part: int, whole: int) -> str:
    return f"{100 * part / whole:.0f}%" if whole else "-"


def _mb(value: float) -> str:
    return f"{value / 1e6:,.0f} MB"


def team_name(h: History, player: int | None) -> str:
    if player is None:
        return "strategy layer"
    team = h.player_teams.get(player)  # units keep pointing at the players of missions the save no longer holds
    return team if team else f"player {player}, not in save"


def side_name(h: History, player: int | None) -> str:
    """The team alone, for column headings."""
    return h.player_teams.get(player, f"player {player}") if player is not None else "strategy layer"


def is_no_op(h: History, index: int) -> bool:
    """A unit state that records nothing but the visibility pointer."""
    return set(h.props(index)) - NO_CHANGE_PROPS == {"VisibilityInterface"}


def classes(h: History, top: int = 12) -> Table:
    counts = Counter(e.cls for e in h.entries)
    total = len(h.entries)
    rows = [[cls, _n(n), _pct(n, total)] for cls, n in counts.most_common(top)]
    rest = total - sum(n for _, n in counts.most_common(top))
    if rest:
        rows.append([f"({len(counts) - top} other classes)", _n(rest), _pct(rest, total)])
    return Table("Objects by class", ["class", "count", "share"], rows)


def teams(h: History, top: int = 10) -> Table:
    """Units by controlling player. Units whose player is not in the save, left by earlier
    missions, share one orphaned row."""
    groups: dict[str, list] = defaultdict(list)
    players_in: dict[str, set] = defaultdict(set)
    for unit in h.units.values():
        orphaned = unit.player is not None and unit.player not in h.player_teams
        label = "orphaned" if orphaned else team_name(h, unit.player)
        groups[label].append(unit)
        players_in[label].add(unit.player)
    if "orphaned" in groups:
        groups[f"orphaned ({len(players_in['orphaned'])} players not in save)"] = groups.pop("orphaned")
    total_states = sum(len(u.states) for u in h.units.values())
    begun = Counter(team_name(h, c.player) for c in h.contexts if c.rule == "PlayerTurnBegin")
    ranked = sorted(groups.items(), key=lambda kv: -sum(len(u.states) for u in kv[1]))
    rows = []
    for label, units in ranked[:top]:
        states = sum(len(u.states) for u in units)
        mix = Counter(u.template for u in units).most_common(4)
        rows.append([label, _n(len(units)), _n(states), _pct(states, total_states),
                     _n(begun.get(label, 0)), ", ".join(f"{t} {n}" for t, n in mix)])
    rest = ranked[top:]
    notes = [f"{len(rest)} other players with {_n(sum(len(u) for _, u in rest))} units "
             f"and {_n(sum(len(x.states) for _, u in rest for x in u))} unit states"] if rest else []
    return Table("Teams",
                 ["team", "units", "unit states", "share", "turns begun", "most common templates"], rows, notes)


def rules(h: History, top: int = 10) -> Table:
    """What created the frames, how many objects each kind wrote, and how many of its unit states changed only
    their visibility. A frame's own record counts under "frames"; an object outside any frame under "(no frame)".

    Under each context holding at least BREAKDOWN_SHARE percent of objects, and under SkipTurn,
    its top SUBROWS abilities (for Ability frames) or object classes (for the rest)."""
    label = h.frame_labels()
    ability_of = {c.frame: c.ability for c in h.contexts if c.ability}
    contexts = Counter(label.values())
    objects: Counter = Counter()
    no_op: Counter = Counter()
    parts: dict[str, Counter] = defaultdict(Counter)
    for e in h.entries:
        kind = label.get(e.frame) or ("frames" if e.cls == FRAME_CLASS else "(no frame)")
        objects[kind] += 1
        parts[kind][ability_of.get(e.frame, e.cls)] += 1
        if e.cls == "XComGameState_Unit" and is_no_op(h, e.index):
            no_op[kind] += 1
    total = sum(objects.values())
    rows = []
    for kind, n in objects.most_common(top):
        rows.append([kind, _n(contexts[kind]) if kind in contexts else "", _n(n), _pct(n, total), _n(no_op[kind])])
        if len(parts[kind]) > 1 and (100 * n / total >= BREAKDOWN_SHARE or kind == "SkipTurn"):
            rows += [[f"  {part}", "", _n(m), _pct(m, total), ""]
                     for part, m in parts[kind].most_common(SUBROWS)]
    return Table("What wrote it", ["context", "count", "objects", "share", "visibility only"], rows)


def turns(h: History) -> Table:
    """Each side's k-th turn on row k: its abilities, the SkipTurns it submitted, and the unit
    states those wrote. The bar is the row's rewritten unit states, scaled to the largest row."""
    unit_player = {u.object_id: u.player for u in h.units.values() if u.object_id}
    frame_units: dict[int, list[int]] = defaultdict(list)
    for e in h.entries:
        if e.cls == "XComGameState_Unit":
            frame_units[e.frame].append(e.index)
    per_side: dict[int | None, list[tuple[int, int, int, int]]] = {}  # (abilities, SkipTurn, rewritten, no-op)
    quiet = []
    for player in sorted({c.player for c in h.contexts if c.rule == "PlayerTurnBegin"}, key=lambda p: (p is None, p)):
        begins = sorted((c.frame for c in h.contexts if c.rule == "PlayerTurnBegin" and c.player == player), reverse=True)
        ends = sorted((c.frame for c in h.contexts if c.rule == "PlayerTurnEnd" and c.player == player), reverse=True)
        side = []
        for begin in begins:
            end = next((f for f in ends if f < begin), 0)
            window = [c for c in h.contexts if end <= c.frame <= begin]
            skip_turns = [c for c in window if c.rule == "SkipTurn" and c.player == player]
            written = [i for c in skip_turns for i in frame_units.get(c.frame, [])]
            acts = sum(1 for c in window if c.cls == "Ability" and unit_player.get(c.source) == player)
            side.append((acts, len(skip_turns), len(written), sum(1 for i in written if is_no_op(h, i))))
        if any(a or k for a, k, _, _ in side):
            per_side[player] = side
        else:
            quiet.append(team_name(h, player))
    rounds = max((len(v) for v in per_side.values()), default=0)
    most = max((sum(v[k][2] for v in per_side.values() if k < len(v)) for k in range(rounds)), default=0)
    rows = []
    for k in range(rounds):
        row = [str(k + 1)]
        for side in per_side.values():
            if k < len(side):
                acts, skips, written, idle = side[k]
                row += [_n(acts), _n(skips), _n(written), _pct(idle, written)]
            else:
                row += ["", "", "", ""]
        rewritten = sum(v[k][2] for v in per_side.values() if k < len(v))
        row.append("█" * round(TURN_BLOCKS * rewritten / most) if most else "")
        rows.append(row)
    headers = ["turn"]
    for player in per_side:
        name = side_name(h, player)
        headers += [f"{name} acts", f"{name} SkipTurn", f"{name} rewritten", "visibility only"]
    notes = (["acts = abilities the side's units used; rewritten = unit states its SkipTurns wrote; "
              "visibility only = share of those that changed only their visibility; bar = rewritten, both sides"] if rows else
             ["no PlayerTurnBegin frames (an archived save keeps only the frames that hold a current version)"])
    if quiet:
        notes.append(f"no skips or abilities in any turn: {', '.join(quiet)}")
    return Table("Player turns", headers + [""], rows, notes)


def growth(h: History) -> Table:
    """How the history grows round by round, and what the post-load copy of a save taken then would be.

    A round runs from the start of the busiest AI player's turn k to the start of its
    turn k+1, so it holds that player's turn and everything between. Frames fall as time
    advances, so a round covers frames above the next turn's begin frame, up to its own.
    The copy size is a rough estimate (objects x COPY_BYTES_PER_OBJECT). Bars are scaled
    so the largest round fits GROWTH_BLOCKS blocks of a whole thousand objects.
    """
    title = "History size by round"
    skips = Counter(c.player for c in h.contexts if c.rule == "SkipTurn")
    if not skips:
        return Table(title, ["round"], [], ["no SkipTurn contexts, so no player to count rounds for"])
    player = skips.most_common(1)[0][0]
    begins = sorted((c.frame for c in h.contexts if c.rule == "PlayerTurnBegin" and c.player == player), reverse=True)
    if not begins:
        return Table(title, ["round"], [],
                     [f"no PlayerTurnBegin frame for {team_name(h, player)}, so no rounds to count "
                      "(an archived save keeps only the frames that hold a current version)"])
    skip_frames = {c.frame for c in h.contexts if c.rule == "SkipTurn" and c.player == player}
    objects_in: Counter = Counter(e.frame for e in h.entries)
    all_frames = sorted(objects_in)
    edges = begins + [-1]  # the last round runs to the end of the history

    def total_between(low: int, high: int, counter: Counter) -> int:
        i, j = bisect.bisect_right(all_frames, low), bisect.bisect_right(all_frames, high)
        return sum(counter[f] for f in all_frames[i:j])

    block = -(-(len(h.entries) + 1) // (GROWTH_BLOCKS * 1000)) * 1000  # the last round's total is every object

    def bar(n: int) -> str:
        return "█" * round(n / block)

    # the history record plus everything before turn 1, including the objects held outside any frame
    # (frame 0xFFFFFFFF, such as XpEventData)
    cumulative = 1 + total_between(begins[0], all_frames[-1], objects_in)
    rows = [["start", _n(cumulative), "", "", "", _n(round(cumulative * COPY_BYTES_PER_OBJECT / 1e6)),
             bar(cumulative)]]
    for k, begin in enumerate(begins, 1):
        low = edges[k]  # next turn's begin frame: this round's frames are above it
        added = total_between(low, begin, objects_in)
        in_skips = sum(objects_in[f] for f in skip_frames if low < f <= begin)
        n_skips = sum(1 for f in skip_frames if low < f <= begin)
        cumulative += added
        rows.append([f"turn {k}", _n(cumulative), "+" + _n(added), _n(n_skips), _pct(in_skips, added),
                     _n(round(cumulative * COPY_BYTES_PER_OBJECT / 1e6)), bar(cumulative)])
    return Table(f"{title} (each █ = {block // 1000}K objects)",
                 ["round", "objects", "added", "SkipTurn", "from SkipTurn", "load copy, MB", ""], rows)


GROWTH_BLOCKS = 30  # the longest growth bar
BREAKDOWN_SHARE = 5  # percent of objects a context needs for its breakdown rows
SUBROWS = 3  # breakdown rows under a "what wrote it" context
TURN_BLOCKS = 30  # the longest player-turn bar
TIME = re.compile(r"\d{1,2}:\d{2}")  # a description line that is a clock time, joined to the date before it


def summary(h: History, description: list[str], file_bytes: int, chunks: int, compressed: int) -> str:
    """The save's description, one line each, then its size measures, each number
    right-aligned with its label in front and its unit after."""
    lines: list[str] = []
    for line in (d.strip() for d in description if d.strip()):
        if lines and TIME.match(line):
            lines[-1] += f" {line}"
        else:
            lines.append(line)
    objects = len(h.entries) + 1
    rows = [
        ("file size", _n(file_bytes), "bytes"),
        ("compressed chunks", _n(chunks), ""),
        ("history uncompressed", _n(len(h.body)), f"bytes (ratio {len(h.body) / compressed:.1f})"),
        ("objects", _n(objects), ""),
        ("load copy (rough)", _n(round(objects * COPY_BYTES_PER_OBJECT / 1e6)), "MB"),
    ]
    key_w, value_w = max(len(k) for k, _, _ in rows), max(len(v) for _, v, _ in rows)
    return "\n".join([f"  {line}" for line in lines] +
                     [f"{k.ljust(key_w)}  {v.rjust(value_w)} {unit}".rstrip() for k, v, unit in rows])


def change(results: dict[str, tuple[History, int]]) -> Table:
    """Before and after: the size measures of each save, the first being the baseline."""
    names = list(results)
    def measures(h: History, file_bytes: int) -> list[int]:
        objects = len(h.entries) + 1
        return [file_bytes, len(h.body), sum(1 for e in h.entries if e.cls == "XComGameState"), objects,
                objects * COPY_BYTES_PER_OBJECT]
    values = {n: measures(*results[n]) for n in names}
    base = values[names[0]]
    rows = []
    for i, m in enumerate(["file size (bytes)", "history, uncompressed (bytes)", "frames", "objects", "load copy (rough)"]):
        cells = [(_mb(values[n][i]) if i == 4 else _n(values[n][i])) +
                 ("" if n == names[0] else f" ({_pct(values[n][i], base[i])})") for n in names]
        rows.append([m] + cells)
    return Table("Before and after", ["measure"] + names, rows)


def all_tables(h: History) -> list[Table]:
    return [growth(h), rules(h), classes(h), teams(h), turns(h)]


# ---- printing whole saves ---------------------------------------------------------

def history_position(buf: bytes) -> tuple[int, str]:
    """The history's file offset and a one-line description of the header."""
    try:
        header = parse_header(buf)
        return header.history_position, f"{header.description!r}, {header.created!r}, {header.map_command!r}"
    except HeaderError as e:
        (position,) = struct.unpack_from("<I", buf, 4)
        return position, f"header not parsed ({e}); history at {position}"


def load_bytes(buf: bytes) -> tuple[History, int, int, str]:
    position, note = history_position(buf)
    parts = list(chunks(buf, position))
    return History(read_body(buf, position)), len(parts), sum(c.compressed for c in parts), note


def print_reports(saves: list[tuple[str, bytes]], brief_after: bool = False) -> None:
    """The report for each save and, for several, the before-and-after tables (the first is the baseline).
    With brief_after, the saves after the first get only their summary."""
    sizes: dict[str, tuple[History, int]] = {}
    for k, (label, buf) in enumerate(saves):
        h, n_chunks, compressed, note = load_bytes(buf)
        sizes[label] = (h, len(buf))
        try:
            description = parse_header(buf).description.split("\n")
        except HeaderError:
            description = [note]
        print(f"\n######## {label}")
        print(summary(h, description, len(buf), n_chunks, compressed), end="\n\n")
        for table in [] if brief_after and k else all_tables(h):
            print(table.render(), end="\n\n")
    if len(saves) > 1:
        print(change(sizes).render())

# ==== smash.py ============================================================
BLOCK = 0x20000
# Properties compared when checking that a rewrite left every object's current state alone.


class SmashError(Exception):
    pass


# ---- checksums and compression ------------------------------------------------------

_REV8 = bytes(int(f"{i:08b}"[::-1], 2) for i in range(256))


def crc32_bzip2(data: bytes) -> int:
    """CRC-32/BZIP2 (poly 0x04C11DB7, init and xorout 0xFFFFFFFF, MSB first), via zlib.

    It equals the reflected CRC-32 of the bit-reversed bytes with the result bit-reversed.
    """
    reflected = zlib.crc32(data.translate(_REV8)) & 0xFFFFFFFF
    return int(f"{reflected:032b}"[::-1], 2)


def pick_codec(name: str):
    """(label, compress function). 'library' is lzallright, a binding to the reference LZO code."""
    if name in ("auto", "library"):
        try:
            import lzallright
            return "library (lzallright)", lzallright.LZOCompressor().compress
        except ImportError:
            if name == "library":
                raise SmashError("--codec library needs the lzallright package (pip install lzallright)")
    return "builtin (saveparser.lzo)", lzo1x_compress


def chunk_sizes(h: History) -> list[int]:
    """The uncompressed size of every chunk the game's own writer produces for this history.

    Measured on two real saves (1,230 and 2,423 chunks, reproduced exactly): everything before
    the first object (the 12-byte header, the table and the history object) is one run; then
    whole objects are collected until at least BLOCK bytes are pending and the pending bytes
    are cut into BLOCK-sized pieces, which leaves a short last piece ending on an object
    boundary; the footer after the last object is a run of its own. The loader reads a save
    object by object, so chunk boundaries have to follow this rule: uniform 128 KB chunks,
    which cut across objects, make it read garbage lengths.
    """
    def pieces(n: int) -> list[int]:
        out = []
        while n > BLOCK:
            out.append(BLOCK)
            n -= BLOCK
        return out + [n] if n else out

    sizes = pieces(h.entries[0].offset - 8)
    pending = 0
    for e in h.entries:
        pending += e.offset + e.length - (e.offset - 8)
        if pending >= BLOCK:
            sizes += pieces(pending)
            pending = 0
    sizes += pieces(pending)
    return sizes + pieces(len(h.body) - h.data_end)


def write_chunks(body: bytes, sizes: list[int], compress=lzo1x_compress) -> bytes:
    if sum(sizes) != len(body):
        raise SmashError(f"chunk plan covers {sum(sizes)} bytes, the body has {len(body)}")
    out = bytearray()
    at = 0
    for size in sizes:
        block = body[at:at + size]
        at += size
        packed = compress(block)
        out += struct.pack("<IIIIII", TAG, BLOCK, len(packed), len(block), len(packed), len(block)) + packed
    return bytes(out)


def seal(header: bytes, chunk_bytes: bytes, checksum2_offset: int) -> bytes:
    """The two header checksums for `header` + `chunk_bytes`, written into a copy of the header."""
    h = bytearray(header)
    struct.pack_into("<I", h, checksum2_offset, crc32_bzip2(chunk_bytes))
    struct.pack_into("<I", h, 8, 0)
    struct.pack_into("<I", h, 8, crc32_bzip2(bytes(h)))
    return bytes(h) + chunk_bytes


# ---- validation -----------------------------------------------------------------------


def structure_problems(h: History) -> list[str]:
    """Self-consistency of a history, independent of any original."""
    E, B, n = h.entries, h.body, len(h.entries)
    out: list[str] = []
    if h.declared_count != n + 1:
        out.append(f"declared count {h.declared_count} but {n + 1} records")
    xgs = {e.index: e for e in E if e.cls == "XComGameState"}
    xgs_hi = {i: h.props(i)["HistoryIndex"].value for i in xgs if "HistoryIndex" in h.props(i)}
    bad_self = bad_prev = bad_ctx = 0
    for e in E:
        d = h.props(e.index)
        if "VisibilityInterface" in d and struct.unpack_from("<i", B, d["VisibilityInterface"].value_pos)[0] != e.index + 1:
            bad_self += 1
        if e.previous >= 0:
            if e.previous >= n or E[e.previous].cls != e.cls:
                bad_prev += 1
            elif "PreviousHistoryFrameIndex" in d:
                if d["PreviousHistoryFrameIndex"].value != xgs_hi.get(E[e.previous].frame - 1):
                    bad_prev += 1
    for i in xgs:
        d = h.props(i)
        if "StateChangeContext" in d:
            v = struct.unpack_from("<i", B, d["StateChangeContext"].value_pos)[0]
            if not (0 < v <= n and E[v - 1].cls.startswith("XComGameStateContext_") and E[v - 1].frame == i + 1):
                bad_ctx += 1
    const = {hi + i + 1 for i, hi in xgs_hi.items()}
    if len(const) > 1:
        out.append(f"history index plus frame reference is not constant ({len(const)} values)")
    for label, count in (("units whose VisibilityInterface is not their own reference", bad_self),
                         ("bad previous-version links or PreviousHistoryFrameIndex", bad_prev),
                         ("frames whose StateChangeContext is not their own context", bad_ctx)):
        if count:
            out.append(f"{count} {label}")
    hist_props, _ = read_properties(B, h.history_object[0], h.history_object[0] + h.history_object[1])
    array = next((p for p in hist_props if p.name == "History"), None)
    if array is not None:
        (count,) = struct.unpack_from("<i", B, array.value_pos)
        refs = set(struct.unpack_from(f"<{count}i", B, array.value_pos + 4))
        if refs != {i + 1 for i in xgs_hi}:
            out.append(f"History array holds {len(refs)} frames, frames with a HistoryIndex number {len(xgs_hi)}")
    return out

# ==== refs.py ============================================================
class RefError(Exception):
    pass


# `struct immutable` in SDK Src/Core/Classes/Object.uc lines 183-509: native layout, no objects.
IMMUTABLE_STRUCTS = {"Guid", "Vector", "Vector4", "Vector2D", "TwoVectors", "Plane", "Rotator", "Quat",
                     "PackedNormal", "IntPoint", "Color", "LinearColor", "Box", "Matrix"}


@dataclass
class Ref:
    pos: int  # offset of the i32 in the buffer
    path: str


@dataclass
class ListArray:
    prop: Property  # a top-level LISTS array; its elements are table indexes
    path: str


@dataclass
class Found:
    refs: list[Ref]
    lists: list[ListArray]
    end: int  # where the tagged properties ended (a native trailer may follow)
    untyped: list[str]  # paths of properties whose references cannot be told: 4-byte arrays, native structs


def _try_struct_elements(buf: bytes, start: int, end: int, count: int) -> list[list[Property]] | None:
    pos, elements = start, []
    try:
        for _ in range(count):
            props, pos = read_properties(buf, pos, end)
            if any(not p.name.isidentifier() for p in props):
                return None
            elements.append(props)
    except (ParseError, struct.error, UnicodeDecodeError):
        return None
    return elements if pos == end else None


def _delegate_shaped(buf: bytes, start: int, end: int, count: int) -> bool:
    pos = start
    try:
        for _ in range(count):
            _, pos = read_name(buf, pos + 4, end)
            _, pos = read_fstring(buf, pos, end)
    except (ParseError, struct.error, UnicodeDecodeError):
        return False
    return pos == end


def struct_members(buf: bytes, p: Property) -> tuple[list[Property], int] | None:
    """A tagged struct value's members and where its closing `None` starts, or None for any other
    property (an immutable struct, a natively serialized struct, not a struct at all).

    A later version of an object writes a tagged struct member by member, leaving out each member
    whose value equals the previous version's (save_Ava_WW, unit 1087's TileLocation: {X 25, Y 38}
    then {Y 37}), so a struct's current value is merged member by member along the chain."""
    if p.type != "StructProperty" or p.extra in IMMUTABLE_STRUCTS:
        return None
    try:
        inner, after = read_properties(buf, p.value_pos, p.value_pos + p.size)
    except (ParseError, struct.error, UnicodeDecodeError):
        return None
    if after != p.value_pos + p.size:
        return None
    last = inner[-1] if inner else None
    none_start = p.value_pos if last is None else last.value_pos + (1 if last.type == "BoolProperty" else last.size)
    return inner, none_start


def _walk(buf: bytes, props: list[Property], owner: str, path: str, top: bool, found: Found) -> None:
    for p in props:
        here = f"{path}.{p.name}"
        if p.type in ("ObjectProperty", "InterfaceProperty", "DelegateProperty"):
            found.refs.append(Ref(p.value_pos, here))
        elif p.type == "StructProperty":
            if p.extra in IMMUTABLE_STRUCTS:
                continue
            try:
                inner, after = read_properties(buf, p.value_pos, p.value_pos + p.size)
            except (ParseError, struct.error, UnicodeDecodeError):
                found.untyped.append(here)  # a struct serialized natively: its layout is not known here
                continue
            if after != p.value_pos + p.size:
                found.untyped.append(here)
                continue
            _walk(buf, inner, p.extra or "?", f"{here}<{p.extra}>", False, found)
        elif p.type == "ArrayProperty":
            _array(buf, p, owner, here, top, found)


def _array(buf: bytes, p: Property, owner: str, here: str, top: bool, found: Found) -> None:
    (count,) = struct.unpack_from("<i", buf, p.value_pos)
    start, end = p.value_pos + 4, p.value_pos + p.size
    if count == 0:
        return
    if (owner, p.name) in LISTS:
        if not top or end - start != 4 * count:
            raise RefError(f"{here}: frame list that is nested or not made of 4-byte elements")
        found.lists.append(ListArray(p, here))
        return
    if end - start == 4 * count:
        found.untyped.append(here)
        return
    elements = _try_struct_elements(buf, start, end, count)
    if elements is not None:
        for props in elements:
            _walk(buf, props, "?", f"{here}[]", False, found)
        return
    if _delegate_shaped(buf, start, end, count):
        pos = start
        for i in range(count):
            found.refs.append(Ref(pos, f"{here}[{i}]"))
            _, pos = read_name(buf, pos + 4)
            _, pos = read_fstring(buf, pos)
    # otherwise names, strings, bytes or immutable structs: no reference


def find_refs(buf: bytes, cls: str, offset: int, length: int) -> Found:
    """Every typed table reference in one object's data (`offset` is past the leading i32 -1).
    A native trailer after `None` is not read."""
    props, after = read_properties(buf, offset, offset + length)
    found = Found([], [], after, [])
    _walk(buf, props, cls, cls, True, found)
    return found

# ==== compare.py ============================================================
# History bookkeeping, not game state: the self pointer and the history-index links.
IGNORED = {"VisibilityInterface", "PreviousHistoryFrameIndex", "HistoryIndex", "EventChainStartIndex", "bReadOnly"}


@dataclass
class Snapshot:
    cls: str
    state: dict[tuple, bytes]  # key path of (name, array index) pairs, a struct member below its struct
    template: str | None
    untyped: set[tuple]  # properties holding an array whose element type is not known


@dataclass
class Side:
    objects: dict[int, Snapshot]  # ObjectID -> current state
    unresolved: dict[int, str]  # ObjectID -> why its frame lists could not be read
    no_id: int  # chains whose first version carries no ObjectID
    branched: int = 0  # chains with more than one live end
    superseded: int = 0  # chains left out because a newer chain carries the same ObjectID


def _live(h: History) -> set[int]:
    """Entry indexes some frame's GameStates names."""
    out: set[int] = set()
    for e in h.entries:
        if e.cls != "XComGameState" or "GameStates" not in h.props(e.index):
            continue
        p = h.props(e.index)["GameStates"]
        (count,) = struct.unpack_from("<i", h.body, p.value_pos)
        if p.size != 4 + 4 * count:
            raise RefError(f"XComGameState[{e.index}].GameStates: {count} elements in {p.size} bytes")
        out.update(v - 1 for v in struct.unpack_from(f"<{count}i", h.body, p.value_pos + 4) if v > 0)
    return out


def _identity(h: History, frame_hi: dict[int, int], object_id: dict[int, int]):
    """A function from a table reference to a value that means the same thing in any save."""
    n = len(h.entries)

    def name(v: int) -> bytes:
        if not 0 < v <= n:
            return struct.pack("<i", v)  # None (-1, 0) or an object that was not saved
        e = h.entries[v - 1]
        if e.cls == "XComGameState":
            return f"frame@{frame_hi[e.index]}".encode()
        if e.cls.startswith(CONTEXT_PREFIX):
            return f"context@{frame_hi[e.frame - 1]}".encode()
        root = h.root(e.index)
        if root in object_id:
            return f"{e.cls}#{object_id[root]}".encode()
        return f"{e.cls}@unidentified".encode()
    return name


def _leaves(buf: bytes, props: list, prefix: tuple = ()):
    """(key path, property) for every property, a tagged struct's members as their own keys: a
    later version writes only the struct members it changed (`refs.struct_members`)."""
    for p in props:
        key = prefix + ((p.name, p.array_index),)
        members = struct_members(buf, p)
        if members is None:
            yield key, p
        else:
            yield from _leaves(buf, members[0], key)


def snapshot(h: History) -> Side:
    E, B = h.entries, h.body
    live = _live(h)
    frame_hi = {e.index: int(h.props(e.index)["HistoryIndex"].value) for e in E
                if e.cls == "XComGameState" and "HistoryIndex" in h.props(e.index)}
    object_id = {e.index: int(h.props(e.index)["ObjectID"].value) for e in E
                 if e.previous < 0 and "ObjectID" in h.props(e.index)}
    name = _identity(h, frame_hi, object_id)
    has_next = {e.previous for e in E if e.previous >= 0 and e.index in live}
    newest: dict[int, int] = {}
    branched: set[int] = set()
    for e in E:
        if e.index in live and e.index not in has_next and e.cls != "XComGameState" and not e.cls.startswith(CONTEXT_PREFIX):
            root = h.root(e.index)
            if root in newest:
                branched.add(root)
                if E[newest[root]].frame <= e.frame:
                    continue
            newest[root] = e.index
    side = Side({}, {}, 0, len(branched))
    # an ObjectID can start a second chain with no link to the first; the game resolves the ID
    # to the chain whose newest version is in the newer frame
    by_id: dict[int, int] = {}
    for root, tail in newest.items():
        if root not in object_id:
            side.no_id += 1
        elif object_id[root] not in by_id or E[newest[by_id[object_id[root]]]].frame > E[tail].frame:
            by_id[object_id[root]] = root
    side.superseded = len(newest) - side.no_id - len(by_id)
    for oid, root in by_id.items():
        tail = newest[root]
        chain = []
        at = tail
        while at >= 0:
            chain.append(at)
            at = E[at].previous
        state: dict[tuple, bytes] = {}
        untyped: set[tuple] = set()
        try:
            for i in reversed(chain):
                e = E[i]
                found = find_refs(B, e.cls, e.offset, e.length)
                refs = found.refs
                loose = {path.removeprefix(f"{e.cls}.").split(".")[0].split("<")[0] for path in found.untyped}
                props, _ = read_properties(B, e.offset, e.offset + e.length)
                for key, p in _leaves(B, [q for q in props if q.name not in IGNORED and (e.cls, q.name) not in LISTS]):
                    if p.type == "BoolProperty":
                        state[key] = bytes([p.value])
                        continue
                    if key[0][0] in loose:
                        untyped.add(key)
                    lo, hi = p.value_pos, p.value_pos + p.size
                    inner = [r.pos for r in refs if lo <= r.pos < hi]
                    out, at = bytearray(), lo
                    for r in inner:
                        out += B[at:r] + b"<" + name(struct.unpack_from("<i", B, r)[0]) + b">"
                        at = r + 4
                    state[key] = bytes(out + B[at:hi])
        except RefError as err:
            side.unresolved[oid] = str(err)
            continue
        template = next((str(h.props(i)["m_TemplateName"].value) for i in chain if "m_TemplateName" in h.props(i)), None)
        side.objects[oid] = Snapshot(E[root].cls, state, template, untyped)
    return side


@dataclass
class Difference:
    object_id: int
    cls: str
    template: str | None
    keys: list[str]
    untyped: list[str]  # of `keys`, those holding an array whose element type is not known


@dataclass
class Comparison:
    compared: int
    only_a: Counter = field(default_factory=Counter)  # class -> count
    only_b: Counter = field(default_factory=Counter)
    class_changed: list[str] = field(default_factory=list)
    unresolved: dict[int, str] = field(default_factory=dict)
    differences: list[Difference] = field(default_factory=list)
    no_id: tuple[int, int] = (0, 0)
    branched: tuple[int, int] = (0, 0)


def _key(k: tuple) -> str:
    return ".".join(name if index == 0 else f"{name}[{index}]" for name, index in k)


def compare(a: History, b: History) -> Comparison:
    sa, sb = snapshot(a), snapshot(b)
    out = Comparison(0, no_id=(sa.no_id, sb.no_id), branched=(sa.branched, sb.branched))
    out.unresolved = {**sa.unresolved, **sb.unresolved}
    for oid, snap in sa.objects.items():
        if oid in out.unresolved:
            continue
        if oid not in sb.objects:
            out.only_a[snap.cls] += 1
            continue
        other = sb.objects[oid]
        if other.cls != snap.cls:
            out.class_changed.append(f"ObjectID {oid}: {snap.cls} -> {other.cls}")
            continue
        out.compared += 1
        changed = [k for k in set(snap.state) | set(other.state) if snap.state.get(k) != other.state.get(k)]
        if changed:
            loose = snap.untyped | other.untyped
            out.differences.append(Difference(oid, snap.cls, snap.template, sorted(_key(k) for k in changed),
                                              sorted(_key(k) for k in changed if k in loose)))
    for oid, snap in sb.objects.items():
        if oid not in sa.objects and oid not in out.unresolved:
            out.only_b[snap.cls] += 1
    return out


def render_comparison(c: Comparison, label_a: str, label_b: str, show: int) -> str:
    lines = [f"== Compare: {label_a} (A) against {label_b} (B)",
             f"objects compared by ObjectID: {c.compared:,}",
             f"objects whose current state differs: {len(c.differences):,}"]
    for label, counts in (("only in A", c.only_a), ("only in B", c.only_b)):
        if counts:
            lines.append(f"{label}: {sum(counts.values()):,} ({', '.join(f'{k} {v}' for k, v in counts.most_common(8))})")
    if c.class_changed:
        lines.append(f"class changed: {len(c.class_changed)}, e.g. {c.class_changed[:3]}")
    if c.unresolved:
        reasons = Counter(why.split(":")[0] for why in c.unresolved.values())
        lines.append(f"not compared, frame list unreadable: {len(c.unresolved):,} "
                     f"({', '.join(f'{k} {v}' for k, v in reasons.most_common(4))})")
    if any(c.no_id):
        lines.append(f"chains with no ObjectID, not compared: A {c.no_id[0]:,}, B {c.no_id[1]:,}")
    if any(c.branched):
        lines.append(f"chains with several live ends, newest frame taken: A {c.branched[0]:,}, B {c.branched[1]:,}")
    if c.differences:
        by_class = Counter(d.cls for d in c.differences)
        by_prop = Counter(k for d in c.differences for k in d.keys)
        lines.append("differing objects by class: " + ", ".join(f"{k} {v}" for k, v in by_class.most_common()))
        lines.append("differing properties: " + ", ".join(f"{k} {v}" for k, v in by_prop.most_common(20)))
        loose = Counter(k for d in c.differences for k in d.untyped)
        if loose:
            lines.append("   of those, arrays of 4-byte elements whose type the save does not record (a difference may be a "
                         "renumbered reference): " + ", ".join(f"{k} {v}" for k, v in loose.most_common(10)))
        for d in sorted(c.differences, key=lambda d: (d.cls, d.object_id))[:show]:
            lines.append(f"   {d.cls} #{d.object_id} {d.template or ''}: {', '.join(d.keys[:8])}")
        if len(c.differences) > show:
            lines.append(f"   ... {len(c.differences) - show:,} more (--show)")
    return "\n".join(lines)

# ==== archive.py ============================================================
LABEL = " (archived)"  # added to the save name in the Load Game list
ARCHIVE_CONTEXT = CONTEXT_PREFIX + "ArchiveHistory"
START_CONTEXT = CONTEXT_PREFIX + "TacticalGameRule"
# int properties that hold a history index (found in save_Ava_WW by value range, then read in the
# SDK source): contexts' event-chain and interruption links, and the units' and AI's own records
HISTORY_INDEX_INTS = {"EventChainStartIndex", "InterruptionHistoryIndex", "ResumeHistoryIndex",
                      "HistoryIndexInterruptedBySelf", "DesiredVisualizationBlockIndex",
                      "m_SuppressionHistoryIndex", "multifireHistoryIndex", "m_iLastEndTurnHistoryIndex"}


class ArchiveError(Exception):
    pass


@dataclass
class Built:
    body: bytes
    history_index: int  # the archive frame's new history index, also NumArchivedFrames
    kept: int  # entries of the archive and start frames, copied
    changed: int  # versions in the frames after the start
    dropped: int  # objects created during the mission and removed since, left out
    nulled: Counter = field(default_factory=Counter)  # (class, property) -> references to dropped frames or contexts set to -1
    untyped: Counter = field(default_factory=Counter)  # (class, property) -> objects holding a 4-byte array copied as is
    frames: int = 0  # frames after the start that hold a current version, kept


@dataclass
class Node:
    """One property of an object's merged current state: the version it was last written in,
    and for a tagged struct its merged members and the closing None of its newest version."""
    version: int
    prop: Property
    children: dict | None
    none: bytes


def _end(p: Property) -> int:
    return p.value_pos + (1 if p.type == "BoolProperty" else p.size)


def _int_array(values: list[int]) -> bytes:
    return struct.pack("<i", len(values)) + struct.pack(f"<{len(values)}i", *values)


def _with_value(B: bytes, p: Property, value: bytes) -> bytes:
    """The property's raw tag with a new value, the size field matched to it. The size and array
    index follow the name and the type; a struct's or enum's own name comes after them."""
    at = read_name(B, read_name(B, p.tag_pos)[1])[1]
    return B[p.tag_pos:at] + struct.pack("<ii", len(value), p.array_index) + B[at + 8:p.value_pos] + value


def _object_bytes(B: bytes, offset: int, length: int, replace: dict[str, bytes]) -> bytes:
    """An object's data from its leading i32 -1, its properties copied raw except those named in
    `replace` (name -> whole raw property). Raises if a named property is absent."""
    props, _ = read_properties(B, offset, offset + length)
    missing = set(replace) - {p.name for p in props}
    if missing:
        raise ArchiveError(f"object at {offset} has no {sorted(missing)}")
    out = bytearray(struct.pack("<i", -1))
    for p in props:
        out += replace.get(p.name, B[p.tag_pos:_end(p)])
    none_start = _end(props[-1]) if props else offset
    return bytes(out + B[none_start:offset + length])


def build(h: History) -> Built:
    E, B, n = h.entries, h.body, len(h.entries)
    hist = {p.name: p for p in read_properties(B, h.history_object[0], h.history_object[0] + h.history_object[1])[0]}
    for name in ("History", "NumArchivedFrames", "HistoryStartIndex", "StateObjectCache"):
        if name not in hist:
            raise ArchiveError(f"the history record has no {name}")
    frame_hi = {e.index: int(h.props(e.index)["HistoryIndex"].value) for e in E
                if e.cls == FRAME_CLASS and "HistoryIndex" in h.props(e.index)}
    (count,) = struct.unpack_from("<i", B, hist["History"].value_pos)
    frames = struct.unpack_from(f"<{count}i", B, hist["History"].value_pos + 4)
    archived = int(hist["NumArchivedFrames"].value)
    if sorted(frame_hi[f - 1] for f in frames) != list(range(archived, archived + count)):
        raise ArchiveError("the frame array's history indexes do not run densely from NumArchivedFrames")
    by_hi = {frame_hi[f - 1]: f - 1 for f in frames}
    contexts = {e.frame - 1: e for e in E if e.cls.startswith(CONTEXT_PREFIX)}
    start_hi = int(hist["HistoryStartIndex"].value)
    if start_hi not in by_hi or contexts[by_hi[start_hi]].cls != START_CONTEXT \
            or "GameRuleType" in h.props(contexts[by_hi[start_hi]].index):
        raise ArchiveError("HistoryStartIndex does not name a tactical start state: not a tactical save")
    if start_hi - 1 not in by_hi or contexts[by_hi[start_hi - 1]].cls != ARCHIVE_CONTEXT:
        raise ArchiveError("the frame before the start state is not an ArchiveHistory frame")
    if start_hi + 1 not in by_hi:
        raise ArchiveError("nothing happened after the start state: there is nothing to collapse")
    ARCHIVE, START = by_hi[start_hi - 1], by_hi[start_hi]
    cache = struct.unpack_from("<i", B, hist["StateObjectCache"].value_pos)[0] - 1
    if not (0 <= cache < n and E[cache].cls == FRAME_CLASS):
        raise ArchiveError("StateObjectCache does not name an XComGameState in the table")
    new_hi = archived + count  # the archive frame's new index; start and collapsed frames follow

    kept_frames = {ARCHIVE + 1, START + 1}  # a context's or object's frame field is its XComGameState's reference
    kept = [e.index for e in E if e.frame in kept_frames]
    kept_set = set(kept)

    # the newest live version of every state object, the newest frame winning a branch
    live = _live(h)
    newest: dict[int, int] = {}
    for e in E:
        if e.index in live and e.cls != FRAME_CLASS and not e.cls.startswith(CONTEXT_PREFIX):
            root = h.root(e.index)
            if root not in newest or E[newest[root]].frame > e.frame:
                newest[root] = e.index

    def chain(tail: int) -> list[int]:
        out = []
        while tail >= 0:
            out.append(tail)
            tail = E[tail].previous
        return out[::-1]

    def merge_into(state: dict, props: list[Property], i: int) -> None:
        """Lay version i's properties over `state`, key (name, array index) -> Node; a tagged struct
        is merged member by member, since a version leaves out the members it did not change."""
        for p in props:
            key = (p.name, p.array_index)
            members = struct_members(B, p)
            if members is None:
                state[key] = Node(i, p, None, b"")
                continue
            inner, none_start = members
            children = dict(state[key].children) if key in state and state[key].children is not None else {}
            merge_into(children, inner, i)
            state[key] = Node(i, p, children, B[none_start:p.value_pos + p.size])

    def merged(tail: int) -> dict[tuple[str, int], Node]:
        state: dict[tuple[str, int], Node] = {}
        for i in chain(tail):
            merge_into(state, read_properties(B, E[i].offset, E[i].offset + E[i].length)[0], i)
        return state

    def removed(state: dict[tuple[str, int], Node]) -> bool:
        return ("bRemoved", 0) in state and bool(state[("bRemoved", 0)].prop.value)

    # each object whose newest version is past the start frame gets one version, in the frame that
    # wrote its newest version; frames that hold no newest version are dropped
    changed: dict[int, list[tuple[int, int, dict]]] = {}  # frame -> [(root, base version in the kept frames or -1, state)]
    dropped = 0
    for root, tail in newest.items():
        if tail in kept_set:
            continue
        base = next((i for i in reversed(chain(tail)) if i in kept_set), -1)
        state = merged(tail)
        if removed(state) and base < 0:
            dropped += 1
            continue
        if ("ObjectID", 0) not in state:
            raise ArchiveError(f"{E[root].cls}[{root}] has no ObjectID")
        changed.setdefault(E[tail].frame - 1, []).append((root, base, state))
    for versions in changed.values():
        versions.sort(key=lambda c: int(c[2][("ObjectID", 0)].prop.value))
    later = sorted(changed, key=lambda f: frame_hi[f])  # kept frames after the start, oldest first
    hi_map = {start_hi - 1: new_hi, start_hi: new_hi + 1, **{frame_hi[f]: new_hi + 2 + k for k, f in enumerate(later)}}

    # new table, in the save's own order: 0 the cache, the frames' XComGameStates newest first, then
    # each frame's context and objects, oldest frame first; a reference is position + 1
    frames_newest_first = list(reversed(later)) + [START, ARCHIVE]
    frame_ref = {f: 2 + k for k, f in enumerate(frames_newest_first)}
    frame_ref[cache] = 1
    at = 2 + len(frames_newest_first)
    kept_ref = {i: at + k for k, i in enumerate(kept)}
    at += len(kept)
    context_ref: dict[int, int] = {}
    changed_ref: dict[int, int] = {}
    for f in later:
        context_ref[f] = at
        for k, (root, _, _) in enumerate(changed[f]):
            changed_ref[root] = at + 1 + k
        at += 1 + len(changed[f])
    current_ref = {**{h.root(i): kept_ref[i] for i in kept if newest.get(h.root(i)) == i}, **changed_ref}
    built = Built(b"", new_hi, len(kept), len(changed_ref), dropped, frames=len(later))

    def remap(v: int, owner: str, path: str) -> int:
        if not 0 < v <= n:
            return v
        i = v - 1
        if i in kept_ref:
            return kept_ref[i]
        if i in frame_ref:
            return frame_ref[i]
        if E[i].cls.startswith(CONTEXT_PREFIX) and E[i].frame - 1 in context_ref:
            return context_ref[E[i].frame - 1]
        if E[i].cls == FRAME_CLASS or E[i].cls.startswith(CONTEXT_PREFIX):
            built.nulled[(owner, path)] += 1
            return -1
        return current_ref.get(h.root(i), -1)

    def index_ints(props: dict[str, Property], own_hi: int) -> dict[str, int]:
        """New values for the int properties that hold a history index: a kept frame's index maps
        to its new one; an event chain whose first frame was dropped starts at this frame; any
        other index into a dropped frame becomes -1."""
        out = {}
        for name in HISTORY_INDEX_INTS:
            if name in props and props[name].type == "IntProperty":
                v = int(props[name].value)
                if v in hi_map:
                    out[name] = hi_map[v]
                elif archived <= v < archived + count:
                    out[name] = own_hi if name == "EventChainStartIndex" else -1
        return out

    def patched(i: int, ints: dict[str, int] | None = None) -> bytes:
        """Entry i's data from its leading i32 -1, every typed reference and frame-list element
        renumbered in place and the named int properties set; nothing changes size."""
        e = E[i]
        blob = bytearray(B[e.offset - 4:e.offset + e.length])
        found = find_refs(B, e.cls, e.offset, e.length)
        for r in found.refs:
            v = struct.unpack_from("<i", B, r.pos)[0]
            struct.pack_into("<i", blob, r.pos - e.offset + 4, remap(v, e.cls, r.path.removeprefix(f"{e.cls}.")))
        for arr in found.lists:
            (k,) = struct.unpack_from("<i", B, arr.prop.value_pos)
            for j in range(k):
                pos = arr.prop.value_pos + 4 + 4 * j
                struct.pack_into("<i", blob, pos - e.offset + 4, remap(struct.unpack_from("<i", B, pos)[0], e.cls, arr.path))
        props = h.props(i)
        for name, value in (ints or {}).items():
            struct.pack_into("<i", blob, props[name].value_pos - e.offset + 4, value)
        for path in found.untyped:
            built.untyped[(e.cls, path.removeprefix(f"{e.cls}.").split(".")[0].split("<")[0])] += 1
        return bytes(blob)

    def kept_record(i: int) -> tuple[str, int, int, int, int, bytes]:
        e = E[i]
        ints = index_ints(h.props(i), hi_map[frame_hi[e.frame - 1]])
        if e.previous >= 0:
            if e.previous not in kept_ref:
                raise ArchiveError(f"{e.cls}[{i}] in a kept frame links to a version outside them")
            if "PreviousHistoryFrameIndex" in h.props(i):
                ints["PreviousHistoryFrameIndex"] = hi_map[int(h.props(i)["PreviousHistoryFrameIndex"].value)]
        previous_raw = kept_ref[e.previous] if e.previous >= 0 else e.previous_raw
        return e.cls, frame_ref[e.frame - 1], e.unknown, e.size, previous_raw, patched(i, ints)

    def copy_property(i: int, p: Property, owner: str, found: dict[int, list]) -> bytes:
        if i not in found:
            f = find_refs(B, E[i].cls, E[i].offset, E[i].length)
            found[i] = f.refs
            for path in f.untyped:
                built.untyped[(owner, path.removeprefix(f"{E[i].cls}.").split(".")[0].split("<")[0])] += 1
        raw = bytearray(B[p.tag_pos:_end(p)])
        for r in found[i]:
            if p.tag_pos <= r.pos < _end(p):
                v = struct.unpack_from("<i", B, r.pos)[0]
                struct.pack_into("<i", raw, r.pos - p.tag_pos, remap(v, owner, r.path.removeprefix(f"{E[i].cls}.")))
        return bytes(raw)

    def changed_record(frame: int, root: int, base: int, state: dict) -> tuple[str, int, int, int, int, bytes]:
        """The object's full current state in the frame that wrote its newest version, linked to its
        version in the archive or start frame; an object created during the mission keeps the
        previous-frame index its first version carried."""
        tail = newest[root]
        e = E[tail]
        props, after = read_properties(B, e.offset, e.offset + e.length)
        trailer = B[after:e.offset + e.length]
        if not trailer and any(read_properties(B, E[i].offset, E[i].offset + E[i].length)[1] != E[i].offset + E[i].length
                               for i in chain(tail)):
            raise ArchiveError(f"{e.cls}[{tail}]: an older version carries a native trailer the newest does not")
        if ("PreviousHistoryFrameIndex", 0) not in state:
            raise ArchiveError(f"{e.cls}[{tail}] has no PreviousHistoryFrameIndex")
        if base >= 0:
            previous_hi = hi_map[frame_hi[E[base].frame - 1]]
        else:
            first = int(h.props(root)["PreviousHistoryFrameIndex"].value) if "PreviousHistoryFrameIndex" in h.props(root) else -1
            previous_hi = hi_map.get(first, first)
        ints = {}
        for key, node in state.items():
            if key[0] in HISTORY_INDEX_INTS and node.prop.type == "IntProperty":
                ints.update(index_ints({key[0]: node.prop}, hi_map[frame_hi[frame]]))
        found: dict[int, list] = {}

        def serialize(node: Node) -> bytes:
            if node.children is None:
                return copy_property(node.version, node.prop, e.cls, found)
            body = b"".join(serialize(child) for child in node.children.values()) + node.none
            return _with_value(B, node.prop, body)

        out = bytearray(struct.pack("<i", -1))
        for key, node in state.items():
            if key == ("PreviousHistoryFrameIndex", 0):
                out += _with_value(B, node.prop, struct.pack("<i", previous_hi))
            elif key[0] in ints and key[1] == 0:
                out += _with_value(B, node.prop, struct.pack("<i", ints[key[0]]))
            else:
                out += serialize(node)
        none_start = _end(props[-1]) if props else e.offset
        return (e.cls, frame_ref[frame], e.unknown, e.size, kept_ref[base] if base >= 0 else -1,
                bytes(out + B[none_start:after] + trailer))

    records: list[tuple[str, int, int, int, int, bytes]] = []  # class, frame, unknown, size, previous_raw, data
    # the cache lists each ObjectID's current version, the newer chain winning a duplicated ID
    by_id: dict[int, tuple[int, int]] = {}  # ObjectID -> (frame of the current version, its reference)
    for root, ref in current_ref.items():
        if "ObjectID" not in h.props(root):
            continue
        oid = int(h.props(root)["ObjectID"].value)
        frame = E[newest[root]].frame
        if oid not in by_id or frame < by_id[oid][0]:
            by_id[oid] = (frame, ref)
    records.append((FRAME_CLASS, E[cache].frame, E[cache].unknown, E[cache].size, E[cache].previous_raw,
                    _object_bytes(B, E[cache].offset, E[cache].length, {
                        "GameStates": _with_value(B, h.props(cache)["GameStates"],
                                                  _int_array(sorted(ref for _, ref in by_id.values())))})))
    for f in frames_newest_first:
        if f in (START, ARCHIVE):
            records.append((FRAME_CLASS, 0, E[f].unknown, E[f].size, E[f].previous_raw,
                            patched(f, {"HistoryIndex": hi_map[frame_hi[f]]})))
            continue
        s = h.props(f)
        records.append((FRAME_CLASS, 0, E[f].unknown, E[f].size, E[f].previous_raw,
                        _object_bytes(B, E[f].offset, E[f].length, {
                            "GameStates": _with_value(B, s["GameStates"], _int_array([changed_ref[r] for r, _, _ in changed[f]])),
                            "StateChangeContext": _with_value(B, s["StateChangeContext"], struct.pack("<i", context_ref[f])),
                            "HistoryIndex": _with_value(B, s["HistoryIndex"], struct.pack("<i", hi_map[frame_hi[f]])),
                        })))
    records += [kept_record(i) for i in kept]
    for f in later:
        ctx = contexts[f]
        records.append((ctx.cls, frame_ref[f], ctx.unknown, ctx.size, ctx.previous_raw,
                        patched(ctx.index, index_ints(h.props(ctx.index), hi_map[frame_hi[f]]))))
        records += [changed_record(f, root, base, state) for root, base, state in changed[f]]
    if len(records) != at - 1:
        raise ArchiveError("the table positions do not match the references written into it")

    # the history record: the kept frames, everything before them archived, the start state second
    for p in hist.values():
        if p.name != "StateObjectCache" and p.type in ("ObjectProperty", "InterfaceProperty"):
            raise ArchiveError(f"the history record's {p.name} is a reference this module does not rebuild")
    history = _object_bytes(B, h.history_object[0], h.history_object[1], {
        "History": _with_value(B, hist["History"], _int_array([frame_ref[f] for f in reversed(frames_newest_first)])),
        "NumArchivedFrames": _with_value(B, hist["NumArchivedFrames"], struct.pack("<i", new_hi)),
        "HistoryStartIndex": _with_value(B, hist["HistoryStartIndex"], struct.pack("<i", new_hi + 1)),
        "StateObjectCache": _with_value(B, hist["StateObjectCache"], struct.pack("<i", 1)),
    })

    out = bytearray(struct.pack("<III", 0x34D, 0x78, len(records) + 1))
    out += write_fstring(HISTORY_CLASS) + h.history_fields
    for cls, frame, unknown, size, previous_raw, _ in records:
        out += write_fstring(cls) + struct.pack("<IiIi", frame, unknown, size, previous_raw)
    for blob in [history] + [r[5] for r in records]:
        out += struct.pack("<I", len(blob)) + blob
    out += B[h.data_end:]
    built.body = bytes(out)
    return built


# ---- command --------------------------------------------------------------------------

@dataclass
class Result:
    before: int
    after: int
    built: Built
    structure: list[str]
    comparison: str
    file_bytes: int
    seconds: float
    path: Path | None
    file: bytes = b""


def run(path: Path, out: Path | None, codec: str = "builtin") -> Result:
    started = time.time()
    codec_label, compress = pick_codec(codec)
    buf = path.read_bytes()
    header = parse_header(buf)
    old = History(read_body(buf, header.history_position))
    built = build(old)
    new = History(built.body)
    head = relabel(buf[:header.history_position], LABEL)
    file = seal(head, write_chunks(built.body, chunk_sizes(new), compress), parse_header(head).checksum2_offset)
    if out is not None:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(file)
    comparison = render_comparison(compare(old, new), path.name, f"{path.name}{LABEL}", 20)
    return Result(len(old.entries) + 1, len(new.entries) + 1, built, structure_problems(new),
                  comparison + f"\nblocks compressed with {codec_label}", len(file), time.time() - started, out, file)


def render(r: Result, path: Path) -> str:
    b = r.built
    lines = [f"== {path.name}",
             f"objects: {r.before:,} -> {r.after:,} ({b.kept:,} entries of the archive and start frames kept, "
             f"{b.changed:,} current versions in {b.frames:,} later frames, {b.dropped:,} objects created and "
             f"removed during the mission left out)",
             f"frames: archive {b.history_index:,} (= NumArchivedFrames), start {b.history_index + 1:,} "
             f"(= HistoryStartIndex), then {b.frames:,} more",
             f"file: {r.file_bytes:,} bytes, {r.seconds:.0f} s",
             f"structure problems: {len(r.structure)}"]
    lines += [f"   {s}" for s in r.structure]
    lines.append(f"references to a dropped frame or context set to -1: {sum(b.nulled.values()):,}")
    lines += [f"   {n:,}  {cls}.{prop}" for (cls, prop), n in b.nulled.most_common(15)]
    lines.append(f"4-byte arrays copied unrenumbered (ints, or references the save cannot type): {sum(b.untyped.values()):,}")
    lines += [f"   {n:,}  {cls}.{prop}" for (cls, prop), n in b.untyped.most_common(15)]
    lines += ["", "Current state, original against archived:", r.comparison]
    if r.path:
        lines.append(f"wrote {r.path}")
    return "\n".join(lines)


# ---- command line ----------------------------------------------------------------------

def archive_save(source: Path) -> int:
    if not source.is_file():
        print(f"not a file: {source}")
        return 2
    stem = source.name if source.name.startswith("save_") else f"save_{source.name}"
    target = source.parent / f"{stem}_archived"
    try:
        result = run(source, None)
    except (ArchiveError, RefError, SmashError, HeaderError, HistoryError, ParseError, LzoError, ContainerError) as e:
        print(f"refused, nothing written: {e}")
        return 1
    if result.structure:
        print("refused, nothing written: the archived history failed its own checks:")
        for line in result.structure[:8]:
            print("  " + line)
        return 1
    print_reports([(source.name, source.read_bytes()), (f"{source.name}{LABEL}", result.file)], brief_after=True)
    print()
    print(render(result, source))
    target.write_bytes(result.file)
    print()
    print(f"Wrote {target.name}; it shows in the Load Game list with (archived) after its name.")
    print(f"Keep the original. Copy {target.name} into the SaveData folder to load it. Not every save has been tested.")
    return 0


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        sys.exit(2)
    sys.exit(archive_save(Path(sys.argv[1])))
