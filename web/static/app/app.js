import "phoenix_html";
import socket from "./socket";

import NavSideMenu from "./components/nav-side-menu";

import ElmEvents from "../../elm/events/Main.elm";

ElmEvents.Main.embed(document.getElementById("elm-events"));

const navSideMenu = new NavSideMenu("#nav-side-menu");
