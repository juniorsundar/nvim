#!/usr/bin/env python3
"""Scripted stdio LSP server for the completion specs.

Options (JSON argv[1]): label, kind (LSP CompletionItemKind, default 3), snippet, import, resolve_import, empty, never_reply,
delays (per-completion-request ms, last repeats), incomplete,
log (file path; one line appended per textDocument/completion request received),
dynamic (as lua-language-server does: when the client advertises dynamic completion registration, omit completionProvider from initialize and register it afterwards),
cwd_log (file path; the working directory is written once, at initialize),
hover (advertise hoverProvider; reply markdown "<hover> @line:char", or null when ""),
symbols (advertise documentSymbolProvider; reply with this list), symbols_changed (reply with this list
instead once the document has changed; the reply reflects the text at the time the request arrived),
encoding (positionEncoding to pick from the client's offer), reply_delays (per hover/symbols request ms,
last repeats). `log` also gets one line per hover/symbols request.
It deliberately replies after $/cancelRequest.
"""
import json, os, re, sys, threading

opts = json.loads(sys.argv[1])
lock = threading.Lock()
docs, count, other, changed = {}, 0, 0, False
FEATURES = {"textDocument/hover": "hover", "textDocument/documentSymbol": "symbols"}
dynamic = False
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
        "label": label, "kind": opts.get("kind", 3), "insertTextFormat": 2 if snippet else 1, "data": {"probe": True},
        "textEdit": {"range": {"start": {"line": pos["line"], "character": start}, "end": pos},
                     "newText": "LspCall(${1:arg})$0" if snippet else label},
    }
    if opts.get("import"):
        item["additionalTextEdits"] = edit("import LspThing\n")
    return {"isIncomplete": bool(opts.get("incomplete")), "items": [] if opts.get("empty") else [item]}


def reply(req):
    global dynamic
    method, params = req["method"], req.get("params", {})
    result = None
    if method == "initialize":
        if opts.get("cwd_log"):
            with open(opts["cwd_log"], "w") as f:
                f.write(os.getcwd())
        caps = {"textDocumentSync": 1}
        client = params.get("capabilities", {}).get("textDocument", {}).get("completion", {})
        dynamic = bool(opts.get("dynamic") and client.get("dynamicRegistration"))
        if not dynamic:
            caps["completionProvider"] = {"resolveProvider": True, "triggerCharacters": [".", "/"]}
        if "hover" in opts:
            caps["hoverProvider"] = True
        if "symbols" in opts:
            caps["documentSymbolProvider"] = True
        if opts.get("encoding"):
            caps["positionEncoding"] = opts["encoding"]
        result = {"capabilities": caps}
    elif method == "textDocument/completion":
        result = completion(req)
    elif method == "textDocument/hover":
        pos = params["position"]
        if opts["hover"]:
            result = {"contents": {"kind": "markdown", "value": f'{opts["hover"]} @{pos["line"]}:{pos["character"]}'}}
    elif method == "textDocument/documentSymbol":
        result = opts["symbols_changed"] if req.get("changed") and "symbols_changed" in opts else opts["symbols"]
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
    if method == "textDocument/didOpen":
        docs[params["textDocument"]["uri"]] = params["textDocument"]["text"]
    elif method == "textDocument/didChange":
        docs[params["textDocument"]["uri"]] = params["contentChanges"][-1]["text"]
        changed = True
    if method == "initialized" and dynamic:
        send({"jsonrpc": "2.0", "id": "reg", "method": "client/registerCapability", "params": {"registrations": [
            {"id": "c", "method": "textDocument/completion",
             "registerOptions": {"resolveProvider": True, "triggerCharacters": [".", "/"]}}]}})
    if "id" not in req or method is None:  # notifications, and the client's reply to our request
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
    elif method in FEATURES:
        req["changed"] = changed
        if opts.get("log"):
            with open(opts["log"], "a") as f:
                f.write(FEATURES[method] + "\n")
        delays = opts.get("reply_delays", [0])
        delay = delays[min(other, len(delays) - 1)] / 1000
        other += 1
    threading.Timer(delay, reply, [req]).start()
