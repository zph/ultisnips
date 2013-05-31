#!/usr/bin/env python
# encoding: utf-8

import re

__all__ = [
    "SyntaxErrorEvent", "SnippetEvent", "ExtendsEvent", "ClearSnippetsEvent",
    "UltiSnipsSnippetsFileParser"
]

# NOCOM(#sirver): think about this a bit more.
class FileParserEvent(object):
    def __init__(self, filename, line_number):
        self._filename = filename
        self._line_number = line_number

    @property
    def filename(self):
        return self._filename

    @property
    def line_number(self):
        return self._line_number

class SyntaxErrorEvent(FileParserEvent):
    def __init__(self, filename, line_number, error_text):
        FileParserEvent.__init__(self, filename, line_number)

        self._error_text = error_text

    @property
    def error_text(self):
        return self._error_text

class SnippetEvent(FileParserEvent):
    def __init__(self, filename, line_number, trigger, text, description, options, ft, global_texts):
        FileParserEvent.__init__(self, filename, line_number)
        self._trigger = trigger
        self._text = text
        self._description = description
        self._options = options
        self._ft = ft
        self._global_texts = text

    # NOCOM(#sirver): add getters for all of these
    @property
    def error_text(self):
        return self._text

class ExtendsEvent(FileParserEvent):
    def __init__(self, filename, line_number, extending_fts):
        FileParserEvent.__init__(self, filename, line_number)

        self._extending_fts = extending_fts

    # NOCOM(#sirver): does this indeed take multiple fts?
    @property
    def extending_fts(self):
        return self._extending_fts

class ClearSnippetsEvent(FileParserEvent):
    def __init__(self, filename, line_number, clearing_triggers):
        FileParserEvent.__init__(self, filename, line_number)
        self._clearing_triggers = clearing_triggers

    @property
    def clearing_triggers(self):
        return self._clearing_triggers

class UltiSnipsSnippetsFileParser(object):
    def __init__(self, ft, fn, injected_file_data_for_testing=None):
        self._events = []
        self._ft = ft
        self._fn = fn
        self._globals = {}
        if injected_file_data_for_testing is None:
            self._lines = open(fn).readlines()
        else:
            self._lines = injected_file_data_for_testing.splitlines(True)

        self._idx = 0

    @property
    def events(self):
        return self._events

    def _make_event(self, event_class, line_index, *args):
        self._events.append(
            event_class(self._fn, line_index, *args)
        )

    def _line(self):
        if self._idx < len(self._lines):
            line = self._lines[self._idx]
        else:
            line = ""
        return line

    def _line_head_tail(self):
        parts = re.split(r"\s+", self._line().rstrip(), maxsplit=1)
        parts.append('')
        return parts[:2]

    def _line_head(self):
        return self._line_head_tail()[0]

    def _line_tail(self):
        return self._line_head_tail()[1]

    def _goto_next_line(self):
        self._idx += 1
        return self._line()

    def _parse_first(self, line):
        """ Parses the first line of the snippet definition. Returns the
        snippet type, trigger, description, and options in a tuple in that
        order.
        """
        cdescr = ""
        coptions = ""
        cs = ""

        # Ensure this is a snippet
        snip = line.split()[0]

        # Get and strip options if they exist
        remain = line[len(snip):].strip()
        words = remain.split()
        if len(words) > 2:
            # second to last word ends with a quote
            if '"' not in words[-1] and words[-2][-1] == '"':
                coptions = words[-1]
                remain = remain[:-len(coptions) - 1].rstrip()

        # Get and strip description if it exists
        remain = remain.strip()
        if len(remain.split()) > 1 and remain[-1] == '"':
            left = remain[:-1].rfind('"')
            if left != -1 and left != 0:
                cdescr, remain = remain[left:], remain[:left]

        # The rest is the trigger
        cs = remain.strip()
        if len(cs.split()) > 1 or "r" in coptions:
            if cs[0] != cs[-1]:
                self._make_event(SyntaxErrorEvent, self._idx, "Invalid multiword trigger: '%s'" % cs)
                cs = ""
            else:
                cs = cs[1:-1]

        return (snip, cs, cdescr, coptions)

    # NOCOM(#sirver): pull this out of this file
    def _parse_snippet(self):
        starting_line_index = self._idx
        line = self._line()

        (snip, trig, description, options) = self._parse_first(line)
        end = "end" + snip
        cv = ""

        while self._goto_next_line():
            line = self._line()
            if line.rstrip() == end:
                cv = cv[:-1] # Chop the last newline
                break
            cv += line
        else:
            self._make_event(SyntaxErrorEvent, self._idx, "Missing 'endsnippet' for %r" % trig)
            return None

        if not trig:
            # there was an error
            return None
        elif snip == "global":
            # add snippet contents to file globals
            if trig not in self._globals:
                self._globals[trig] = []
            self._globals[trig].append(cv)
        elif snip == "snippet":
            self._make_event(SnippetEvent, starting_line_index, trig, cv,
                    description, options, self._ft, self._globals)
        else:
            self._make_event(SyntaxErrorEvent, self._idx, "Invalid snippet type: '%s'" % snip)

    def parse(self):
        while self._line():
            head, tail = self._line_head_tail()
            if head == "extends":
                if tail:
                    self._make_event(ExtendsEvent, [ p.strip() for p in tail.split(',') ], self._ft)
                else:
                    self._make_event(SyntaxErrorEvent, self._idx, "'extends' without file types")
            elif head in ("snippet", "global"):
                self._parse_snippet()
            elif head == "clearsnippets":
                self._make_event(ClearSnippetsEvent, tail.split(), self._ft)
            elif head and not head.startswith('#'):
                self._make_event(SyntaxErrorEvent, self._idx, "Invalid line %r" % self._line().rstrip())
                break
            self._goto_next_line()


