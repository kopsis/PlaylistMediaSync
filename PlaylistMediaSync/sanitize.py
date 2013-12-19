#!/usr/bin/env python

# Copyright (c) 2013, David J. Kessler <dkessler@acm.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

import re
import sys

invalidChars = "[<>:\"/\\|?*\x00-\x1F]{1}"
badEnding = r"[ .]+$"
badStart = r"(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])[:.]+"

text = unicode(sys.argv[1], 'utf_8')
if text != None:
	text = text.encode('cp1252', 'replace')
	text = re.sub(badStart, 'X', text)
	text = re.sub(badEnding, '_', text)
	text = re.sub(invalidChars, '_', text)
	print(text)

