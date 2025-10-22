package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log/slog"
	"net"
	"os"
	"sort"
)

// Request types
type Request string

const (
	RequestEventStream Request = "EventStream"
)

// Event types
type Event struct {
	WorkspacesChanged  *WorkspacesChangedEvent  `json:"WorkspacesChanged,omitempty"`
	WorkspaceActivated *WorkspaceActivatedEvent `json:"WorkspaceActivated,omitempty"`

	WindowsChanged        *WindowsChangedEvent        `json:"WindowsChanged,omitempty"`
	WindowOpenedOrChanged *WindowOpenedOrChangedEvent `json:"WindowOpenedOrChanged,omitempty"`
	WindowClosed          *WindowClosedEvent          `json:"WindowClosed,omitempty"`
}

type WorkspacesChangedEvent struct {
	Workspaces []Workspace `json:"workspaces"`
}

type WorkspaceActivatedEvent struct {
	Id      uint64 `json:"id"`
	Focused bool   `json:"focused"`
}

type WindowsChangedEvent struct {
	Windows []Window `json:"windows"`
}

type WindowOpenedOrChangedEvent struct {
	Window Window `json:"window"`
}

type WindowClosedEvent struct {
	Id uint64 `json:"id"`
}

type Workspace struct {
	Id             uint64  `json:"id"`
	Idx            uint8   `json:"idx"`
	Name           *string `json:"name,omitempty"`
	Output         *string `json:"output,omitempty"`
	IsUrgent       bool    `json:"is_urgent"`
	IsActive       bool    `json:"is_active"`
	IsFocused      bool    `json:"is_focused"`
	IsFloating     bool    `json:"is_floating"`
	ActiveWindowId *uint64 `json:"active_window_id,omitempty"`
}

type WorkspaceEww struct {
	Idx       uint8 `json:"idx"`
	IsFocused bool  `json:"is_focused"`
	WindowQty uint8 `json:"window_qty"`
}

type Window struct {
	Id          uint64  `json:"id"`
	WorkspaceId *uint64 `json:"workspace_id,omitempty"`
}

// LogValue implements slog.LogValuer
func (w WorkspaceEww) LogValue() slog.Value {
	return slog.GroupValue(
		slog.Int("idx", int(w.Idx)),
		slog.Bool("isFocused", w.IsFocused),
		slog.Int("windowQty", int(w.WindowQty)),
	)
}

// State keeps track of all the state necessary for the bar to work
type State struct {
	Workspaces map[uint64]Workspace
	Windows    map[uint64]Window
}

func NewWorkspaceState() *State {
	return &State{
		Workspaces: make(map[uint64]Workspace),
		Windows:    make(map[uint64]Window),
	}
}

func (state *State) Print(logger *slog.Logger) {
	workspacesEww := make([]WorkspaceEww, 0, len(state.Workspaces))
	for _, workspace := range state.Workspaces {
		var windowQty uint8
		for _, window := range state.Windows {
			if window.WorkspaceId == nil {
				continue
			}

			if *window.WorkspaceId != workspace.Id {
				continue
			}

			windowQty += 1
		}

		workspacesEww = append(workspacesEww, WorkspaceEww{
			Idx:       workspace.Idx,
			IsFocused: workspace.IsFocused,
			WindowQty: windowQty,
		})
	}

	sort.Slice(workspacesEww, func(i int, j int) bool {
		return workspacesEww[i].Idx < workspacesEww[j].Idx
	})

	workspacesJson, err := json.Marshal(workspacesEww)
	if err != nil {
		logger.Error(
			"Could not marshal workspaces to JSON",
			slog.Any("workspaces", workspacesEww),
			slog.String("error", err.Error()),
		)
		os.Exit(1)
	}

	fmt.Println(string(workspacesJson))
}

func handleWorkspacesChangedEvent(logger *slog.Logger, event *WorkspacesChangedEvent, state *State) {
	logger.Debug("Received WorkspacesChanged event")
	state.Workspaces = make(map[uint64]Workspace)
	for _, w := range event.Workspaces {
		state.Workspaces[w.Id] = w
	}
	state.Print(logger)
}

func handleWorkspaceActivatedEvent(logger *slog.Logger, event *WorkspaceActivatedEvent, state *State) {
	logger.Debug(
		"Workspace activated",
		slog.Uint64("workspace_id", event.Id),
		slog.Bool("focused", event.Focused),
	)

	if !event.Focused {
		return
	}

	_, found := state.Workspaces[event.Id]
	if !found {
		logger.Error(
			"Could not find WorkspaceActivated",
			slog.Uint64("workspace_id", event.Id),
		)
		os.Exit(1)
	}

	for workspaceId, workspace := range state.Workspaces {
		workspace.IsFocused = workspace.Id == event.Id
		state.Workspaces[workspaceId] = workspace
	}

	state.Print(logger)
}

func handleWindowsChangedEvent(logger *slog.Logger, event *WindowsChangedEvent, state *State) {
	logger.Debug("Received WindowsChanged event")
	state.Windows = make(map[uint64]Window)
	for _, w := range event.Windows {
		state.Windows[w.Id] = w
	}
	state.Print(logger)
}

func handleWindowOpenedOrChangedEvent(logger *slog.Logger, event *WindowOpenedOrChangedEvent, state *State) {
	logger.Debug("Received WindowOpenedOrChanged event")

	window, found := state.Windows[event.Window.Id]
	if !found {
		logger.Debug(
			"WindowOpened",
			slog.Uint64("window_id", event.Window.Id),
			slog.Any("workspace_id", *event.Window.WorkspaceId),
		)

		state.Windows[event.Window.Id] = event.Window
		state.Print(logger)
		return
	}

	logger.Debug(
		"WindowChanged",
		slog.Uint64("window_id", event.Window.Id),
		slog.Any("workspace_id", *event.Window.WorkspaceId),
	)

	window.WorkspaceId = event.Window.WorkspaceId
	state.Windows[event.Window.Id] = window

	state.Print(logger)
}

func handleWindowClosedEvent(logger *slog.Logger, event *WindowClosedEvent, state *State) {
	logger.Debug("Received WindowClosed event")
	delete(state.Windows, event.Id)
	state.Print(logger)
}

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))

	// Get socket path from environment
	socketPath := os.Getenv("NIRI_SOCKET")
	if socketPath == "" {
		logger.Error("NIRI_SOCKET environment variable is not set")
		os.Exit(1)
	}

	// Connect to Unix socket
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		logger.Error(
			"Failed to connect to socket",
			slog.String("error", err.Error()),
		)
		os.Exit(1)
	}
	defer conn.Close()

	logger.Info("Connected to Niri socket", slog.String("socket_path", socketPath))

	// Send EventStream request
	request, err := json.Marshal(RequestEventStream)
	if err != nil {
		logger.Error("Failed to marshal request", slog.String("error", err.Error()))
		os.Exit(1)
	}

	_, err = conn.Write(append(request, '\n'))
	if err != nil {
		logger.Error("Failed to send request", slog.String("error", err.Error()))
		os.Exit(1)
	}

	logger.Info("Sent EventStream request, waiting for events...")

	// Read response
	scanner := bufio.NewScanner(conn)
	state := NewWorkspaceState()

	// First line should be the reply to our request
	if scanner.Scan() {
		str := scanner.Text()
		if str != "{\"Ok\":\"Handled\"}" {
			logger.Error("Failed to parse reply", slog.String("reply", str))
		}

		logger.Info("EventStream activated successfully")
	}

	// Now continuously read events
	for scanner.Scan() {
		bytes := scanner.Bytes()
		event := Event{}
		if err := json.Unmarshal(bytes, &event); err != nil {
			logger.Info("Failed to parse event", slog.String("event", string(bytes)), slog.String("error", err.Error()))
			continue
		}

		// Handle workspace events
		if event.WorkspacesChanged != nil {
			handleWorkspacesChangedEvent(logger, event.WorkspacesChanged, state)
		}

		if event.WorkspaceActivated != nil {
			handleWorkspaceActivatedEvent(logger, event.WorkspaceActivated, state)
		}

		if event.WindowsChanged != nil {
			handleWindowsChangedEvent(logger, event.WindowsChanged, state)
		}

		if event.WindowOpenedOrChanged != nil {
			handleWindowOpenedOrChangedEvent(logger, event.WindowOpenedOrChanged, state)
		}

		if event.WindowClosed != nil {
			handleWindowClosedEvent(logger, event.WindowClosed, state)
		}

	}

	if err := scanner.Err(); err != nil {
		logger.Error("Error reading from socket", slog.String("error", err.Error()))
		os.Exit(1)
	}
}
