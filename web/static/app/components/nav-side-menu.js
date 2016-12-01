import { u } from "umbrellajs";

export default class NavSideMenu {
  constructor(selector) {
    window.console.log("In nav side Menu");
    this.selector = selector;
    this.menu = u(this.selector);

    let menuLink = u(`${this.selector} .menu-link`);

    menuLink.on("click", evt => {
      window.console.log("Toggling");
      this.menu.toggleClass("active");
    });

  }
}
