import "phoenix_html";
import socket from "./socket";
import injectTapEventPlugin from 'react-tap-event-plugin';

import NavSideMenu from "./components/nav-side-menu";
import ElmEvents from "../../elm/events/Main.elm";

injectTapEventPlugin();

ElmEvents.Main.embed(document.getElementById("elm-events"));

const navSideMenu = new NavSideMenu("#nav-side-menu");
