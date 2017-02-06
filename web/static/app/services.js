import ElmServices from "../../elm/services/Main.elm";

let container = document.getElementById("services");

window.addEventListener("WebComponentsReady", () => {
  ElmServices.Main.embed(container);
});
