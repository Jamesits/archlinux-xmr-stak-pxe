#!/usr/bin/env python3

import hug

@hug.static('/xmr-stak')
def config_stor():
    return ("config", )

@hug.static('/static')
def pxe_stor():
    return ("release", )

@hug.get("/", output=hug.output_format.text)
def bootfiles(**kwargs):
	with open("release/boot.cfg", "r") as bootcfg:
		return bootcfg.read()

