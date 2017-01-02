import {Socket} from "phoenix";

let socket = new Socket("/socket", {});

socket.connect();

let eventsChannel = socket.channel("events:docker", {});

eventsChannel.on("event", payload => {
  console.log(payload.RotterdamNodeLabel);
});

eventsChannel
  .join()
  .receive("ok", resp => { console.log("Joined successfully to events channel", resp); })
  .receive("error", resp => { console.log("Unable to join to events channel", resp); });

export default socket;
