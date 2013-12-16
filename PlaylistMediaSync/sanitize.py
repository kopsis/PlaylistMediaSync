#!/usr/bin/env python

import re
import sys

invalidChars = "[<>:\"/\\|?*\x00-\x1F]{1}"
badEnding = r"[ .]+$"
badStart = r"(?:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])[:.]+"

text = sys.argv[1]
if text != None:
	text = text.encode('cp1252')
	text = re.sub(badStart, 'X', text)
	text = re.sub(badEnding, '_', text)
	text = re.sub(invalidChars, '_', text)
	print(text)

