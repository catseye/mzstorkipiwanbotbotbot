#!/bin/sh
R --no-restore --no-save --no-readline --slave --file=bot.R --args $*
