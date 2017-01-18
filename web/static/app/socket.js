import {Socket} from "phoenix";
import React from "react";
import ReactDOM from "react-dom";
import ServiceList from "components/service-list.jsx";

let socket = new Socket("/socket", {});

socket.connect();

let stateChannel = socket.channel("state:docker", {});

let servicesContainer = document.getElementById("services");

let renderServiceList = function(services) {
  ReactDOM.render(
    React.createElement(ServiceList, { services }),
    servicesContainer
  );
};

stateChannel.on("services", payload => {
  renderServiceList(payload.services);
});

stateChannel
  .join()
  .receive("ok", services => {
    console.log("Joined successfully to state channel", services);
    renderServiceList(services);
  })
  .receive("error", resp => { console.log("Unable to join to state channel", resp); });

export default socket;
