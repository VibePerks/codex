// Command vibeperks-codex is the Codex adapter for VibePerks: a thin wrapper that reuses the
// shared package core for all network, auth, cache, and privacy concerns. Codex has no
// status-line slot, so the rendering surface is the terminal title / prompt line (the
// `render` command, network-free) and the thinking-state signal is Codex's
// UserPromptSubmit hook (the `prompt` command). Every command runs inside core.Guard,
// the single boundary where errors are swallowed so the host CLI is never broken.
package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"time"

	"vibeperks/core"
)

// version is stamped at build time via -ldflags "-X main.version=...".
var version = "dev"

const cli = "codex"

func main() {
	if len(os.Args) < 2 {
		return
	}
	switch os.Args[1] {
	case "version", "-v", "--version":
		fmt.Println(version)
		return
	}
	core.Guard(func() error { return dispatch(os.Args[1]) })
}

func dispatch(cmd string) error {
	dir := core.ConfigDir()
	switch cmd {
	case "render":
		return cmdRender(dir)
	case "prompt":
		return cmdPrompt()
	case "refresh":
		return cmdRefresh(dir)
	case "stop":
		return cmdStop(dir)
	case "login":
		return cmdLogin(dir)
	case "optout":
		return cmdOptOut(dir, true)
	case "optin":
		return cmdOptOut(dir, false)
	}
	return nil
}

func meta(sessionID string) core.Meta {
	return core.Meta{
		CLI:           cli,
		CLIVersion:    os.Getenv("CODEX_VERSION"),
		PluginVersion: version,
		SessionID:     sessionID,
	}
}

// cmdRender prints the cached ad line for the terminal title / prompt surface. It makes
// no network call and marks the ad as displayed, so the line is always instant. When the
// device token was rejected it prints a sign-in notice instead. The text is left plain
// (no ANSI) because the shell integration also writes it into the terminal title, where
// escape codes would corrupt the title.
func cmdRender(dir string) error {
	adLine, _, err := core.Render(dir, time.Now().Unix(), "vibeperks-codex login")
	if err != nil {
		return err
	}
	if adLine != "" {
		fmt.Println(adLine)
	}
	return nil
}

// cmdPrompt (UserPromptSubmit) signals thinking-start. It spawns a detached refresh so
// the prompt path never waits on the network, and prints nothing.
func cmdPrompt() error {
	self, err := os.Executable()
	if err != nil {
		return err
	}
	c := exec.Command(self, "refresh", sessionArg())
	detach(c)
	return c.Start()
}

// cmdRefresh is the detached background worker: it records the previously displayed ad's
// impression, serves + caches the next ad, and flushes the impression buffer.
func cmdRefresh(dir string) error {
	cfg, err := core.LoadConfig(dir)
	if err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return core.Refresh(ctx, dir, core.NewClient(cfg), meta(sessionArg()), time.Now().Unix(), true)
}

// cmdStop records the currently displayed ad's impression and flushes. Codex has no Stop
// hook, so the next prompt's refresh normally records the prior impression; stop exists
// for hosts that can signal session end.
func cmdStop(dir string) error {
	cfg, err := core.LoadConfig(dir)
	if err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	return core.EndSession(ctx, dir, core.NewClient(cfg), meta(sessionArg()), time.Now().Unix())
}

// cmdLogin stores the device token (from arg or stdin) in the local config.
func cmdLogin(dir string) error {
	token := ""
	if len(os.Args) > 2 {
		token = strings.TrimSpace(os.Args[2])
	}
	if token == "" {
		b, _ := io.ReadAll(os.Stdin)
		token = strings.TrimSpace(string(b))
	}
	if token == "" {
		return fmt.Errorf("login: no device token provided")
	}
	cfg, err := core.LoadConfig(dir)
	if err != nil {
		return err
	}
	cfg.DeviceToken = token
	if err := core.SaveConfig(dir, cfg); err != nil {
		return err
	}
	fmt.Println("vibeperks: device token saved.")
	return nil
}

// cmdOptOut toggles the opt-out flag; when opted out the plugin fetches and reports
// nothing.
func cmdOptOut(dir string, out bool) error {
	cfg, err := core.LoadConfig(dir)
	if err != nil {
		return err
	}
	cfg.OptOut = out
	if err := core.SaveConfig(dir, cfg); err != nil {
		return err
	}
	if out {
		fmt.Println("vibeperks: opted out. No ads will be fetched or reported.")
	} else {
		fmt.Println("vibeperks: opted back in.")
	}
	return nil
}

// sessionArg returns the optional session id passed as the second CLI argument.
func sessionArg() string {
	if len(os.Args) > 2 {
		return os.Args[2]
	}
	return ""
}
