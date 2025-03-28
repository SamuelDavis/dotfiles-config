---------------
-- UTILITIES --
---------------
function vim.snippet.add(trigger, body, opts)
	vim.keymap.set("ia", trigger, function()
		-- If abbrev is expanded with keys like "(", ")", "<cr>", "<space>",
		-- don't expand the snippet. Only accept "<c-]>" as trigger key.
		local c = vim.fn.nr2char(vim.fn.getchar(0))
		if c ~= "" then
			vim.api.nvim_feedkeys(trigger .. c, "i", true)
			return
		end
		vim.snippet.expand(body)
	end, opts)
end

local function set_root_directory()
	local path = vim.fn.argv(0) or vim.fn.expand("%:p:h")
	local stat = vim.loop.fs_stat(path)

	if not stat then
		path = vim.fs.dirname(path)
		stat = vim.loop.fs_stat(path)
	end

	if stat then
		if stat.type == "file" then
			path = vim.fs.dirname(path)
		elseif stat.type == "directory" then
			path = path
		end
	end

	stat = vim.loop.fs_stat(path)
	if not stat or stat.type ~= "directory" then
		return vim.notify("'" .. path .. "' is not a valid path", vim.log.levels.warn)
	end

	local search = vim.fs.find(
		{ ".git", "package.json", "composer.json", "requirements.txt", "project.godot" },
		{ upward = true, path = path }
	)

	if search[1] then
		path = vim.fs.dirname(search[1])
	end

	vim.cmd("cd " .. path)
end

----------
-- INIT --
----------
set_root_directory()

-------------
-- OPTIONS --
-------------
vim.g.mapleader = ","
vim.g.maplocalleader = vim.g.mapleader
vim.g.have_nerd_font = false
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.colorcolumn = "80"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldlevel = 9999
-- vim.cmd.colorscheme("retrobox")
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-------------
-- KEYMAPS --
-------------
local function map(keys, fn, desc, opts, mode)
	opts = opts or {}
	opts.desc = desc
	mode = mode or "n"
	vim.keymap.set(mode, "<leader>" .. keys, fn, opts)
end

local function currymap(prefixed_keys, prefixed_desc)
	return function(keys, fn, desc, opts, mode)
		keys = prefixed_keys .. keys
		desc = prefixed_desc .. " " .. desc
		mode = mode or "n"
		map(keys, fn, desc, opts)
	end
end

local dmap = currymap("d", "[D]iagnostic")
local fmap = currymap("f", "[F]ind")

vim.keymap.set("n", "j", "gj", { noremap = true, silent = true })
vim.keymap.set("n", "k", "gk", { noremap = true, silent = true })
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("x", "<leader>r", ":<C-u>'<,'>s/\\%V", { desc = "Replace in Selection", silent = false })

dmap("o", vim.diagnostic.open_float, "[O]pen Float")
dmap("p", vim.diagnostic.get_prev, "[P]revious")
dmap("n", vim.diagnostic.get_next, "[N]ext")
dmap("l", vim.diagnostic.setloclist, "[L]ist")

-------------
-- PLUGINS --
-------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		error("Error cloning lazy.nvim:\n" .. out)
	end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
	{
		"navarasu/onedark.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("onedark").setup()
			vim.cmd.colorscheme("onedark")
		end,
	},
	{ "windwp/nvim-autopairs", opts = {} },
	{ "tpope/vim-sleuth" },
	{
		"folke/which-key.nvim",
		event = "VimEnter",
		opts = {
			spec = {
				{ "<leader>c", group = "[C]ode", mode = { "n", "x" } },
				{ "<leader>d", group = "[D]iagnostic" },
				{ "<leader>f", group = "[F]ind" },
				{ "<leader>t", group = "[T]oggle" },
				{ "<leader>r", group = "[R]ename" },
				{ "<leader>c", group = "[C]ode" },
				{ "<leader>h", group = "[H]over" },
			},
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")
			telescope.setup({
				defaults = {
					file_ignore_patterns = {
						"venv",
						"__pycache__",
						"node_modules",
						"vendor",
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})
			pcall(telescope.load_extension, "fzf")
			pcall(telescope.load_extension, "ui-select")

			local function current_file()
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end
			local function open_files()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end

			dmap("l", builtin.diagnostics, "[L]ist")
			fmap("h", builtin.help_tags, "[H]elp")
			fmap("k", builtin.keymaps, "[K]eymaps")
			fmap("f", builtin.find_files, "[F]iles")
			fmap("t", builtin.builtin, "[T]elescope")
			fmap("g", builtin.live_grep, "[G]rep")
			fmap("c", builtin.resume, "[C]ontinue")
			fmap("b", builtin.buffers, "[B]uffers")
			fmap("o", builtin.oldfiles, "[O]ld Files")
			fmap(".", current_file, "[.] Current File")
			fmap("..", open_files, "[..] Open Files")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
		opts = {
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = {
				enable = true,
				disable = { "ruby", "gdscript" },
			},
			ensure_installed = {
				"javascript",
				"typescript",
				"tsx",
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/nvim-cmp",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			{ "L3MON4D3/LuaSnip", version = "v2.*" },
			{ "williamboman/mason.nvim", config = true },
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		config = function()
			local cmp = require("cmp")
			local autopairs = require("nvim-autopairs.completion.cmp")
			local lsp = require("lspconfig")
			local tools = require("mason-tool-installer")
			local mason = require("mason-lspconfig")
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local snip = require("luasnip")

			snip.add_snippets("html", {
				snip.snippet("favicon", {
					snip.text_node('<link rel="icon" type="image/png" href="data:image/png;base64,iVBORw0KGgo=">'),
				}),
			})

			local acceptSelection = cmp.mapping(function(fallback)
				if cmp.visible() then
					local entry = cmp.get_selected_entry()
					if not entry then
						cmp.select_next_item({
							behavior = cmp.SelectBehavior.Select,
						})
					end
					cmp.confirm()
				elseif snip.expand_or_jumpable() then
					snip.expand_or_jump()
				else
					fallback()
				end
			end, { "i", "s" })

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
					{ name = "cmdline" },
				}),
			})

			cmp.setup({
				snippet = {
					expand = function(args)
						snip.lsp_expand(args.body)
					end,
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
				}),
				mapping = {
					["<Tab>"] = acceptSelection,
					["<CR>"] = acceptSelection,
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered({
						winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
					}),
				},
			})

			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							diagnostics = {
								globals = { "vim" },
							},
						},
					},
				},
				intelephense = {},
				biome = {},
				ts_ls = {},
				deno = {},
				cssls = {},
				harper_ls = {
					filetypes = { "markdown" },
				},
			}

			cmp.event:on("confirm_done", autopairs.on_confirm_done())

			local ensure_installed = vim.list_extend(vim.tbl_keys(servers or {}), { "stylua", "prettierd", "pint" })
			tools.setup({ ensure_installed = ensure_installed })
			mason.setup({
				handlers = {
					function(name)
						local is_deno = lsp.util.root_pattern("deno.json")(vim.fn.getcwd())

						if name == "ts_ls" and is_deno then
							return
						end
						if name == "denols" and not is_deno then
							return
						end

						local config = servers[name] or {}
						config.capabilities = vim.tbl_deep_extend(
							"force",
							capabilities,
							vim.lsp.protocol.make_client_capabilities(),
							config.capabilities or {}
						)
						config.root_dir = function()
							return vim.fn.getcwd()
						end
						lsp[name].setup(config)
					end,
				},
			})

			lsp.gdscript.setup({})

			local group = vim.api.nvim_create_augroup("lsp-attach", { clear = true })
			vim.api.nvim_create_autocmd("LspAttach", {
				group = group,
				callback = function(event)
					local builtin = require("telescope.builtin")
					fmap("d", builtin.lsp_definitions, "[D]efinition")
					fmap("r", builtin.lsp_references, "[R]eferences")
					fmap("I", builtin.lsp_implementations, "[I]mplementations")
					fmap("T", builtin.lsp_type_definitions, "[T]ype definitions")
					fmap("sw", builtin.lsp_dynamic_workspace_symbols, "[S]ymbols (Workspace)")
					fmap("sd", builtin.lsp_document_symbols, "[S]ymbols ([D]ocument)")
					fmap("D", vim.lsp.buf.declaration, "[D]eclaration")

					map("rn", vim.lsp.buf.rename, "[R]e[N]ame")
					map("ca", vim.lsp.buf.code_action, "[C]ode [A]ction", {}, { "n", "x" })
					map("cf", vim.lsp.buf.format, "[C]ode [F]ormat")
					map("hd", vim.lsp.buf.hover, "[H]over [D]ocumentation")

					local client = vim.lsp.get_client_by_id(event.data.client_id)

					local optional_autocmds = {
						{
							vim.lsp.protocol.Methods.textDocument_documentHighlight,
							function()
								local highlight_augroup =
									vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
								vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
									buffer = event.buf,
									group = highlight_augroup,
									callback = vim.lsp.buf.document_highlight,
								})

								vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
									buffer = event.buf,
									group = highlight_augroup,
									callback = vim.lsp.buf.clear_references,
								})

								vim.api.nvim_create_autocmd("LspDetach", {
									group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
									callback = function(event2)
										vim.lsp.buf.clear_references()
										vim.api.nvim_clear_autocmds({
											group = "lsp-highlight",
											buffer = event2.buf,
										})
									end,
								})
							end,
						},
						{
							vim.lsp.protocol.Methods.textDocument_inlayHint,
							function()
								map("th", function()
									vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({
										bufnr = event.buf,
									}))
								end, "[T]oggle Inlay [H]ints")
							end,
						},
					}

					if client then
						for _, entry in pairs(optional_autocmds) do
							local capability = entry[1]
							local callback = entry[2]
							if client.supports_method(capability) then
								callback()
							end
						end
					end
				end,
			})
		end,
	},
	{
		"stevearc/conform.nvim",
		config = function()
			local conform = require("conform")
			conform.formatters = vim.tbl_extend("force", conform.formatters, {
				ensure_newline = {
					format = function(_, _, lines, callback)
						local out_lines = vim.deepcopy(lines)
						while #out_lines > 0 and out_lines[#out_lines] == "" do
							table.remove(out_lines)
						end
						table.insert(out_lines, "")
						callback(nil, out_lines)
					end,
				},
			})

			conform.setup({
				lsp_format = "fallback",
				format_on_save = {
					timeout_ms = 500,
				},
				formatters_by_ft = {
					lua = { "stylua" },
					javascript = { "prettierd" },
					typescript = { "prettierd" },
					javascriptreact = { "prettierd" },
					typescriptreact = { "prettierd" },
					html = { "prettierd" },
					css = { "prettierd" },
					json = { "prettierd" },
					php = { "pint" },
					gdscript = { "gdformat" },
				},
			})
			map("cc", conform.format, "[C]ode [C]onform")
		end,
	},
})

--------------
-- AUTOCMDS --
--------------
local autosave_group = vim.api.nvim_create_augroup("autosave", { clear = true })
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
	desc = "Autosave on focus lost",
	group = autosave_group,
	callback = function(event)
		if vim.bo.modified then
			require("conform").format({ bufnr = event.buf }, function()
				vim.cmd("silent! write")
			end)
		end
	end,
})

vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NonText", { bg = "NONE" })
vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE" }) -- Make line numbers transparent
vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" }) -- Remove sidebar background
