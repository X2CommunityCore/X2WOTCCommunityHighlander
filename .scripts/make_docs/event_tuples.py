from enum import Enum
from typing import Iterator, List, Optional, Tuple
import re


class _TokenType(Enum):
    LPAREN = 1
    RPAREN = 2
    LBRACE = 3
    RBRACE = 4
    LBRACK = 5
    RBRACK = 6
    KW = 7
    IDENT = 8
    COMMA = 9
    COLON = 10


class _Keyword(Enum):
    IN = 1
    OUT = 2
    INOUT = 3


class InOutness(Enum):
    IN = 1
    OUT = 2
    INOUT = 3

    def is_in(self) -> bool:
        return self in [InOutness.IN, InOutness.INOUT]

    def is_out(self) -> bool:
        return self in [InOutness.OUT, InOutness.INOUT]

    def __str__(self) -> str:
        if self == InOutness.IN:
            return "in"
        elif self == InOutness.OUT:
            return "out"
        elif self == InOutness.INOUT:
            return "inout"
        else:
            assert False, "unreachable"


class NewGameState(Enum):
    YES = 1
    NO = 2
    MAYBE = 3

    def __str__(self) -> str:
        if self == NewGameState.YES:
            return "yes"
        elif self == NewGameState.NO:
            return "no"
        elif self == NewGameState.MAYBE:
            return "sometimes"
        else:
            assert False, "unreachable"


class _Token:
    def __init__(self, type: _TokenType):
        self.type = type

    def __str__(self):
        buf = str(self.type)
        if self.type == _TokenType.KW:
            buf += f" ({self.kw})"
        elif self.type == _TokenType.IDENT:
            buf += f" ({self.ident})"
        return buf


_PUNCTUATION = {
    "(": _Token(_TokenType.LPAREN),
    ")": _Token(_TokenType.RPAREN),
    "{": _Token(_TokenType.LBRACE),
    "}": _Token(_TokenType.RBRACE),
    "[": _Token(_TokenType.LBRACK),
    "]": _Token(_TokenType.RBRACK),
    ",": _Token(_TokenType.COMMA),
    ":": _Token(_TokenType.COLON),
}

_KWS = {
    "in": _Keyword.IN,
    "out": _Keyword.OUT,
    "inout": _Keyword.INOUT,
}

_STARTIDENTCHAR = re.compile(r"[A-Za-z]")
_IDENTCHAR = re.compile(r"[A-Za-z0-9\-_<>]")


class ParseError(Exception):
    def __init__(self, msg: str):
        self.msg = msg


def _ident(pos: int, text: str, first: str) -> (int, str):
    while pos < len(text) and _IDENTCHAR.match(text[pos]):
        first += text[pos]
        pos += 1

    return (pos, first)


def _lex_event_spec(text: str) -> Iterator[_Token]:
    pos = 0
    while pos < len(text):
        c = text[pos]
        pos += 1

        if c.isspace():
            continue

        if c in _PUNCTUATION:
            yield _PUNCTUATION[c]
            continue

        if _STARTIDENTCHAR.match(c):
            (pos, id) = _ident(pos, text, c)
            if id in _KWS:
                tok = _Token(_TokenType.KW)
                tok.kw = _KWS[id]
            else:
                tok = _Token(_TokenType.IDENT)
                tok.ident = id
            yield tok
            continue

        raise ParseError(f"unknown start of token {c}")
        return


def _expect(it, t: _TokenType) -> _Token:
    n = next(it)
    if n is None:
        raise ParseError(f"expected {str(t)} but doc comment ended")

    if n.type != t:
        raise ParseError(f"expected {str(t)}, found {str(n)}")

    return n

def _try_eat(it, t: _TokenType) -> _Token:
    if it and it.peek.type == t:
        return next(it)
    return None
    


def _kw_to_inout(t: _Token) -> InOutness:
    if t.kw == _Keyword.IN:
        return InOutness.IN
    elif t.kw == _Keyword.OUT:
        return InOutness.OUT
    elif t.kw == _Keyword.INOUT:
        return InOutness.INOUT


class _peekable():
    "Wrap iterator with lookahead to both peek and test exhausted"
    # https://mail.python.org/pipermail//python-ideas/2013-February/019633.html
    _NONE = object()

    def __init__(self, iterable):
        self._it = iter(iterable)
        self._set_peek()

    def __iter__(self):
        return self

    def __next__(self):
        if self:
            ret = self.peek
            self._set_peek()
            return ret
        else:
            raise StopIteration()

    def _set_peek(self):
        try:
            self.peek = next(self._it)
        except StopIteration:
            self.peek = self._NONE

    def __bool__(self):
        return self.peek is not self._NONE


def _parse_type_sig(lex) -> (InOutness, str, str, Optional[str]):
    """
    "inout bool bShow" -> (InOutness.INOUT, "bool", "bShow", None)
    "in enum[EInventorySlot] Slot" -> (InOutness.IN, "enum", "Slot", "EInventorySlot")
    """
    param_kind = _kw_to_inout(_expect(lex, _TokenType.KW))
    tup_type = _expect(lex, _TokenType.IDENT).ident
    local_type = None
    if _try_eat(lex, _TokenType.LBRACK):
        local_type = _expect(lex, _TokenType.IDENT).ident
        _expect(lex, _TokenType.RBRACK)
    name = _expect(lex, _TokenType.IDENT)
    return param_kind, tup_type, name.ident, local_type


def _parse_tuple_data(lex) -> List[Tuple]:
    _expect(lex, _TokenType.LBRACK)

    tup = []
    comma = False

    while True:
        if _try_eat(lex, _TokenType.RBRACK):
            break
        if comma:
            _expect(lex, _TokenType.COMMA)
        comma = True
        if _try_eat(lex, _TokenType.RBRACK):
            break
        tup.append(_parse_type_sig(lex))

    return tup


def _parse_tuple(lex) -> List[Tuple]:
    _expect(lex, _TokenType.LBRACE)

    data = _expect(lex, _TokenType.IDENT)
    if data.ident != "Data":
        raise ParseError(f"expected \"Data\", got {data}")

    _expect(lex, _TokenType.COLON)
    tup = _parse_tuple_data(lex)
    _try_eat(lex, _TokenType.COMMA)
    _expect(lex, _TokenType.RBRACE)
    return tup


def parse_event_spec(text: str) -> dict:
    lex = _peekable(_lex_event_spec(text))

    spec = dict()
    comma = False

    while True:
        if not lex:
            break
        if comma:
            _expect(lex, _TokenType.COMMA)
        if not lex:
            break
        comma = True
        key = _expect(lex, _TokenType.IDENT).ident
        _expect(lex, _TokenType.COLON)
        if key in spec:
            raise ParseError(f"error, duplicate key {key}")
        elif key == "EventID":
            name = _expect(lex, _TokenType.IDENT)
            spec[key] = name.ident
        elif key == "EventSource":
            type = _expect(lex, _TokenType.IDENT)
            spec[key] = {"type": type.ident}
            if _try_eat(lex, _TokenType.LPAREN):
                name = _expect(lex, _TokenType.IDENT)
                spec[key]["name"] = name.ident
                _expect(lex, _TokenType.RPAREN)
        elif key == "EventData":
            if lex and lex.peek.type == _TokenType.LBRACK:
                tup = _parse_tuple_data(lex)
                spec[key] = {"type": "XComLWTuple", "tuple": tup}
            else:
                type = _expect(lex, _TokenType.IDENT)
                spec[key] = {"type": type.ident}
                if type.ident == "XComLWTuple":
                    tup = _parse_tuple(lex)
                    spec[key]["tuple"] = tup
                else:
                    if _try_eat(lex, _TokenType.LPAREN):
                        name = _expect(lex, _TokenType.IDENT)
                        spec[key]["name"] = name.ident
                        _expect(lex, _TokenType.RPAREN)
        elif key == "NewGameState":
            b = _expect(lex, _TokenType.IDENT).ident
            if b == "yes":
                spec[key] = NewGameState.YES
            elif b == "no":
                spec[key] = NewGameState.NO
            elif b == "maybe":
                spec[key] = NewGameState.MAYBE
            else:
                raise ParseError(f"expected yes, no, or maybe")
        else:
            raise ParseError(
                f"unexpected key (expected EventID, EventSource, EventData, NewGameState)"
            )

    if not "EventSource" in spec:
        spec["EventSource"] = {"type": "None"}
    if not "NewGameState" in spec:
        spec["NewGameState"] = NewGameState.NO

    return spec


def replace_event_specifications(text: str) -> str:
    pass
