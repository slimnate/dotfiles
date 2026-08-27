import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "slim.disk"
  ipcTarget: "slim.disk"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var stats: ({})
  readonly property var barIdentity: hostWidget || root
  readonly property var mounts: stats.mounts || []

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property real usageFraction: Math.max(0, Math.min(1, (stats.percent || 0) / 100))

  function open() {
    root.controller.show()
    if (hostWidget && hostWidget.refresh) hostWidget.refresh()
  }

  function close() { root.controller.hide() }
  function toggle() { if (root.opened) root.close(); else root.open() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }
  function openBtop() {
    if (root.bar) root.bar.run("omarchy-launch-or-focus-tui btop")
  }

  Timer {
    interval: 5000
    running: root.opened
    repeat: true
    onTriggered: if (hostWidget && hostWidget.refresh) hostWidget.refresh()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: root.openBtop()

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        PanelHero {
          title: "Disk"
          meta: (stats.usedHuman && stats.totalHuman)
            ? (stats.usedHuman + " / " + stats.totalHuman + " on " + (stats.path || "/"))
            : "Filesystems"
          detail: (stats.percent !== undefined ? stats.percent + "%" : "—")
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          iconComponent: Text {
            text: "\uf0c7"
            color: root.contentForeground
            font.family: root.contentFontFamily
            font.pixelSize: Style.font.display
          }
        }

        Item {
          width: parent.width
          implicitHeight: Style.space(8)
          Rectangle {
            id: barTrack
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
          }
          Rectangle {
            anchors.left: barTrack.left
            anchors.verticalCenter: barTrack.verticalCenter
            height: barTrack.height
            radius: barTrack.radius
            color: root.contentForeground
            width: Math.max(barTrack.height, barTrack.width * root.usageFraction)
            Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
          }
        }

        PanelSeparator { foreground: root.contentForeground }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "MOUNTS"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          Repeater {
            model: root.mounts

            Column {
              required property var modelData
              width: parent.width
              spacing: Style.space(6)

              Row {
                width: parent.width
                Text {
                  text: modelData.path
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }
                Item {
                  width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth)
                  height: 1
                }
                Text {
                  text: modelData.percent + "%"
                  color: root.contentForeground
                  font.family: root.contentFontFamily
                  font.pixelSize: Style.font.body
                }
              }

              Item {
                width: parent.width
                implicitHeight: Style.space(6)
                Rectangle {
                  anchors.fill: parent
                  radius: height / 2
                  color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
                }
                Rectangle {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  height: parent.height
                  radius: height / 2
                  color: root.contentForeground
                  width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, modelData.percent / 100)))
                }
              }

              InfoPair {
                label: modelData.source
                value: modelData.usedHuman + " / " + modelData.sizeHuman
              }
            }
          }
        }

        PanelSeparator { foreground: root.contentForeground }

        Button {
          width: parent.width
          text: "Open btop"
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          bordered: true
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          onClicked: root.openBtop()
        }
      }
    }
  }

  component InfoPair: Row {
    property string label: ""
    property string value: ""
    width: parent.width
    spacing: Style.space(8)
    Text {
      text: label
      color: root.contentForeground
      opacity: 0.6
      font.family: root.contentFontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideMiddle
      width: Math.min(implicitWidth, parent.width * 0.55)
    }
    Item {
      width: Math.max(0, parent.width - parent.children[0].width - parent.children[2].implicitWidth - parent.spacing * 2)
      height: 1
    }
    Text {
      text: value
      color: root.contentForeground
      font.family: root.contentFontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }
}
