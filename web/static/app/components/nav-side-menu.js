import { u } from "umbrellajs";

export default class NavSideMenu {
  constructor(selector) {
    this.selector = selector;
    this.menu = u(this.selector);
    this.layout = u("#layout");

    let menuLink = u(`${this.selector} .menu-link`);

    menuLink.on("click", evt => {
      this.menu.toggleClass("active");
      this.layout.toggleClass("active");
      menuLink.toggleClass("active");
    });

  }
}
