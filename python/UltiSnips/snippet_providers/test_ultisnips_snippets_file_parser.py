#!/usr/bin/env python
# encoding: utf-8

import unittest

from ultisnips_snippets_file_parser import *

class _SnippetFileParsing(object):
    ft = "all"
    filename = "test_file"
    file_content = None
    events = []

    def runTest(self):
        p = UltiSnipsSnippetsFileParser(self.ft, self.filename, self.file_content)
        p.parse()

        self.assertEqual(len(self.events), len(p.events))

        for i in range(len(self.events)):
            self.assertEqual(self.events[i][0], p.events[i].__class__)
            self.assertEqual(self.events[i][1], p.events[i].line_number)
            self.assertEqual(self.filename, p.events[i].filename)

class ParseSnippets_SimpleSnippet(_SnippetFileParsing, unittest.TestCase):
    file_content =  \
r"""
snippet testsnip "Test Snippet" b!
This is a test snippet!
endsnippet
"""
    events = [ (SnippetEvent, 1, { "ft": "all" }) ]


if __name__ == '__main__':
   unittest.main()

