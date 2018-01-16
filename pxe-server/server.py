#!/usr/bin/env python3

import hug
import requests

@hug.static('/static')
def my_static_dirs():
    return ("release", )

@hug.get("/", output=hug.output_format.text)
def bootfiles(**kwargs):
	with open("release/boot.cfg", "r") as bootcfg:
		return bootcfg.read()

