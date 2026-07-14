"""Vercel Python Function entry point for the CleanNow API."""

from server.clean_now_api import Handler, initialize


# A function instance can handle multiple requests, so initialize once when a
# new instance starts. All statements are idempotent and the data is stored in
# Turso rather than on Vercel's temporary filesystem.
initialize()


class handler(Handler):
    pass
