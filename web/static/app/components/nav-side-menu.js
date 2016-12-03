import { u } from "umbrellajs";

export default class NavSideMenu {
  constructor(selector) {
    this.selector = selector;
    this.menu = u(this.selector);
    this.layout = u("#layout");

    let menuLink = u(`${this.selector} a.menu-link`);
    let closeMenu = u(`${this.selector} a.close`);

    menuLink.on("click", evt => {
      this.layout.addClass("active");
      this.menu.addClass("active");
      menuLink.addClass("hidden");
    });

    closeMenu.on("click", evt => {
      this.layout.removeClass("active");
      this.menu.removeClass("active");
      menuLink.removeClass("hidden");
    });



  }
}
