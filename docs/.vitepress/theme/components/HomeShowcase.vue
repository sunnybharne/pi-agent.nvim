<script setup>
import { withBase } from "vitepress";
</script>

<template>
  <div class="pi-home-sections">
    <section class="pi-workflow" aria-labelledby="workflow-heading">
      <div class="pi-workflow-copy">
        <p class="pi-kicker">Stay in the flow</p>
        <h2 id="workflow-heading">From selected code to a useful answer in one panel.</h2>
        <p class="pi-lede">
          Pi Agent brings the context you already have open—project, file, cursor, and selection—into a focused assistant built for Neovim.
        </p>

        <div class="pi-signal-list" aria-label="Editor context included with each request">
          <span><b>01</b> Project root</span>
          <span><b>02</b> Active file</span>
          <span><b>03</b> Selected lines</span>
        </div>
      </div>

      <div class="pi-editor" aria-label="Example Pi Agent conversation inside Neovim">
        <div class="pi-editor-bar">
          <div class="pi-window-dots" aria-hidden="true"><i></i><i></i><i></i></div>
          <span>checkout.lua — nvim</span>
          <span class="pi-mode">NORMAL</span>
        </div>

        <div class="pi-editor-body">
          <div class="pi-code-pane" aria-hidden="true">
            <p><span>18</span><code>local function total(items)</code></p>
            <p class="is-selected"><span>19</span><code>  return vim.iter(items)</code></p>
            <p class="is-selected"><span>20</span><code>    :fold(0, function(sum, item)</code></p>
            <p class="is-selected"><span>21</span><code>      return sum + item.price</code></p>
            <p class="is-selected"><span>22</span><code>    end)</code></p>
            <p><span>23</span><code>end</code></p>
          </div>

          <div class="pi-chat-pane">
            <div class="pi-chat-heading">
              <img :src="withBase('/logo.png')" alt="" />
              <span>PI AGENT</span>
            </div>
            <p class="pi-you">You</p>
            <p>Make the selected code null-safe and explain the tradeoff.</p>
            <p class="pi-agent-label">Pi Agent</p>
            <p>Guarding missing prices keeps the fold predictable. Treating them as zero is resilient, but it can hide incomplete data.</p>
            <div class="pi-context-pill">selection · lines 19–22</div>
          </div>
        </div>

        <div class="pi-status-bar">
          <span>pi-agent</span>
          <span><kbd>&lt;leader&gt;cc</kbd> open panel</span>
          <span>lua</span>
        </div>
      </div>
    </section>

    <section class="pi-principles" aria-label="Pi Agent design principles">
      <article>
        <span class="pi-principle-number">01</span>
        <h3>Project-scoped</h3>
        <p>Chats follow the nearest Git root and return when you reopen the project.</p>
      </article>
      <article>
        <span class="pi-principle-number">02</span>
        <h3>Selection-aware</h3>
        <p>Send line-numbered visual selections without copying code into another app.</p>
      </article>
      <article>
        <span class="pi-principle-number">03</span>
        <h3>Runtime-flexible</h3>
        <p>Keep the Neovim surface small while the backend owns model integration.</p>
      </article>
    </section>

    <section class="pi-install-card" aria-labelledby="install-heading">
      <div>
        <p class="pi-kicker">Ready when your buffer is</p>
        <h2 id="install-heading">Add Pi Agent with lazy.nvim.</h2>
        <p>Install the plugin, authenticate once, then open the assistant with <kbd>&lt;leader&gt;cc</kbd>.</p>
        <div class="pi-install-actions">
          <a class="pi-primary-link" :href="withBase('/installation')">Installation guide</a>
          <a class="pi-secondary-link" href="https://github.com/sunnybharne/pi-agent.nvim">View on GitHub</a>
        </div>
      </div>

      <pre aria-label="Minimal lazy.nvim configuration"><code>{
  "sunnybharne/pi-agent.nvim",
  build = "chmod +x bin/pi-agent",
  config = function()
    require("pi_agent").setup()
  end,
}</code></pre>
    </section>
  </div>
</template>
