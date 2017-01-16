import { u } from "umbrellajs";

export default class NavSideMenu {
  constructor(selector) {
    this.selector = selector;
    this.menu = u(this.selector);
    this.layout = u("#layout");

    this.menuLink = u(`${this.selector} a.link`);
    this.closeMenu = u(`${this.selector} a.close`);

    this.menuLink.on("click", evt => {
      this.layout.addClass("active");
      this.menu.addClass("active");
      this.menuLink.addClass("hidden");
    });

    this.closeMenu.on("click", evt => {
      this.layout.removeClass("active");
      this.menu.removeClass("active");
      this.menuLink.removeClass("hidden");
    });



  }
}
