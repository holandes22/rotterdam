const ElmEvents = require("../../elm/events/Main.elm");
const ElmServices = require("../../elm/Services.elm");

import "phoenix_html";
import socket from "./socket";
import NavSideMenu from "./components/nav-side-menu";

ElmEvents.Main.embed(document.getElementById("elm-events"));
ElmServices.Main.embed(document.getElementById("elm-services"));

const navSideMenu = new NavSideMenu("#nav-side-menu");
