#!/bin/bash
# Debug: dump every Meet element whose aria-label mentions share / present /
# stop / presenting. Useful when `meetctl present` can't find the toggle
# button because Meet's UI renamed it.
#
# Usage: run once while idle, once while sharing, to see how labels change.

exec meetctl eval 'JSON.stringify(
    Array.from(document.querySelectorAll("[aria-label]"))
        .filter(e => /present|share|stop/i.test(e.getAttribute("aria-label")))
        .map(e => ({
            tag: e.tagName,
            role: e.getAttribute("role") || "-",
            label: e.getAttribute("aria-label"),
        })),
    null, 2
)'
