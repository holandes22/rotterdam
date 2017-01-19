import { u } from "umbrellajs";

export default class NavSideMenu {
  constructor(eventsSelector, linkBarSelector) {
    this.events = u('.box .events');
    this.link = u('#ppp');
    this.linkBar = u('.link-bar');

    this.link.on("click", evt => {
      this.linkBar.toggleClass("active");
      this.events.toggleClass("active");
    });

  }
}
