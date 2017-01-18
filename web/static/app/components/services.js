import { u } from "umbrellajs";
import template from "templates/services.hbs";


export default class Services {

  constructor(selector) {
    this.container = u(selector);
  }

  render(services) {
    this.container.html(template({ services }));
  }
}
