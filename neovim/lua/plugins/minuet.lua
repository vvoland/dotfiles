return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    lazy = false,
    priority = 100,
    config = function()
      local secrets = require("secrets")
      require("minuet").setup {
        -- provider = "openai",
        provider = "openai_fim_compatible",
        context_window = 512,
        request_tieout = 9000,
        provider_options = {
          claude = {
            model = "claude-sonnet-4-0",
            api_key = secrets.pass_func("Anthropic")
          },
          openai = {
            model = "gpt-4o",
            stream = true,
            api_key = secrets.pass_func("OpenAI"),
          },
          openai_fim_compatible = {
            -- For Windows users, TERM may not be present in environment variables.
            -- Consider using APPDATA instead.
            api_key = "TERM",
            name = "Llama.cpp",
            end_point = "http://localhost:8012/v1/completions",
            -- The model is set by the llama-cpp server and cannot be altered
            -- post-launch.
            model = "PLACEHOLDER",
            optional = {
              max_tokens = 56,
              top_p = 0.9,
            },
            -- Llama.cpp does not support the `suffix` option in FIM completion.
            -- Therefore, we must disable it and manually populate the special
            -- tokens required for FIM completion.
            template = {
              prompt = function(context_before_cursor, context_after_cursor, _)
                return "<|fim_prefix|>"
                .. context_before_cursor
                .. "<|fim_suffix|>"
                .. context_after_cursor
                .. "<|fim_middle|>"
              end,
              suffix = false,
            },
          },
        },
      }
    end,
  }
}
