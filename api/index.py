"""Vercel Python Function entry point for the CleanNow API."""

import threading
from urllib.parse import parse_qs, urlencode, urlparse

from server.clean_now_api import Handler, initialize


_initialized = False
_initialize_lock = threading.Lock()


def _ensure_initialized():
    global _initialized
    if _initialized:
        return
    with _initialize_lock:
        if not _initialized:
            initialize()
            _initialized = True


class handler(Handler):
    def _prepare_request(self):
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query, keep_blank_values=True)
        forwarded_path = query.pop("__path", [None])[0]
        if forwarded_path is not None:
            self.path = f"/api/{forwarded_path.lstrip('/')}"
            remaining_query = urlencode(query, doseq=True)
            if remaining_query:
                self.path += f"?{remaining_query}"

    def _run(self, method):
        self._prepare_request()
        try:
            _ensure_initialized()
        except Exception as error:
            return self.reply(500, {
                "error": "Backend initialization failed",
                "detail": f"{type(error).__name__}: {error}",
            })
        return method(self)

    def do_GET(self):
        return self._run(Handler.do_GET)

    def do_POST(self):
        return self._run(Handler.do_POST)

    def do_PATCH(self):
        return self._run(Handler.do_PATCH)

    def do_DELETE(self):
        return self._run(Handler.do_DELETE)
