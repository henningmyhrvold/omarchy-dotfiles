import QtQuick
import qs.Ui

// Installed into a native `omarchy plugin clone omarchy.menu` clone. Its
// clonedFrom metadata keeps the stock IPC target and keyboard shortcuts working.
BarWidget {
  id: root
  moduleName: "omarchy.menu"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf303"
    fontFamily: "JetBrainsMono Nerd Font"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}
