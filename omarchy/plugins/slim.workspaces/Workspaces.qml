import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "slim.workspaces"

  // Mechabar icons from the old waybar format-icons map.
  readonly property var icons: ({
      1: "\uF121",
      2: "\uEB01",
      3: "\uE702",
      4: "4",
      5: "5",
      6: "6",
      7: "7",
      8: "\uDB82\uDC2E",
      9: "\uF1BC"
    })

  // Per-glyph optical padding from old waybar style.css (applied to the label).
  readonly property var paddingLeft: ({ 1: 4, 2: 7, 3: 6, 8: 6, 9: 6 })
  readonly property var paddingRight: ({ 1: 12, 2: 10, 3: 9, 8: 10, 9: 10 })

  readonly property color chromeColor: Color.accent
  readonly property color fillColor: Color.background
  readonly property color labelColor: Color.bar.text
  // Vertical inset from the bar edges; chips are a bit wider than tall.
  readonly property int chipMarginY: 3
  readonly property int chipHeight: Math.max(Style.space(14), root.barSize - Style.space(root.chipMarginY) * 2)
  readonly property int chipWidth: root.chipHeight + Style.space(6)
  // Old waybar used border-radius: 10px (rounded rect, not a circle).
  readonly property int chipRadius: Style.space(10)
  readonly property int defaultPadLeft: 9
  readonly property int defaultPadRight: 7

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    return [1, 2, 3, 4, 5, 6, 7, 8, 9]
  }

  function iconFor(id) {
    return root.icons[id] || String(id)
  }

  function padLeft(id) {
    return root.paddingLeft[id] !== undefined ? root.paddingLeft[id] : root.defaultPadLeft
  }

  function padRight(id) {
    return root.paddingRight[id] !== undefined ? root.paddingRight[id] : root.defaultPadRight
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  implicitWidth: row.implicitWidth
  implicitHeight: root.barSize

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(6)

    Repeater {
      model: root.workspaceIds()

      Item {
        id: chip
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        width: root.chipWidth
        height: root.chipHeight
        opacity: occupied || focused ? 1 : 0.5

        Behavior on opacity {
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        Rectangle {
          anchors.fill: parent
          visible: !chip.focused
          radius: root.chipRadius
          border.width: 1
          border.color: root.chromeColor
          gradient: Gradient {
            GradientStop { position: 0.0; color: root.chromeColor }
            GradientStop { position: 0.3; color: root.fillColor }
            GradientStop { position: 0.7; color: root.fillColor }
            GradientStop { position: 1.0; color: root.chromeColor }
          }
        }

        Rectangle {
          anchors.fill: parent
          visible: chip.focused
          radius: root.chipRadius
          border.width: 1
          border.color: root.chromeColor
          color: root.chromeColor
        }

        Text {
          anchors.fill: parent
          text: root.iconFor(chip.modelData)
          color: root.labelColor
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          renderType: Text.NativeRendering
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          leftPadding: Style.space(root.padLeft(chip.modelData))
          rightPadding: Style.space(root.padRight(chip.modelData))
          topPadding: Style.space(2)
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          cursorShape: Qt.PointingHandCursor
          onClicked: root.focusWorkspace(chip.modelData)
        }
      }
    }
  }
}
