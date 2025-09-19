local jdtls = require "jdtls"

local data_path = vim.fn.stdpath("data")
local config_path = vim.fn.stdpath("config")

local jdtls_home = vim.fs.joinpath(data_path, "mason", "packages", "jdtls")
local lombok_jar = vim.fs.joinpath(jdtls_home, "lombok.jar")

-- java全局首选项
local java_settings_url = vim.fs.joinpath(config_path, "lua", "fengwk", "lsp", "jdtls", "org.eclipse.jdt.core.prefs")

local java_home_preset = {
  java_home_5 = os.getenv("JAVA_HOME_5") or "",
  java_home_6 = os.getenv("JAVA_HOME_6") or "",
  java_home_7 = os.getenv("JAVA_HOME_7") or "",
  java_home_8 = os.getenv("JAVA_HOME_8") or "",
  java_home_9 = os.getenv("JAVA_HOME_9") or "",
  java_home_10 = os.getenv("JAVA_HOME_10") or "",
  java_home_11 = os.getenv("JAVA_HOME_11") or "",
  java_home_12 = os.getenv("JAVA_HOME_12") or "",
  java_home_13 = os.getenv("JAVA_HOME_13") or "",
  java_home_14 = os.getenv("JAVA_HOME_14") or "",
  java_home_15 = os.getenv("JAVA_HOME_15") or "",
  java_home_16 = os.getenv("JAVA_HOME_16") or "",
  java_home_17 = os.getenv("JAVA_HOME_17") or "",
  java_home_18 = os.getenv("JAVA_HOME_18") or "",
  java_home_19 = os.getenv("JAVA_HOME_19") or "",
  java_home_20 = os.getenv("JAVA_HOME_20") or "",
  java_home_21 = os.getenv("JAVA_HOME_21") or "",
  java_home_22 = os.getenv("JAVA_HOME_22") or "",
}

local runtimes_preset = {
  {
    name = "J2SE-1.5",
    path = java_home_preset.java_home_5,
  },
  {
    name = "JavaSE-1.6",
    path = java_home_preset.java_home_6,
    sources = vim.fs.joinpath(java_home_preset.java_home_6, "src.zip"),
    javadoc = "https://docs.oracle.com/javase/6/docs/api",
  },
  {
    name = "JavaSE-1.7",
    path = java_home_preset.java_home_7,
    sources = vim.fs.joinpath(java_home_preset.java_home_7, "src.zip"),
    javadoc = "https://docs.oracle.com/javase/7/docs/api",
  },
  {
    name = "JavaSE-1.8",
    path = java_home_preset.java_home_8,
    sources = vim.fs.joinpath(java_home_preset.java_home_8, "src.zip"),
    javadoc = "https://docs.oracle.com/javase/8/docs/api",
    default = true,
  },
  {
    name = "JavaSE-9",
    path = java_home_preset.java_home_9,
    sources = vim.fs.joinpath(java_home_preset.java_home_9, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/9/docs/api",
  },
  {
    name = "JavaSE-10",
    path = java_home_preset.java_home_10,
    sources = vim.fs.joinpath(java_home_preset.java_home_10, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/10/docs/api",
  },
  {
    name = "JavaSE-11",
    path = java_home_preset.java_home_11,
    sources = vim.fs.joinpath(java_home_preset.java_home_11, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/11/docs/api",
  },
  {
    name = "JavaSE-12",
    path = java_home_preset.java_home_12,
    sources = vim.fs.joinpath(java_home_preset.java_home_12, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/12/docs/api",
  },
  {
    name = "JavaSE-13",
    path = java_home_preset.java_home_13,
    sources = vim.fs.joinpath(java_home_preset.java_home_13, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/13/docs/api",
  },
  {
    name = "JavaSE-14",
    path = java_home_preset.java_home_14,
    sources = vim.fs.joinpath(java_home_preset.java_home_14, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/14/docs/api",
  },
  {
    name = "JavaSE-15",
    path = java_home_preset.java_home_15,
    sources = vim.fs.joinpath(java_home_preset.java_home_15, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/15/docs/api",
  },
  {
    name = "JavaSE-16",
    path = java_home_preset.java_home_16,
    sources = vim.fs.joinpath(java_home_preset.java_home_16, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/16/docs/api",
  },
  {
    name = "JavaSE-17",
    path = java_home_preset.java_home_17,
    sources = vim.fs.joinpath(java_home_preset.java_home_17, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/17/docs/api",
  },
  {
    name = "JavaSE-18",
    path = java_home_preset.java_home_18,
    sources = vim.fs.joinpath(java_home_preset.java_home_18, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/18/docs/api",
  },
  {
    name = "JavaSE-19",
    path = java_home_preset.java_home_19,
    sources = vim.fs.joinpath(java_home_preset.java_home_19, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/19/docs/api",
  },
  {
    name = "JavaSE-20",
    path = java_home_preset.java_home_20,
    sources = vim.fs.joinpath(java_home_preset.java_home_20, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/20/docs/api",
  },
  {
    name = "JavaSE-21",
    path = java_home_preset.java_home_21,
    sources = vim.fs.joinpath(java_home_preset.java_home_21, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/21/docs/api",
  },
  {
    name = "JavaSE-22",
    path = java_home_preset.java_home_22,
    sources = vim.fs.joinpath(java_home_preset.java_home_22, "lib", "src.zip"),
    javadoc = "https://docs.oracle.com/javase/22/docs/api",
  },
}

local function build_runtimes()
  local runtimes = {}
  for _, item in pairs(runtimes_preset) do
    if item.path ~= nil then
      table.insert(runtimes, item)
    end
  end
  return runtimes
end

local function build_conf(base_conf, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local current_buf_filename = vim.api.nvim_buf_get_name(bufnr)

  local found = vim.fs.find({
    "build.xml",           -- Ant
    "mvnw",                -- Maven
    "pom.xml",             -- Maven
    "settings.gradle",     -- Gradle
    "settings.gradle.kts", -- Gradle
    "gradlew",             -- Gradle
  }, { path = current_buf_filename, limit = math.huge, upward = true })

  local root_dir = found and #found > 0 and vim.fs.dirname(found[#found]) or nil

  local jdtls_cmd = vim.fs.joinpath(jdtls_home, "jdtls")

  local bundles = {}
  -- debug插件
  -- https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
  vim.list_extend(bundles,
    vim.split(
      vim.fn.glob(vim.fs.joinpath(data_path, "mason", "packages", "java-debug-adapter", "extension", "server", "*.jar")),
      "\n"))
  -- 单元测试插件
  vim.list_extend(bundles,
    vim.split(vim.fn.glob(vim.fs.joinpath(data_path, "mason", "packages", "java-test", "extension", "server", "*.jar")),
      "\n"))
  -- eclipse插件支持
  -- https://github.com/eclipse/eclipse.jdt.ls/blob/master/CONTRIBUTING.md
  vim.list_extend(bundles,
    vim.split(
      vim.fn.glob(vim.fs.joinpath(config_path, "lib", "eclipse-pde", "*.jar")),
      "\n"))

  local extendedClientCapabilities = vim.tbl_extend("force", jdtls.extendedClientCapabilities, {
    resolveAdditionalTextEditsSupport = true,
  });

  return vim.tbl_extend('force', base_conf, {
    root_dir = root_dir,
    capabilities = base_conf.capabilities and base_conf.capabilities or vim.lsp.protocol.make_client_capabilities(),

    cmd = {
      'env',
      'JAVA_HOME=' .. java_home_preset.java_home_21,
      jdtls_cmd,
      "--jvm-arg=-javaagent:" .. lombok_jar,
      "--jvm-arg=-Xmx4g",
      "--jvm-arg=-XX:+UseZGC",    -- ZGC
      "--jvm-arg=-XX:+ZUncommit", -- 允许将未使用的内存归还给操作系统
    },

    on_attach = function(client, bufnr)
      if base_conf and base_conf.on_attach then
        base_conf.on_attach(client, bufnr)
      end

      -- jdtls 特性

      jdtls.setup_dap { hotcodereplace = "auto" }

      -- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
      -- 注册用于调试的主类，如果是新增的main方法需要使用:JdtRefreshDebugConfigs命令刷新
      require "jdtls.dap".setup_dap_main_class_configs()
      -- 注册调试命令
      vim.api.nvim_create_user_command("JdtTestClass",
        function() require("jdtls").test_class() end, {})
      vim.api.nvim_create_user_command("JdtTestMethod",
        function() require("jdtls").test_nearest_method() end, {})
      vim.api.nvim_create_user_command("JdtRemoteDebug",
        function() require("fengwk.lsp.jdtls.enhancer").remote_debug() end, {})
      vim.api.nvim_create_user_command("JdtDebug",
        function() require("fengwk.lsp.jdtls.enhancer").debug() end, {})

      -- 拷贝引用
      vim.api.nvim_create_user_command("JdtCopyReference", function()
        require("fengwk.lsp.jdtls.enhancer").copy_reference()
      end, {})

      -- 设置jdt的扩展快捷键，跳转到父类或接口
      vim.keymap.set("n", "gp", "<Cmd>lua require'jdtls'.super_implementation()<CR>",
        { silent = true, buffer = bufnr, desc = "Lsp Super Implementation" })
      -- inherited_members扩展
      vim.keymap.set("n", "gS", "<Cmd>Telescope jdtls inherited_members<CR>",
        { silent = true, buffer = bufnr, desc = "Lsp Inherited Members" })

      -- 刷新配置
      vim.keymap.set("n", "<leader>rr", "<Cmd>JdtUpdateConfig<CR>",
        { silent = true, buffer = bufnr, desc = "Lsp Update Config" })
    end,

    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = "fernflower" },
        completion = {
          -- 这些包使用静态成员
          favoriteStaticMembers = {
            "org.hamcrest.MatcherAssert.assertThat",
            "org.hamcrest.Matchers.*",
            "org.hamcrest.CoreMatchers.*",
            "org.junit.jupiter.api.Assertions.*",
            "java.util.Objects.requireNonNull",
            "java.util.Objects.requireNonNullElse",
            "org.mockito.Mockito.*"
          },
          -- 推测方法参数进行补全
          guessMethodArguments = true,
        },
        sources = {
          -- 低于指定阈值，不在import中使用*
          organizeImports = {
            starThreshold = 5,
            staticStarThreshold = 5,
          },
        },
        configuration = {
          -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
          -- And search for `interface RuntimeOption`
          -- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
          runtimes = build_runtimes(),
        },
        format = {
          enabled = true,
          -- 插入空格而不是tab
          insertSpaces = true,
        },
        settings = {
          -- https://github.com/eclipse/eclipse.jdt.ls/issues/1892#issuecomment-929715918
          -- https://github.com/redhat-developer/vscode-java/wiki/Settings-Global-Preferences
          url = java_settings_url
        },
        maven = {
          downloadSources = true,
          updateSnapshots = true,
        },
        -- https://github.com/redhat-developer/vscode-java/issues/1470
        -- https://github.com/redhat-developer/vscode-java/wiki/Predefined-Variables-for-Java-Template-Snippets
        templates = {
          typeComment = {
            "/**",
            " * ${type_name}",
            " * @author ${user}",
            " */",
          },
        },
      },
    },

    init_options = {
      bundles = bundles,
      extendedClientCapabilities = extendedClientCapabilities,
    },
  })
end

local function setup(base_conf)
  local function start_or_attach(bufnr)
    local conf = build_conf(base_conf, bufnr)
    jdtls.start_or_attach(conf)
  end

  local group = vim.api.nvim_create_augroup("user_jdtls_setup", { clear = true })
  -- java or ant 文件启动 jdtls
  vim.api.nvim_create_autocmd(
    { "FileType" },
    {
      group = group,
      pattern = "java,ant",
      callback = function(args)
        local bufnr = args.buf
        start_or_attach(bufnr)
      end
    })
  -- pom.xml文件启动jdtls
  vim.api.nvim_create_autocmd(
    { "FileType" },
    {
      group = group,
      pattern = "xml",
      callback = function(args)
        local name = vim.fn.expand("%:t")
        if name == "pom.xml" then
          local bufnr = args.buf
          start_or_attach(bufnr)
        end
      end
    })
end

return setup
