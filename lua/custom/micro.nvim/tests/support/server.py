#!/usr/bin/env python3
"""Scripted stdio LSP server for the completion specs.

Options (JSON argv[1]): label, snippet, import, resolve_import, empty, never_reply,
delays (per-completion-request ms, last repeats), incomplete, cancel_error,
log (file path; one line appended per textDocument/completion request received).
It deliberately replies after $/cancelRequest unless cancel_error is set.
"""
import json, re, sys, threading

opts = json.loads(sys.argv[1])
lock = threading.Lock()
docs, cancelled, count = {}, set(), 0
DOC = "\n".join(["Probe documentation"] + [f"line {i:02}" for i in range(2, 60)])


def send(message):
    data = json.dumps(message).encode()
    with lock:
        sys.stdout.buffer.write(f"Content-Length: {len(data)}\r\n\r\n".encode() + data)
        sys.stdout.buffer.flush()


def edit(text):
    zero = {"line": 0, "character": 0}
    return [{"range": {"start": zero, "end": zero}, "newText": text}]


def completion(req):
    pos = req["params"]["position"]
    line = docs.get(req["params"]["textDocument"]["uri"], "").split("\n")[pos["line"]]
    prefix = line.encode("utf-16-le")[: pos["character"] * 2].decode("utf-16-le")
    start = len(prefix[: re.search(r"\w*$", prefix).start()].encode("utf-16-le")) // 2
    snippet = opts.get("snippet")
    label = opts.get("label", "LspCall" if snippet else "LspThing")
    item = {
        "label": label, "kind": 3, "insertTextFormat": 2 if snippet else 1, "data": {"probe": True},
        "textEdit": {"range": {"start": {"line": pos["line"], "character": start}, "end": pos},
                     "newText": "LspCall(${1:arg})$0" if snippet else label},
    }
    if opts.get("import"):
        item["additionalTextEdits"] = edit("import LspThing\n")
    return {"isIncomplete": bool(opts.get("incomplete")), "items": [] if opts.get("empty") else [item]}


def reply(req):
    method, params = req["method"], req.get("params", {})
    result = None
    if method == "initialize":
        result = {"capabilities": {"textDocumentSync": 1,
                  "completionProvider": {"resolveProvider": True, "triggerCharacters": [".", "/"]}}}
    elif method == "textDocument/completion":
        if req["id"] in cancelled and opts.get("cancel_error"):
            return send({"jsonrpc": "2.0", "id": req["id"], "error": {"code": -32800, "message": "cancelled"}})
        result = completion(req)
    elif method == "completionItem/resolve":
        result = dict(params, documentation={"kind": "plaintext", "value": DOC})
        if opts.get("resolve_import"):
            result["additionalTextEdits"] = edit("import ResolvedThing\n")
    send({"jsonrpc": "2.0", "id": req["id"], "result": result})


while True:
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            raise SystemExit(0)
        if line == b"\r\n":
            break
        k, v = line.decode().split(":", 1)
        headers[k.lower()] = v.strip()
    req = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
    method, params = req.get("method"), req.get("params", {})
    if method == "exit":
        break
    if method == "$/cancelRequest":
        cancelled.add(params["id"])
    elif method == "textDocument/didOpen":
        docs[params["textDocument"]["uri"]] = params["textDocument"]["text"]
    elif method == "textDocument/didChange":
        docs[params["textDocument"]["uri"]] = params["contentChanges"][-1]["text"]
    if "id" not in req:
        continue
    delay = 0
    if method == "textDocument/completion":
        if opts.get("log"):
            with open(opts["log"], "a") as f:
                f.write("completion\n")
        if opts.get("never_reply"):
            continue
        delays = opts.get("delays", [40])
        delay = delays[min(count, len(delays) - 1)] / 1000
        count += 1
    threading.Timer(delay, reply, [req]).start()
