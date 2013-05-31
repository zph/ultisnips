#!/usr/bin/env python
# encoding: utf-8

from collections import defaultdict

class ManuallyAddedSnippets_SnippetProvider(object):
    """The list of manually added snippets."""
    # NOCOM(#sirver): this comment is not very good.

    def __init__(self):
        self._snippets = []

    def add_snippet(self, snippet):
        self._snippets = .append(snippet)

    # NOCOM(#sirver): this is copy and pasted
    def get_matching_snippets(self, trigger, potentially):
        """Returns all snippets matching the given trigger."""
        if not potentially:
            return [ s for s in self._snippets if s.matches(trigger) ]
        else:
            return [ s for s in self._snippets if s.could_match(trigger) ]

# NOCOM(#sirver): would be nice to get rid of this class again.
class _SnippetDictionary(object):
    def __init__(self, *args, **kwargs):
        self._added = []
        self.reset()

    def add_snippet(self, s, fn=None):
        if fn:
            self._snippets.append(s)

            if fn not in self.files:
                self.addfile(fn)
        else:
            self._added.append(s)

    def get_matching_snippets(self, trigger, potentially):
        """Returns all snippets matching the given trigger."""
        if not potentially:
            return [ s for s in self.snippets if s.matches(trigger) ]
        else:
            return [ s for s in self.snippets if s.could_match(trigger) ]

    @property
    def snippets(self):
        return self._added + self._snippets

    def clear_snippets(self, triggers=[]):
        """Remove all snippets that match each trigger in triggers.
            When triggers is empty, removes all snippets.
        """
        if triggers:
            for t in triggers:
                for s in self.get_matching_snippets(t, potentially=False):
                    if s in self._snippets:
                        self._snippets.remove(s)
                    if s in self._added:
                        self._added.remove(s)
        else:
            self._snippets = []
            self._added = []

    @property
    def files(self):
        return self._files

    def reset(self):
        self._snippets = []
        self._extends = []
        self._files = {}


    def _hash(self, path):
        if not os.path.isfile(path):
            return False

        return hashlib.sha1(open(path, "rb").read()).hexdigest()

    def addfile(self, path):
        self.files[path] = self._hash(path)

    def needs_update(self):
        for path, hash in self.files.items():
            if not hash or hash != self._hash(path):
                return True
        return False

    def extends():
        def fget(self):
            return self._extends
        def fset(self, value):
            self._extends = value
        return locals()
    extends = property(**extends())


class UltiSnips_SnippetProvider(object):
    """Searches and parses UltiSnips snippet files."""

    def __init__(self):
        pass

    def get_matching_snippets(self, trigger, potentially):
        snips = self._snippets.get(ft,None)
        if not snips:
            return []

        if not seen:
            seen = []
        seen.append(ft)

        parent_results = []

        for p in snips.extends:
            if p not in seen:
                seen.append(p)
                parent_results += self._find_snippets(p, trigger,
                        potentially, seen)

        return parent_results + snips.get_matching_snippets(
            trigger, potentially)


    def _load_snippets_for(self, ft):
        self._snippets[ft].reset()

        for fn in snippet_files_for(ft):
            self._parse_snippets(ft, fn)

        # Now load for the parents
        for p in self._snippets[ft].extends:
            if p not in self._snippets:
                self._load_snippets_for(p)

    # Loading
    def _parse_snippets(self, ft, fn, file_data=None):
        # This is a separate method for testing.
        # NOCOM(#sirver): this should get proper unit tests instead of testing it from the end-to-end tests.
        self._snippets[ft].addfile(path)
        _SnippetsFileParser(ft, fn, self, file_data).parse()


    def _needs_update(self, ft):
        # NOCOM(#sirver): remove this g:UltiSnipsDoHash. we always want to hash.
        do_hash = _vim.eval('exists("g:UltiSnipsDoHash")') == "0" \
                or _vim.eval("g:UltiSnipsDoHash") != "0"

        if ft not in self._snippets:
            return True
        elif do_hash and self._snippets[ft].needs_update():
            return True
        elif do_hash:
            cur_snips = set(snippet_files_for(ft))
            old_snips = set(self._snippets[ft].files)

            if cur_snips - old_snips:
                return True

        return False

    def _ensure_all_loaded(self):
        # NOCOM(#sirver): try to peel these methods out into a SnippetProvider
        for ft in self._filetypes[_vim.buf.nr]:
            self._ensure_loaded(ft)

    def _ensure_loaded(self, ft, checked=None):
        if not checked:
            checked = set([ft])
        elif ft in checked:
            return
        else:
            checked.add(ft)

        if self._needs_update(ft):
            self._load_snippets_for(ft)

        for parent in self._snippets[ft].extends:
            self._ensure_loaded(parent, checked)

    def _find_snippets(self, ft, trigger, potentially = False, seen=None):
        """
        Find snippets matching trigger

        ft          - file type to search
        trigger     - trigger to match against
        potentially - also returns snippets that could potentially match; that
                      is which triggers start with the current trigger
        """
        snips = self._snippets.get(ft,None)
        if not snips:
            return []

        if not seen:
            seen = []
        seen.append(ft)

        parent_results = []

        for p in snips.extends:
            if p not in seen:
                seen.append(p)
                parent_results += self._find_snippets(p, trigger,
                        potentially, seen)

        return parent_results + snips.get_matching_snippets(
            trigger, potentially)
