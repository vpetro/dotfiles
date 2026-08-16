// meetctl — control Google Meet via Chrome DevTools Protocol.
//
// Connects to a Chrome-for-Meet instance launched by the `chrome-for-meet`
// wrapper (which in turn is invoked from Hammerspoon's urlhandler when any
// meet.google.com URL is opened). Communicates with Chrome over CDP on
// localhost:9222 — no extension, no native messaging host, no external
// click-synthesis tools.
//
// Usage:
//
//	meetctl status                 show mic/camera/presenting state
//	meetctl mute                   toggle the mic
//	meetctl camera                 toggle the camera
//	meetctl present                toggle entire-screen sharing (no picker)
//	meetctl present-screen         alias of `present`
//	meetctl jump                   focus the Meet tab + Chrome window
//	meetctl new [URL]              open a new pre-muted meeting
//	meetctl ping                   liveness check
//
// Output is one-line JSON. Exit codes: 0 ok, 2 CDP/page error,
// 3 CDP port unreachable.
package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/gorilla/websocket"
)

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const (
	cdpHost   = "localhost"
	cdpPort   = 9222
	httpPause = 3 * time.Second // budget for /json/* HTTP calls
	wsPause   = 10 * time.Second // budget for a single CDP method
)

// ---------------------------------------------------------------------------
// CDP transport
// ---------------------------------------------------------------------------

// target is a subset of Chrome's /json/list entry shape.
type target struct {
	ID    string `json:"id"`
	Type  string `json:"type"`
	URL   string `json:"url"`
	Title string `json:"title"`
	WSURL string `json:"webSocketDebuggerUrl"`
}

// httpJSON issues a GET to localhost:9222<path> and decodes the JSON body.
func httpJSON(path string, out any) error {
	url := fmt.Sprintf("http://%s:%d%s", cdpHost, cdpPort, path)
	client := &http.Client{Timeout: httpPause}
	resp, err := client.Get(url)
	if err != nil {
		return fmt.Errorf("GET %s: %w", url, err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read body: %w", err)
	}
	if resp.StatusCode != 200 {
		return fmt.Errorf("GET %s: status %d: %s", url, resp.StatusCode, body)
	}
	return json.Unmarshal(body, out)
}

// findMeetTarget returns the first open page target whose URL is on
// meet.google.com, or nil if none is open.
func findMeetTarget() (*target, error) {
	ts, err := listTargets()
	if err != nil {
		return nil, err
	}
	for i := range ts {
		if ts[i].Type == "page" && strings.Contains(ts[i].URL, "meet.google.com") {
			return &ts[i], nil
		}
	}
	return nil, nil
}

// listTargets returns every page/worker target currently known to Chrome.
func listTargets() ([]target, error) {
	var ts []target
	if err := httpJSON("/json/list", &ts); err != nil {
		return nil, err
	}
	return ts, nil
}

// browserWSURL returns the root CDP WebSocket URL (used for browser-level
// commands like Target.createTarget).
func browserWSURL() (string, error) {
	var info struct {
		WebSocketDebuggerURL string `json:"webSocketDebuggerUrl"`
	}
	if err := httpJSON("/json/version", &info); err != nil {
		return "", err
	}
	if info.WebSocketDebuggerURL == "" {
		return "", errors.New("browser webSocketDebuggerUrl missing from /json/version")
	}
	return info.WebSocketDebuggerURL, nil
}

// cdpRequest is the JSON shape of a CDP method call.
type cdpRequest struct {
	ID     int            `json:"id"`
	Method string         `json:"method"`
	Params map[string]any `json:"params,omitempty"`
}

// cdpResponse is the JSON shape of a CDP reply.
type cdpResponse struct {
	ID     int             `json:"id"`
	Result json.RawMessage `json:"result,omitempty"`
	Error  *cdpError       `json:"error,omitempty"`
}

type cdpError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (e *cdpError) Error() string {
	return fmt.Sprintf("CDP error %d: %s", e.Code, e.Message)
}

// cdpCall opens a short-lived WebSocket, sends one method, and returns its
// raw result. The connection is closed on return. Ignores unsolicited
// events (which Chrome may send before the reply).
func cdpCall(wsURL, method string, params map[string]any) (json.RawMessage, error) {
	dialer := websocket.Dialer{HandshakeTimeout: httpPause}
	conn, _, err := dialer.Dial(wsURL, nil)
	if err != nil {
		return nil, fmt.Errorf("ws dial %s: %w", wsURL, err)
	}
	defer conn.Close()

	req := cdpRequest{ID: 1, Method: method, Params: params}
	if err := conn.WriteJSON(req); err != nil {
		return nil, fmt.Errorf("ws write: %w", err)
	}

	deadline := time.Now().Add(wsPause)
	for time.Now().Before(deadline) {
		if err := conn.SetReadDeadline(time.Now().Add(wsPause)); err != nil {
			return nil, err
		}
		var resp cdpResponse
		if err := conn.ReadJSON(&resp); err != nil {
			return nil, fmt.Errorf("ws read: %w", err)
		}
		if resp.ID != req.ID {
			// unsolicited event — ignore and keep reading
			continue
		}
		if resp.Error != nil {
			return nil, resp.Error
		}
		return resp.Result, nil
	}
	return nil, fmt.Errorf("CDP %s: timed out", method)
}

// evalInTab runs a JS expression in the page and returns its value, decoded
// into out (which should be a pointer to a struct or map that matches the
// expression's return shape).
func evalInTab(t *target, expression string, userGesture bool, out any) error {
	raw, err := cdpCall(t.WSURL, "Runtime.evaluate", map[string]any{
		"expression":    expression,
		"returnByValue": true,
		"userGesture":   userGesture,
		"awaitPromise":  true,
	})
	if err != nil {
		return err
	}
	var r struct {
		Result struct {
			Value            json.RawMessage `json:"value"`
			UnserializableValue string        `json:"unserializableValue,omitempty"`
		} `json:"result"`
		ExceptionDetails *struct {
			Text string `json:"text"`
		} `json:"exceptionDetails,omitempty"`
	}
	if err := json.Unmarshal(raw, &r); err != nil {
		return fmt.Errorf("decode Runtime.evaluate result: %w", err)
	}
	if r.ExceptionDetails != nil {
		return fmt.Errorf("page JS error: %s", r.ExceptionDetails.Text)
	}
	if out == nil {
		return nil
	}
	if len(r.Result.Value) == 0 {
		return nil
	}
	return json.Unmarshal(r.Result.Value, out)
}

// ---------------------------------------------------------------------------
// JS payloads injected into the Meet page
// ---------------------------------------------------------------------------

// Reads mic/camera/presenting state from the DOM.
const jsState = `(function(){
	const labelState = (sel) => {
		const el = document.querySelector(sel);
		if (!el) return "unknown";
		const l = (el.getAttribute("aria-label") || "").toLowerCase();
		if (l.startsWith("turn off")) return "on";
		if (l.startsWith("turn on"))  return "off";
		return "unknown";
	};
	const presentBtn = document.querySelector(
		'[aria-label*="present" i], [aria-label*="share screen" i], [aria-label*="stop sharing" i]'
	);
	const presenting = !!presentBtn
		&& /stop|you are/i.test(presentBtn.getAttribute("aria-label") || "");
	return {
		mic: labelState('[aria-label*="microphone" i]'),
		camera: labelState('[aria-label*="camera" i]'),
		presenting,
		url: location.href,
		title: document.title,
	};
})()`

// jsClick returns a JS snippet that clicks the first element whose
// aria-label contains the given fragment (case-insensitive). The returned
// expression evaluates to {clicked: true} or {error: "..."}.
func jsClick(labelFragment string) string {
	// Single-quote escape for JS literal.
	esc := strings.ReplaceAll(labelFragment, `'`, `\'`)
	return fmt.Sprintf(`(function(){
		const btn = document.querySelector('[aria-label*="%s" i]');
		if (!btn) return {error: "no matching button"};
		btn.click();
		return {clicked: true};
	})()`, esc)
}

// ---------------------------------------------------------------------------
// Command handlers
// ---------------------------------------------------------------------------

type meetState struct {
	Mic        string `json:"mic"`
	Camera     string `json:"camera"`
	Presenting bool   `json:"presenting"`
	URL        string `json:"url"`
	Title      string `json:"title"`
}

func cmdPing() {
	var info struct {
		Browser              string `json:"Browser"`
		WebSocketDebuggerURL string `json:"webSocketDebuggerUrl"`
	}
	if err := httpJSON("/json/version", &info); err != nil {
		die(3, "meetctl: can't reach Chrome DevTools on %d: %v\n"+
			"  Is Chrome-for-Meet running? Open any meet.google.com link first.", cdpPort, err)
	}
	printJSON(map[string]any{
		"browser": info.Browser,
		"cdpPort": cdpPort,
	})
}

func cmdStatus() {
	t := mustFindMeetTarget()
	var state meetState
	must(evalInTab(t, jsState, false, &state))
	printJSON(map[string]any{
		"mic":        state.Mic,
		"camera":     state.Camera,
		"presenting": state.Presenting,
		"url":        state.URL,
		"title":      state.Title,
		"tabId":      t.ID,
	})
}

func cmdMute()   { toggleTrack("microphone", "mic") }
func cmdCamera() { toggleTrack("camera", "camera") }

func toggleTrack(labelFragment, stateKey string) {
	t := mustFindMeetTarget()

	var click struct {
		Clicked bool   `json:"clicked"`
		Error   string `json:"error"`
	}
	must(evalInTab(t, jsClick(labelFragment), true, &click))
	if click.Error != "" {
		die(2, "meetctl: %s", click.Error)
	}

	time.Sleep(120 * time.Millisecond)

	var state meetState
	must(evalInTab(t, jsState, false, &state))

	out := map[string]any{}
	switch stateKey {
	case "mic":
		out["mic"] = state.Mic
	case "camera":
		out["camera"] = state.Camera
	}
	printJSON(out)
}

// jsTogglePresent toggles Meet's screen-sharing state. Meet's UI has two
// shapes we need to handle:
//
//  IDLE:    the toolbar shows a single "Share screen" button. One click
//           starts sharing (the launch flag auto-selects entire screen).
//
//  ACTIVE:  the toolbar shows a "You are presenting" dropdown button.
//           One click opens a submenu with "Stop sharing" and "Present
//           something else". We have to click the submenu item.
//
// Returns a Promise because the active-state path polls briefly for the
// submenu to render.
const jsTogglePresent = `(function(){
	const find = (selectors) => {
		for (const s of selectors) {
			const el = document.querySelector(s);
			if (el) return el;
		}
		return null;
	};

	// Case 1: IDLE -- start sharing.
	const startBtn = find([
		'[aria-label*="share screen" i][role="button"]',
		'[aria-label*="share a tab" i][role="button"]',
		'[aria-label*="present now" i][role="button"]',
	]);
	if (startBtn) {
		startBtn.click();
		return {action: "sharing entire screen", label: startBtn.getAttribute("aria-label")};
	}

	// Case 2: ACTIVE -- open the "You are presenting" dropdown, then click
	// its "Stop sharing" item.
	const activeBtn = find([
		'[aria-label*="you are presenting" i][role="button"]',
		'[aria-label*="stop presenting" i][role="button"]',
		'[aria-label*="stop sharing" i][role="button"]',
	]);
	if (!activeBtn) {
		return {error: "no share/present button found (idle or active)"};
	}
	activeBtn.click();

	return new Promise((resolve) => {
		const deadline = Date.now() + 1500;
		const tick = () => {
			// The submenu's "Stop sharing" item has visible text "Stop sharing"
			// and is clickable. Match broadly on text.
			const items = Array.from(document.querySelectorAll(
				'[role="menuitem"], [role="menuitemradio"], button, [role="button"]'
			));
			const stopItem = items.find((el) => {
				const text  = (el.textContent || "").trim();
				const label = (el.getAttribute("aria-label") || "").trim();
				return /^stop sharing$|^stop presenting$/i.test(text)
				    || /^stop sharing$|^stop presenting$/i.test(label);
			});
			if (stopItem) {
				stopItem.click();
				resolve({action: "stopped", label: "Stop sharing"});
				return;
			}
			if (Date.now() > deadline) {
				resolve({error: "submenu 'Stop sharing' didn't appear"});
				return;
			}
			setTimeout(tick, 100);
		};
		setTimeout(tick, 150);
	});
})()`

func cmdPresent() {
	t := mustFindMeetTarget()

	var click struct {
		Error  string `json:"error"`
		Action string `json:"action"`
		Label  string `json:"label"`
	}
	must(evalInTab(t, jsTogglePresent, true, &click))
	if click.Error != "" {
		die(2, "meetctl: %s", click.Error)
	}
	printJSON(map[string]string{
		"action":       click.Action,
		"clickedLabel": click.Label,
	})
}

func cmdJump() {
	t := mustFindMeetTarget()
	if _, err := cdpCall(t.WSURL, "Page.bringToFront", nil); err != nil {
		die(2, "meetctl: Page.bringToFront: %v", err)
	}
	printJSON(map[string]any{
		"focused": true,
		"url":     t.URL,
	})
}

// cmdEval runs an arbitrary JS expression in the Meet tab and prints the
// result as JSON. Useful for debugging selector drift.
func cmdEval(args []string) {
	if len(args) == 0 {
		die(1, "meetctl eval: missing JS expression\n"+
			"  example: meetctl eval 'document.title'")
	}
	t := mustFindMeetTarget()
	var out json.RawMessage
	must(evalInTab(t, args[0], false, &out))
	if len(out) == 0 {
		fmt.Println("null")
		return
	}
	// Pretty-print if it's a JSON value; else print as-is.
	var pretty bytes.Buffer
	if err := json.Indent(&pretty, out, "", "  "); err == nil {
		fmt.Println(pretty.String())
	} else {
		fmt.Println(string(out))
	}
}

func cmdNew(args []string) {
	url := "https://meet.google.com/new"
	if len(args) > 0 {
		url = args[0]
	}

	// Smart behaviour: if a Meet tab is already open, just focus it. The
	// caller (Hammerspoon Hyper+0, or a shell user) gets a useful action in
	// all three states -- no Chrome, Chrome but no tab, tab already there.
	if existing, err := findMeetTarget(); err == nil && existing != nil {
		if _, err := cdpCall(existing.WSURL, "Page.bringToFront", nil); err == nil {
			printJSON(map[string]any{"action": "focused", "url": existing.URL})
			return
		}
	}

	// No Meet tab open. Two ways to create one:
	//   1. CDP is up  -> Target.createTarget, near-instant
	//   2. CDP is down -> invoke chrome-for-meet directly (NOT via `open URL`,
	//                     which would route through Hammerspoon's default-
	//                     browser handler -- and if Hammerspoon is the caller
	//                     (Hyper+0), it's blocked waiting for us, so URL
	//                     delivery deadlocks until our poll expires).
	created := false
	if ws, err := browserWSURL(); err == nil {
		if _, err := cdpCall(ws, "Target.createTarget", map[string]any{"url": url}); err == nil {
			created = true
		}
	}
	if !created {
		home, err := os.UserHomeDir()
		if err != nil {
			die(2, "meetctl: can't determine $HOME: %v", err)
		}
		launcher := home + "/bin/chrome-for-meet"
		if err := exec.Command(launcher, url).Run(); err != nil {
			die(2, "meetctl: %s: %v", launcher, err)
		}
	}

	// Remember Meet tabs that exist so we can spot the new one we just
	// created (vs any stale ones that might exist).
	existing := map[string]bool{}
	if ts, err := listTargets(); err == nil {
		for _, t := range ts {
			if t.Type == "page" && strings.Contains(t.URL, "meet.google.com") &&
				strings.HasSuffix(t.URL, "/new") {
				continue // pre-redirect, ignore
			}
			if t.Type == "page" && strings.Contains(t.URL, "meet.google.com") {
				existing[t.ID] = true
			}
		}
	}

	// Poll for a *new* Meet tab to appear. Generous deadline because first-
	// ever launch of Chrome-for-Meet requires Google sign-in.
	deadline := time.Now().Add(30 * time.Second)
	var t *target
	for time.Now().Before(deadline) {
		ts, err := listTargets()
		if err == nil {
			for i := range ts {
				if ts[i].Type == "page" &&
					strings.Contains(ts[i].URL, "meet.google.com") &&
					!strings.HasSuffix(ts[i].URL, "/new") &&
					!existing[ts[i].ID] {
					t = &ts[i]
					break
				}
			}
			if t != nil {
				break
			}
		}
		time.Sleep(500 * time.Millisecond)
	}
	if t == nil {
		printJSON(map[string]any{
			"action": "launching",
			"note":   "Chrome still starting up (first run? sign in to Google)",
			"url":    url,
		})
		return
	}

	// Dismiss the "Your meeting's ready" info dialog first. It appears to
	// intercept clicks or block the mic button from rendering; muting
	// reliably only works once the dialog is out of the way.
	_ = evalInTab(t, jsDismissReadyDialog, false, nil)

	// Now auto-mute. Poll for the mic button (Meet renders the toolbar
	// async) and click it only if currently ON.
	_ = evalInTab(t, jsAutoMute, true, nil)

	printJSON(map[string]any{"action": "created", "url": t.URL})
}

// Poll for the mic toggle until it's rendered, then mute if it's on.
const jsAutoMute = `(function(){
	return new Promise((resolve) => {
		const deadline = Date.now() + 5000;
		const tick = () => {
			const on  = document.querySelector('[aria-label="Turn off microphone"]');
			if (on) { on.click(); resolve({muted: true}); return; }
			const off = document.querySelector('[aria-label="Turn on microphone"]');
			if (off) { resolve({muted: false, already: true}); return; }
			if (Date.now() > deadline) { resolve({error: "mic button never rendered"}); return; }
			setTimeout(tick, 150);
		};
		tick();
	});
})()`

// Finds the "Your meeting's ready" dialog (by its text content) and clicks
// its Close button. Returns a Promise; polls up to 5s so we don't race
// Meet's render.
const jsDismissReadyDialog = `(function(){
	return new Promise((resolve) => {
		const deadline = Date.now() + 5000;
		const tick = () => {
			const dialog = Array.from(document.querySelectorAll("*")).find((el) => {
				const t = (el.textContent || "").toLowerCase();
				return t.length < 300
					&& t.includes("your meeting")
					&& t.includes("ready");
			});
			if (dialog) {
				const closeBtn = dialog.querySelector('[aria-label="Close"]');
				if (closeBtn) {
					closeBtn.click();
					resolve({closed: true});
					return;
				}
			}
			if (Date.now() > deadline) {
				resolve({closed: false, reason: "ready dialog didn't appear"});
				return;
			}
			setTimeout(tick, 200);
		};
		tick();
	});
})()`

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func mustFindMeetTarget() *target {
	t, err := findMeetTarget()
	if err != nil {
		die(3, "meetctl: %v", err)
	}
	if t == nil {
		die(2, "meetctl: no meet tab")
	}
	return t
}

func must(err error) {
	if err == nil {
		return
	}
	// Is this a connect error? Return 3 so callers can tell.
	code := 2
	if strings.Contains(err.Error(), "ws dial") || strings.Contains(err.Error(), "GET http") {
		code = 3
	}
	die(code, "meetctl: %v", err)
}

func die(code int, format string, args ...any) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(code)
}

func printJSON(v any) {
	// Use Encoder so we get a trailing newline, matching the old Python
	// `print(json.dumps(...))` output.
	out := bytes.Buffer{}
	enc := json.NewEncoder(&out)
	enc.SetIndent("", "  ")
	if err := enc.Encode(v); err != nil {
		die(2, "meetctl: json encode: %v", err)
	}
	_, _ = io.Copy(os.Stdout, &out)
}

// ---------------------------------------------------------------------------
// Entrypoint
// ---------------------------------------------------------------------------

var commands = map[string]func([]string){
	"ping":           func(_ []string) { cmdPing() },
	"status":         func(_ []string) { cmdStatus() },
	"mute":           func(_ []string) { cmdMute() },
	"camera":         func(_ []string) { cmdCamera() },
	"present":        func(_ []string) { cmdPresent() },
	"present-screen": func(_ []string) { cmdPresent() }, // alias (pre-CDP name)
	"jump":           func(_ []string) { cmdJump() },
	"new":            cmdNew,
	"eval":           cmdEval,
}

func usage() {
	fmt.Print(`meetctl - control Google Meet via Chrome DevTools Protocol.

Commands:
    status             show mic/camera/presenting state
    mute               toggle the mic
    camera             toggle the camera
    present            toggle entire-screen sharing (no picker)
    present-screen     alias of present
    jump               focus the Meet tab + Chrome window
    new [URL]          open a new pre-muted meeting (default: /new)
    eval '<js>'        run arbitrary JS in the Meet tab (debug aid)
    ping               liveness check

Requires Chrome to be running with --remote-debugging-port=9222
and --auto-select-desktop-capture-source="Entire screen". The
chrome-for-meet launcher script sets both.
`)
}

func main() {
	if len(os.Args) < 2 {
		usage()
		return
	}
	switch os.Args[1] {
	case "-h", "--help", "help":
		usage()
		return
	}
	fn, ok := commands[os.Args[1]]
	if !ok {
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", os.Args[1])
		usage()
		os.Exit(1)
	}
	fn(os.Args[2:])
}
