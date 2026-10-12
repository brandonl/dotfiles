return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "ansiblels",
        "dockerls",
        "docker_compose_language_service",
        "gopls",
        "jsonls",
        "marksman",
        "pyright",
        "terraformls",
        "taplo",
        "yamlls",
      },
    },
  },
}
