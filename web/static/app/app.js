import "phoenix_html";
import "./services";
import injectTapEventPlugin from "react-tap-event-plugin";

import NavSideMenu from "./components/nav-side-menu";
import ElmEvents from "../../elm/events/Main.elm";

injectTapEventPlugin();

ElmEvents.Main.embed(document.getElementById("elm-events"));

new NavSideMenu("#nav-side-menu");
