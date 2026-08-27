import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "ProjectsModel.js" as ProjectsModel

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property string filterText: ""
  property int selectedIndex: 0
  property bool cursorActive: false
  property bool scanning: false
  property var projects: []
  property var config: ProjectsModel.defaultConfig()
  property var availableEditorIds: []
  property var visibleEditors: []
  property string listingPath: ""

  readonly property string home: Quickshell.env("HOME")
  readonly property string pluginDir: (manifest && manifest.__sourceDir)
    ? String(manifest.__sourceDir)
    : (home + "/.config/omarchy/plugins/slim.projects")
  readonly property string configPath: home + "/.config/omarchy/projects.json"
  readonly property string scanScript: pluginDir + "/scan.sh"
  readonly property string launchScript: pluginDir + "/launch.sh"
  readonly property string listScript: pluginDir + "/list.sh"

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property color muted: Color.muted
  property color accent: Color.accent
  property color urgent: Color.urgent
  property color warning: Color.accent
  readonly property int cornerRadius: Style.cornerRadius
  property string fontFamily: Style.font.menuFamily
  property int contentMargin: Style.spacing.panelPadding
  property int headerHeight: Math.max(Style.space(34), Style.font.title + Style.spacing.controlPaddingY * 2)
  property int footerHeight: Math.max(Style.space(44), Style.font.body + Style.spacing.controlPaddingY * 2)
  property int contentSpacing: Style.spacing.md
  property int cardWidth: Math.min(Style.space(1100), panel.width - Style.gapsOut * 2)
  property int cardHeight: Math.min(Style.space(640), panel.height - Style.gapsOut * 2)
  property int rowHeight: Math.max(Style.space(58), Style.font.title + Style.font.caption + Style.spacing.rowPaddingX * 2)

  function open(payloadJson) {
    root.opened = true
    root.filterText = ""
    root.selectedIndex = 0
    root.cursorActive = true
    root.disarmPointer()
    root.rebuildEditors()
    root.rebuildDisplay()
    root.refreshProjects()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.opened = false
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "slim.projects")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function loadConfig(raw) {
    root.config = ProjectsModel.parseConfig(raw)
    root.refreshAvailableEditors()
    root.rebuildEditors()
    if (root.opened) root.refreshProjects()
  }

  function loadProjects(raw) {
    root.projects = ProjectsModel.parseProjects(raw)
    root.scanning = false
    if (root.opened) root.rebuildDisplay()
  }

  function refreshProjects() {
    if (scanProc.running) scanProc.running = false
    root.scanning = true
    scanProc.running = true
  }

  function refreshAvailableEditors() {
    var editors = root.config && root.config.editors ? root.config.editors : []
    var checks = []
    for (var i = 0; i < editors.length; i++) {
      var editor = ProjectsModel.normalizeEditor(editors[i])
      if (!editor) continue
      var bin = ProjectsModel.editorBinary(editor)
      if (!bin) continue
      checks.push("if command -v " + Util.shellQuote(bin) + " >/dev/null 2>&1; then printf '%s\\n' " + Util.shellQuote(editor.id) + "; fi")
    }
    if (checks.length === 0) {
      root.availableEditorIds = []
      root.rebuildEditors()
      return
    }
    pathCheck.command = ["bash", "-lc", checks.join("; ")]
    pathCheck.running = false
    pathCheck.running = true
  }

  function rebuildEditors() {
    root.visibleEditors = ProjectsModel.visibleEditors(
      root.config.editors,
      root.availableEditorIds,
      root.config.defaultEditor
    )
  }

  function rebuildDisplay() {
    var rows = ProjectsModel.filterProjects(root.projects, root.filterText)
    displayModel.clear()
    for (var i = 0; i < rows.length; i++) {
      var row = rows[i]
      displayModel.append({
        ts: row.ts,
        name: row.name,
        path: row.path,
        branch: row.branch,
        dirty: row.dirty,
        ahead: row.ahead,
        behind: row.behind,
        activity: row.activity,
        tags: row.tags,
        editor: row.editor,
        meta: ProjectsModel.listMeta(row, root.config.showStatus, root.config.showActivity)
      })
    }

    if (displayModel.count === 0) selectedIndex = 0
    else if (selectedIndex >= displayModel.count) selectedIndex = displayModel.count - 1
    else if (selectedIndex < 0) selectedIndex = 0
    cursorActive = displayModel.count > 0

    Qt.callLater(function() {
      if (displayModel.count > 0) resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    })
    root.queueListing()
  }

  onSelectedIndexChanged: root.queueListing()

  function queueListing() {
    listingDebounce.restart()
  }

  function refreshListing() {
    var row = root.activeRow()
    var path = row && row.path ? String(row.path) : ""
    if (!path) {
      root.listingPath = ""
      listingModel.clear()
      return
    }
    if (path === root.listingPath && listProc.running) return
    root.listingPath = path
    if (listProc.running) listProc.running = false
    listProc.command = [root.listScript, path]
    listProc.running = true
  }

  function loadListing(raw) {
    var rows = ProjectsModel.parseListing(raw)
    listingModel.clear()
    for (var i = 0; i < rows.length; i++) {
      listingModel.append({
        name: rows[i].name,
        dir: rows[i].dir,
        link: rows[i].link,
        hidden: rows[i].hidden
      })
    }
  }

  function select(delta) {
    if (displayModel.count === 0) return
    root.disarmPointer()
    if (!cursorActive) {
      cursorActive = true
      selectedIndex = delta < 0 ? displayModel.count - 1 : 0
    } else {
      selectedIndex = (selectedIndex + delta + displayModel.count) % displayModel.count
    }
    resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
  }

  function selectAbsolute(index) {
    if (displayModel.count === 0) return
    root.disarmPointer()
    root.cursorActive = true
    root.selectedIndex = Math.max(0, Math.min(index, displayModel.count - 1))
    resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
  }

  function setFilter(nextFilter) {
    root.filterText = nextFilter
    root.selectedIndex = 0
    root.cursorActive = true
    root.disarmPointer()
    root.rebuildDisplay()
  }

  function disarmPointer() {
    pointerGate.reset()
  }

  function selectFromPointer(index, item, mouse) {
    if (!pointerGate.moved(item, mouse)) return
    root.cursorActive = true
    root.selectedIndex = index
  }

  function activeRow() {
    if (displayModel.count === 0 || root.selectedIndex < 0 || root.selectedIndex >= displayModel.count)
      return null
    return displayModel.get(root.selectedIndex)
  }

  function launchAt(index, editorId) {
    if (index < 0 || index >= displayModel.count) return
    var row = displayModel.get(index)
    if (!row || !row.path) return
    var editor = ProjectsModel.resolveEditor(
      root.visibleEditors,
      editorId,
      root.config.defaultEditor,
      editorId ? '' : row.editor
    )
    if (!editor) return
    var payload = JSON.stringify({
      id: editor.id,
      name: editor.name,
      command: editor.command,
      class: editor.class,
      kind: editor.kind
    })
    root.dismiss()
    Util.execArgv([root.launchScript, payload, String(row.path)])
  }

  function launchEditorAt(slot) {
    if (!root.cursorActive || displayModel.count === 0) return
    var editors = root.visibleEditors
    if (slot < 0 || slot >= editors.length) return
    root.launchAt(root.selectedIndex, editors[slot].id)
  }

  function digitSlot(event) {
    if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return -1
    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) return event.key - Qt.Key_1
    return -1
  }

  ListModel { id: displayModel }
  ListModel { id: listingModel }

  Timer {
    id: listingDebounce
    interval: 60
    repeat: false
    onTriggered: root.refreshListing()
  }

  PointerMoveGate {
    id: pointerGate
    referenceItem: card
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadConfig(text())
    onLoadFailed: root.loadConfig("{}")
    onFileChanged: reload()
  }

  FileView {
    path: Color.currentThemePath + "/colors.toml"
    watchChanges: true
    printErrors: false
    onLoaded: {
      var hex = ProjectsModel.parseTomlColor(text(), 'yellow', '')
      root.warning = hex ? hex : Color.accent
    }
    onFileChanged: reload()
    onLoadFailed: root.warning = Color.accent
  }

  Process {
    id: scanProc
    command: [root.scanScript, root.configPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.loadProjects(text)
    }
    onExited: function(code) {
      if (code !== 0 && root.scanning) {
        root.scanning = false
        root.loadProjects("[]")
      }
    }
  }

  Process {
    id: pathCheck
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var ids = String(text || "").split("\n").filter(function(id) { return id.length > 0 })
        root.availableEditorIds = ids
        root.rebuildEditors()
      }
    }
  }

  Process {
    id: listProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.loadListing(text)
    }
    onExited: function(code) {
      if (code !== 0) root.loadListing("[]")
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "slim-projects"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      MouseArea { anchors.fill: parent; onClicked: {} }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          var slot = root.digitSlot(event)
          if (slot >= 0) {
            root.launchEditorAt(slot)
            event.accepted = true
            return
          }

          if (event.key === Qt.Key_Escape) {
            if (root.filterText) root.setFilter("")
            else root.dismiss()
            event.accepted = true
          } else if (Util.editsFilter(event, root.filterText)) {
            root.setFilter(Util.editedFilter(event, root.filterText))
            event.accepted = true
          } else if (event.key === Qt.Key_Up) {
            root.select(-1)
            event.accepted = true
          } else if (event.key === Qt.Key_Down) {
            root.select(1)
            event.accepted = true
          } else if (event.key === Qt.Key_PageUp) {
            root.select(-8)
            event.accepted = true
          } else if (event.key === Qt.Key_PageDown) {
            root.select(8)
            event.accepted = true
          } else if (event.key === Qt.Key_Home) {
            root.selectAbsolute(0)
            event.accepted = true
          } else if (event.key === Qt.Key_End) {
            root.selectAbsolute(displayModel.count - 1)
            event.accepted = true
          } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.cursorActive) root.launchAt(root.selectedIndex, "")
            else if (displayModel.count > 0) root.cursorActive = true
            event.accepted = true
          } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127) {
            root.setFilter(root.filterText + event.text)
            event.accepted = true
          }
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: root.contentSpacing

        Rectangle {
          width: parent.width
          height: root.headerHeight
          radius: root.cornerRadius
          color: "transparent"

          Text {
            anchors.left: parent.left
            anchors.right: countLabel.left
            anchors.rightMargin: Style.space(12)
            anchors.verticalCenter: parent.verticalCenter
            text: root.filterText || "Search projects…"
            color: root.foreground
            opacity: root.filterText ? 1 : 0.58
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            elide: Text.ElideRight
          }

          Text {
            id: countLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.scanning
              ? "Scanning…"
              : (displayModel.count + (displayModel.count === 1 ? " project" : " projects"))
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Item {
          width: parent.width
          height: parent.height - root.headerHeight - root.footerHeight - root.contentSpacing * 2

          Row {
            anchors.fill: parent
            spacing: 0
            visible: displayModel.count > 0

            Item {
              width: parent.width * 0.52
              height: parent.height
              clip: true

              ListView {
                id: resultList
                anchors.fill: parent
                anchors.rightMargin: root.contentMargin
                model: displayModel
                clip: true
                spacing: Style.space(4)
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                  id: row
                  required property int index
                  required property string name
                  required property string path
                  required property string branch
                  required property int dirty
                  required property string activity
                  required property string meta

                  readonly property bool hasCursor: root.cursorActive && index === root.selectedIndex

                  width: ListView.view.width
                  height: root.rowHeight
                  radius: root.cornerRadius
                  color: hasCursor ? root.selectedBackground : "transparent"

                  Rectangle {
                    visible: row.hasCursor
                    width: Style.space(3)
                    height: parent.height - Style.space(12)
                    radius: width / 2
                    anchors.left: parent.left
                    anchors.leftMargin: Style.space(6)
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accent
                  }

                  Column {
                    anchors.fill: parent
                    anchors.leftMargin: Style.space(16)
                    anchors.rightMargin: Style.space(12)
                    anchors.topMargin: Style.space(8)
                    anchors.bottomMargin: Style.space(8)
                    spacing: Style.space(2)

                    Text {
                      width: parent.width
                      text: row.name
                      color: row.hasCursor ? root.selectedText : root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.title
                      elide: Text.ElideRight
                    }

                    Row {
                      width: parent.width
                      spacing: Style.space(6)
                      clip: true

                      readonly property bool showBranch: root.config.showStatus && row.branch && row.branch !== '-'
                      readonly property bool showDirty: root.config.showStatus && row.dirty > 0
                      readonly property bool showActivity: root.config.showActivity && row.activity && row.activity !== '-'

                      Text {
                        visible: parent.showBranch
                        text: row.branch
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                      }
                      Text {
                        visible: parent.showBranch && (parent.showDirty || parent.showActivity)
                        text: "·"
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                      }
                      Text {
                        visible: parent.showDirty
                        text: row.dirty + " dirty"
                        color: root.warning
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                      }
                      Text {
                        visible: parent.showDirty && parent.showActivity
                        text: "·"
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                      }
                      Text {
                        visible: parent.showActivity
                        text: row.activity
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                        elide: Text.ElideRight
                      }
                    }
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onPositionChanged: function(mouse) {
                      root.selectFromPointer(row.index, row, mouse)
                    }
                    onClicked: {
                      root.cursorActive = true
                      root.selectedIndex = row.index
                      root.launchAt(row.index, "")
                    }
                  }
                }
              }
            }

            Item {
              id: detailPane
              width: parent.width * 0.48
              height: parent.height
              clip: true

              property var row: root.activeRow()
              property var tags: row ? ProjectsModel.splitTags(row.tags) : []

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Style.normalBorderWidth
                color: Util.alpha(root.border, 0.28)
              }

              Column {
                anchors.fill: parent
                anchors.leftMargin: root.contentMargin
                spacing: Style.space(10)

                Column {
                  id: detailMeta
                  width: parent.width
                  spacing: Style.space(10)

                Text {
                  width: parent.width
                  text: detailPane.row ? detailPane.row.name : ""
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.heading
                  wrapMode: Text.WordWrap
                }

                Text {
                  width: parent.width
                  text: detailPane.row ? ProjectsModel.shortenHome(detailPane.row.path, root.home) : ""
                  color: root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  wrapMode: Text.WrapAnywhere
                }

                Rectangle {
                  width: parent.width
                  height: Style.normalBorderWidth
                  color: Util.alpha(root.border, 0.18)
                }

                Row {
                  width: parent.width
                  spacing: Style.space(6)
                  visible: !!(detailPane.row)

                  readonly property bool hasGit: detailPane.row && detailPane.row.branch && detailPane.row.branch !== '-'
                  readonly property int dirtyCount: detailPane.row ? (detailPane.row.dirty || 0) : 0
                  readonly property int aheadCount: detailPane.row ? (detailPane.row.ahead || 0) : 0
                  readonly property int behindCount: detailPane.row ? (detailPane.row.behind || 0) : 0

                  Text {
                    text: parent.hasGit ? detailPane.row.branch : "Not a git repository"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                  Text {
                    visible: parent.hasGit
                    text: "·"
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                  Text {
                    visible: parent.hasGit
                    text: parent.dirtyCount > 0 ? (parent.dirtyCount + " dirty") : "clean"
                    color: parent.dirtyCount > 0 ? root.warning : root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                  Text {
                    visible: parent.hasGit && parent.aheadCount > 0
                    text: "·  " + parent.aheadCount + " ahead"
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                  Text {
                    visible: parent.hasGit && parent.behindCount > 0
                    text: "·  " + parent.behindCount + " behind"
                    color: root.muted
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                }

                Text {
                  width: parent.width
                  visible: !!(detailPane.row && detailPane.row.activity)
                  text: detailPane.row ? ("Last activity " + detailPane.row.activity) : ""
                  color: root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Flow {
                  width: parent.width
                  spacing: Style.space(6)
                  visible: root.config.showTags && detailPane.tags.length > 0

                  Repeater {
                    model: detailPane.tags
                    delegate: Rectangle {
                      required property string modelData
                      height: Style.font.caption + Style.space(10)
                      width: tagLabel.implicitWidth + Style.space(14)
                      radius: height / 2
                      color: Util.alpha(root.foreground, 0.08)

                      Text {
                        id: tagLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: root.muted
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.caption
                      }
                    }
                  }
                }
              }

                ListView {
                  width: parent.width
                  height: Math.max(0, parent.height - detailMeta.height - parent.spacing)
                  clip: true
                  model: listingModel
                  spacing: Style.space(2)
                  boundsBehavior: Flickable.StopAtBounds
                  visible: listingModel.count > 0

                  delegate: Row {
                    required property string name
                    required property bool dir
                    required property bool link
                    required property bool hidden

                    width: ListView.view.width
                    spacing: Style.space(8)
                    height: Style.font.body + Style.space(4)

                    Text {
                      text: dir ? "󰉋" : (link ? "󰌹" : "󰈔")
                      color: dir ? root.accent : root.muted
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      opacity: hidden ? 0.55 : 1
                    }

                    Text {
                      width: parent.width - parent.spacing - Style.space(18)
                      text: name + (dir ? "/" : "")
                      color: hidden ? root.muted : root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      elide: Text.ElideRight
                      opacity: hidden ? 0.7 : 1
                    }
                  }
                }

                Text {
                  width: parent.width
                  visible: !!detailPane.row && listingModel.count === 0 && !listProc.running
                  text: "Empty directory"
                  color: root.muted
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }

          Column {
            anchors.centerIn: parent
            spacing: Style.space(8)
            visible: displayModel.count === 0

            Text {
              text: root.scanning ? "󰥔" : "󰉋"
              color: root.selectedText
              opacity: 0.8
              font.family: root.fontFamily
              font.pixelSize: Style.font.displayLarge
              horizontalAlignment: Text.AlignHCenter
              width: parent.width
            }

            Text {
              text: root.scanning
                ? "Scanning projects…"
                : (root.filterText
                  ? "No matches for “" + root.filterText + "”"
                  : "No projects found")
              color: root.foreground
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              horizontalAlignment: Text.AlignHCenter
              width: parent.width
            }
          }
        }

        Item {
          width: parent.width
          height: root.footerHeight

          Text {
            id: openLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Open with"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Row {
            anchors.left: openLabel.right
            anchors.leftMargin: Style.space(10)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Repeater {
              model: root.visibleEditors
              delegate: Rectangle {
                id: editorChip
                required property var modelData
                required property int index
                readonly property bool isDefault: index === 0

                height: Style.font.body + Style.space(12)
                width: chipLabel.implicitWidth + Style.space(16)
                radius: height / 2
                color: isDefault ? Util.alpha(root.accent, 0.18) : Util.alpha(root.foreground, 0.06)
                border.width: Style.normalBorderWidth
                border.color: isDefault ? root.accent : Util.alpha(root.border, 0.35)

                Text {
                  id: chipLabel
                  anchors.centerIn: parent
                  text: modelData.name + (isDefault ? "  ⏎" : "  " + (index + 1))
                  color: isDefault ? root.accent : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.launchEditorAt(editorChip.index)
                }
              }
            }
          }
        }
      }
    }
  }
}
