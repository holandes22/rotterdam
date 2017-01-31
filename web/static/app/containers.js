import socket from "./socket";
// import React from "react";
// import ReactDOM from "react-dom";
// import ServiceList from "components/service-list.jsx";

let stateChannel = socket.channel("state:docker", {init: "containers"});

// let container = document.getElementById("containers");

let render = function(containers) {
  window.console.log(containers);
  // if (container) {
  //
  //   ReactDOM.render(
  //     React.createElement(ServiceList, { services }),
  //     container
  //   );
  // }
};

stateChannel.on("containers", payload => {
  render(payload.containers);
});

stateChannel
  .join()
  .receive("ok", containers => {
    render(containers);
  })
  .receive("error", resp => { window.console.log("Unable to join to state channel", resp); });
