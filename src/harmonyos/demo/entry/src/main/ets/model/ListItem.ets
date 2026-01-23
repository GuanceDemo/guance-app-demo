/**
 * Menu item data model
 */
export class MenuItem {
  title: string;
  description: string;
  icon?: ResourceStr;

  constructor(title: string, description: string, icon?: ResourceStr) {
    this.title = title;
    this.description = description;
    this.icon = icon;
  }
}
