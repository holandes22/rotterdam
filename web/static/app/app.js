import "phoenix_html";
import socket from "./socket";
import injectTapEventPlugin from "react-tap-event-plugin";
import { u } from "umbrellajs";


// import React from "react";
// import ReactDOM from "react-dom";
// import TestSSR from "./components/test-ssr.jsx";
import NavSideMenu from "./components/nav-side-menu";
import ElmEvents from "../../elm/events/Main.elm";

injectTapEventPlugin();

ElmEvents.Main.embed(document.getElementById("elm-events"), { user: 3 });

new NavSideMenu("#nav-side-menu");

// ReactDOM.render(
//   React.createElement(TestSSR, window.__INITIAL_STATE__),
//   document.getElementById("cluster-select")
// );

let channel = socket.channel("state:activity");

channel.on("loading", () => {
  u("#loader").removeClass("hidden");
});

channel.on("settled", () => {
  u("#loader").addClass("hidden");
});

channel
  .join()
  .receive("ok", () => {
    window.console.log("Joined successfully to loading channel");
  })
  .receive("error", resp => { window.console.log("Unable to join to state:activity channel", resp); });
