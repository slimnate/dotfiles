import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "slim.memory"

  property var stats: ({})
  readonly property string label: stats.label || "\uefc5  —"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("stats" in target) target.stats = root.stats
  }

  function applyStats(text) {
    try {
      root.stats = JSON.parse(String(text || "").trim() || "{}")
    } catch (e) {
      return
    }
    injectPanel()
  }

  function refresh() {
    if (!statsProc.running) statsProc.running = true
  }

  function openBtop() {
    if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()
  Component.onCompleted: refresh()

  Process {
    id: statsProc
    command: [Quickshell.env("HOME") + "/.config/omarchy/bar/scripts/system-stats", "memory"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStats(text)
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    horizontalMargin: 8.75
    tooltipText: ""
    onPressed: function(b) {
      if (b === Qt.RightButton) root.openBtop()
      else if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}
