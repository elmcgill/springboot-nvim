# Spring Boot NVim

Spring boot NVim is plugin currently under development to simplify the development of Java, specifically Spring Boot projects.

The plugin aims to bring features similar to that of modern Java IDE's such as Intellij and Eclipse to NeoVim.

### Features currently implemented include:

1. Incremental compiling on save, which enables Spring Boot Dev Tools to auto reload your application for rapid development.

2. Start running your Spring Boot project with a simple key mapping rather than starting up a new terminal and running the run command manually.

3. Automatic package declaration when a Java file is created in NeoVim.

4. Class, Interface, and Enum generation to reduce the need to type out boiler plate code.

We are also planning a Spring Boot Project generator based on the Spring Initializer API, as well as features from community feedback.

## Installation

Basic installation requires nvim-lspconfig and nvim-jdtls to auto compile, and gain information from the Java LSP about your project.

```lua
return {
    "elmcgill/springboot-nvim",
    depedencies = {
        "neovim/nvim-lspconfig",
        "mfussenegger/nvim-jdtls"
    },
    config = function()
        local springboot_nvim = require("springboot-nvim")
        springboot_nvim.setup({})
    end
}
```

Recommended installation and configuration

```lua
return {
    "elmcgill/springboot-nvim",
    depedencies = {
        "neovim/nvim-lspconfig",
        "mfussenegger/nvim-jdtls"
    },
    config = function()
        local springboot_nvim = require("springboot-nvim")
        vim.keymap.set('n', '<leader>Jr', springboot_nvim.boot_run, {desc = "Spring Boot Run Project"})
        vim.keymap.set('n', '<leader>Jc', springboot_nvim.generate_class, {desc = "Java Create Class"})
        vim.keymap.set('n', '<leader>Ji', springboot_nvim.generate_interface, {desc = "Java Create Interface"})
        vim.keymap.set('n', '<leader>Je', springboot_nvim.generate_enum, {desc = "Java Create Enum"})
        springboot_nvim.setup({})
    end
}
```

## Contributing

If you have recommendations feel free to create feature requests that we will attempt to get you.

If you would like to contribute please create a new branch and pull request with the new/updated features.
