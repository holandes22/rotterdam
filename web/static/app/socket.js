import {Socket} from "phoenix";
import Services from "components/services";

let socket = new Socket("/socket", {});

socket.connect();

let stateChannel = socket.channel("state:docker", {});

stateChannel.on("services", payload => {
  console.log(payload);
});

stateChannel
  .join()
  .receive("ok", services => {
    console.log("Joined successfully to state channel", services);
    let s = new Services("#services");
    s.render(services);

  })
  .receive("error", resp => { console.log("Unable to join to state channel", resp); });

export default socket;
