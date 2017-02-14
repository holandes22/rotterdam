import "phoenix_html";

import ElmApp from "../../elm/src/Main.elm";

require("vulcanize-loader?es6=false&base=./&watchFiles=./theme.html!./imports.html");

window.Polymer = {
  dom: "shadow",
  lazyRegister: true,
  useNativeCSSProperties: true,
};


window.addEventListener("WebComponentsReady", () => {
  ElmApp.Main.fullscreen(window.__FLAGS__);
});
