import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "ProjectsModel.js" as ProjectsModel

Panel {
  id: root
  moduleName: "slim.projects"
  ipcTarget: "slim.projects"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string home: Quickshell.env("HOME")
  readonly property string configPath: home + "/.config/omarchy/projects.json"

  property var config: ProjectsModel.defaultConfig()
  property int editorFocusCount: 0
  property bool writing: false

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { if (root.opened) root.close(); else root.open() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function openLauncher() {
    if (root.bar) root.bar.run("omarchy-shell shell toggle slim.projects")
    root.close()
  }

  function applyConfig(raw) {
    if (root.writing) return
    root.config = ProjectsModel.parseConfig(raw)
    root.rebuildModels()
  }

  function rebuildModels() {
    baseDirModel.clear()
    var dirs = root.config && root.config.baseDirs ? root.config.baseDirs : []
    for (var i = 0; i < dirs.length; i++)
      baseDirModel.append({ path: String(dirs[i] || "") })

    projectModel.clear()
    var projects = root.config && root.config.projects ? root.config.projects : []
    for (var j = 0; j < projects.length; j++) {
      var row = projects[j] || {}
      projectModel.append({
        label: String(row.label || ""),
        path: String(row.path || ""),
        editor: String(row.editor || "")
      })
    }
  }

  function configFromModels() {
    var next = ProjectsModel.cloneConfig(root.config)
    var dirs = []
    for (var i = 0; i < baseDirModel.count; i++) {
      var dir = String(baseDirModel.get(i).path || "").trim()
      if (dir) dirs.push(dir)
    }
    next.baseDirs = dirs

    var projects = []
    for (var j = 0; j < projectModel.count; j++) {
      var row = projectModel.get(j)
      var path = String(row.path || "").trim()
      if (!path) continue
      var entry = { path: path }
      var label = String(row.label || "").trim()
      if (label) entry.label = label
      var editor = String(row.editor || "").trim()
      if (editor) entry.editor = editor
      projects.push(entry)
    }
    next.projects = projects
    return next
  }

  function saveConfig() {
    var next = root.configFromModels()
    var text = ProjectsModel.serializeConfig(next)
    if (text === ProjectsModel.serializeConfig(root.config)) return
    root.config = next
    root.writing = true
    configFile.setText(text)
    writeGuard.restart()
  }

  function commitBaseDir(index, value) {
    if (index < 0 || index >= baseDirModel.count) return
    baseDirModel.setProperty(index, "path", String(value || ""))
    root.saveConfig()
  }

  function commitProject(index, key, value) {
    if (index < 0 || index >= projectModel.count) return
    projectModel.setProperty(index, key, String(value || ""))
    root.saveConfig()
  }

  function addBaseDir() {
    baseDirModel.append({ path: "" })
  }

  function removeBaseDir(index) {
    if (index < 0 || index >= baseDirModel.count) return
    baseDirModel.remove(index)
    root.saveConfig()
  }

  function addProject() {
    projectModel.append({ label: "", path: "", editor: "" })
  }

  function removeProject(index) {
    if (index < 0 || index >= projectModel.count) return
    projectModel.remove(index)
    root.saveConfig()
  }

  function bumpEditorFocus(focused) {
    if (focused) root.editorFocusCount += 1
    else root.editorFocusCount = Math.max(0, root.editorFocusCount - 1)
  }

  onOpenedChanged: if (!root.opened) root.editorFocusCount = 0

  ListModel { id: baseDirModel }
  ListModel { id: projectModel }

  Timer {
    id: writeGuard
    interval: 300
    onTriggered: root.writing = false
  }

  FileView {
    id: configFile
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyConfig(text())
    onLoadFailed: root.applyConfig("{}")
    onFileChanged: reload()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.editorFocusCount > 0
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.openLauncher()

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: column
          width: parent.width
          spacing: Style.space(14)

          PanelHero {
            title: "Projects"
            meta: "Folders to scan and pinned projects"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            iconComponent: Text {
              text: "󰉋"
              color: root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
            }
          }

          PanelSeparator { foreground: root.contentForeground }

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "SCAN FOLDERS"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Text {
              width: parent.width
              visible: baseDirModel.count === 0
              text: "Immediate children of these folders appear in the picker."
              color: root.contentForeground
              opacity: 0.6
              wrapMode: Text.WordWrap
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }

            Repeater {
              model: baseDirModel
              delegate: PathRow {
                required property int index
                required property string path
                width: parent.width
                value: path
                placeholder: "~/Documents/dev"
                onCommit: function(next) { root.commitBaseDir(index, next) }
                onRemoved: root.removeBaseDir(index)
              }
            }

            Button {
              width: parent.width
              text: "Add folder"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              bordered: true
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
              onClicked: root.addBaseDir()
            }
          }

          PanelSeparator { foreground: root.contentForeground }

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "PINNED PROJECTS"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
            }

            Text {
              width: parent.width
              visible: projectModel.count === 0
              text: "Always listed, even if they are not under a scan folder."
              color: root.contentForeground
              opacity: 0.6
              wrapMode: Text.WordWrap
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.caption
            }

            Repeater {
              model: projectModel
              delegate: Column {
                required property int index
                required property string label
                required property string path
                width: parent.width
                spacing: Style.space(6)

                PathRow {
                  width: parent.width
                  value: label
                  placeholder: "Label"
                  onCommit: function(next) { root.commitProject(index, "label", next) }
                  onRemoved: root.removeProject(index)
                }

                PathRow {
                  width: parent.width
                  value: path
                  placeholder: "~/path/to/project"
                  showRemove: false
                  onCommit: function(next) { root.commitProject(index, "path", next) }
                }
              }
            }

            Button {
              width: parent.width
              text: "Add project"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              bordered: true
              horizontalPadding: Style.spacing.controlPaddingX
              verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
              onClicked: root.addProject()
            }
          }

          PanelSeparator { foreground: root.contentForeground }

          Button {
            width: parent.width
            text: "Open picker"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            bordered: true
            horizontalPadding: Style.spacing.controlPaddingX
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            onClicked: root.openLauncher()
          }
        }
      }
    }
  }

  component PathRow: Row {
    id: row
    property string value: ""
    property string placeholder: ""
    property bool showRemove: true

    signal commit(string next)
    signal removed()

    spacing: Style.space(6)

    TextField {
      id: field
      width: Math.max(0, parent.width - (row.showRemove ? removeButton.width + parent.spacing : 0))
      text: row.value
      placeholderText: row.placeholder
      foreground: root.contentForeground
      font.family: root.contentFontFamily
      onEditingFinished: row.commit(text)
      onActiveFocusChanged: root.bumpEditorFocus(activeFocus)
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          focus = false
          event.accepted = true
        }
      }
    }

    Button {
      id: removeButton
      visible: row.showRemove
      text: "✕"
      foreground: root.contentForeground
      fontFamily: root.contentFontFamily
      bordered: true
      horizontalPadding: Style.space(10)
      verticalPadding: Style.spacing.controlPaddingY
      onClicked: row.removed()
    }
  }
}
