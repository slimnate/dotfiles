import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "slim.memory"
  ipcTarget: "slim.memory"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var stats: ({})
  readonly property var barIdentity: hostWidget || root

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property real usageFraction: Math.max(0, Math.min(1, (stats.percent || 0) / 100))
  readonly property real swapFraction: Math.max(0, Math.min(1, (stats.swapPercent || 0) / 100))

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
    interval: 2000
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
          title: "Memory"
          meta: (stats.usedGb !== undefined && stats.totalGb !== undefined)
            ? (stats.usedGb + " / " + stats.totalGb + " GB used")
            : "System RAM"
          detail: (stats.percent !== undefined ? stats.percent + "%" : "—")
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          iconComponent: Text {
            text: "\uefc5"
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
            text: "RAM"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          Row {
            width: parent.width
            spacing: Style.space(20)
            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.spacing.labelGap
              InfoPair { label: "Used"; value: stats.usedGb !== undefined ? stats.usedGb + " GB" : "—" }
              InfoPair { label: "Available"; value: stats.availableGb !== undefined ? stats.availableGb + " GB" : "—" }
              InfoPair { label: "Free"; value: stats.freeGb !== undefined ? stats.freeGb + " GB" : "—" }
            }
            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.spacing.labelGap
              InfoPair { label: "Cached"; value: stats.cachedGb !== undefined ? stats.cachedGb + " GB" : "—" }
              InfoPair { label: "Buffers"; value: stats.buffersGb !== undefined ? stats.buffersGb + " GB" : "—" }
              InfoPair { label: "Total"; value: stats.totalGb !== undefined ? stats.totalGb + " GB" : "—" }
            }
          }
        }

        PanelSeparator { foreground: root.contentForeground }

        Column {
          width: parent.width
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "SWAP"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
          }

          Item {
            width: parent.width
            implicitHeight: Style.space(8)
            visible: (stats.swapTotalGb || 0) > 0
            Rectangle {
              id: swapTrack
              anchors.fill: parent
              radius: height / 2
              color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.12)
            }
            Rectangle {
              anchors.left: swapTrack.left
              anchors.verticalCenter: swapTrack.verticalCenter
              height: swapTrack.height
              radius: swapTrack.radius
              color: root.contentForeground
              width: Math.max(swapTrack.height, swapTrack.width * root.swapFraction)
              Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }
          }

          InfoPair {
            label: "Used / Total"
            value: (stats.swapTotalGb || 0) > 0
              ? (stats.swapUsedGb + " / " + stats.swapTotalGb + " GB")
              : "None"
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
    }
    Item {
      width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2)
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
