import "phoenix_html";
import socket from "./socket";

import NavSideMenu from "./components/nav-side-menu";

import ElmEvents from "../../elm/events/Main.elm";
import ElmServices from "../../elm/Services.elm";

ElmEvents.Main.embed(document.getElementById("elm-events"));
ElmServices.Main.embed(document.getElementById("elm-services"));

const navSideMenu = new NavSideMenu("#nav-side-menu");
