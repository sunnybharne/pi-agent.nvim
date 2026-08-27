import DefaultTheme from "vitepress/theme";
import HomeShowcase from "./components/HomeShowcase.vue";
import "./custom.css";

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component("HomeShowcase", HomeShowcase);
  },
};
