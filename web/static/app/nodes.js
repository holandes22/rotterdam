import socket from "./socket";
import React from "react";
import ReactDOM from "react-dom";
import NodeList from "components/node-list.jsx";

let stateChannel = socket.channel("state:docker", {init: "nodes"});


let renderNodeList = function(nodes) {
  let container = document.getElementById("nodes");
  if (container) {

    ReactDOM.render(
      React.createElement(NodeList, { nodes }),
      container
    );

  }
};

stateChannel.on("nodes", payload => {
  renderNodeList(payload.nodes);
});

stateChannel
  .join()
  .receive("ok", nodes => {
    window.console.log("Joined successfully to state channel", nodes);
    renderNodeList(nodes);
  })
  .receive("error", resp => { window.console.log("Unable to join to state channel", resp); });
