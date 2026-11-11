import { Graphics, Label, Node } from './Engine';
import { theme } from './UI';
import { NavigationTab } from './NavigationModel';

/** All Cocos pages draw the same tabs, including their selected state. */
export function layoutNavigation(parent: Node, buttons: Node[], width: number, selected: string): void {
  const itemWidth = (width - 12 * (buttons.length - 1)) / buttons.length;
  parent.setContentSize(width, 76);
  buttons.forEach((node, index) => {
    node.setContentSize(itemWidth, 76);
    node.setPosition(-width / 2 + itemWidth / 2 + index * (itemWidth + 12), 0);
    const active = node.name === selected, graphics = node.getComponent(Graphics)!;
    graphics.clear(); graphics.fillColor = active ? theme.primary : theme.pale;
    graphics.roundRect(-itemWidth / 2, -38, itemWidth, 76, 12); graphics.fill();
    const label = node.getComponentInChildren(Label)!;
    label.fontSize = 26; label.lineHeight = 32;
    label.overflow = Label.Overflow.SHRINK; label.enableWrapText = false;
    label.node.color = active ? theme.paper : theme.primary;
    label.node.setContentSize(itemWidth - 12, 64);
  });
}
