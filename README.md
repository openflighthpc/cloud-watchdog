# Overview

A bash script to be run daily to shutdown any instances left running and notifying developers of what has been done. 

## Setup

Copy `settings.sh.example` to `settings.sh` and set values. 

## Prevent Watchdog From Shutting Down

Add `WatchdogIgnore` tag to an instance and set the value to `true`.
