import socket from "./socket";
import React from "react";
import ReactDOM from "react-dom";
import ServiceList from "components/service-list.jsx";

let stateChannel = socket.channel("state:docker", {init: "services"});


let renderServiceList = function(services) {
  let container = document.getElementById("services");
  if (container) {
    ReactDOM.render(
      React.createElement(ServiceList, { services }),
      container
    );
  }
};

stateChannel.on("services", payload => {
  renderServiceList(payload.services);
});

stateChannel
  .join()
  .receive("ok", services => {
    window.console.log("Joined successfully to state channel", services);
    renderServiceList(services);
  })
  .receive("error", resp => { window.console.log("Unable to join to state channel", resp); });
