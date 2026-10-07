-- Summit: dark slate with a glacier-teal accent.
-- Single-file colourscheme for Neovim 0.12, no plugin dependencies.
-- Matches the Summit themes for bat/delta and Kate; same palette, same mapping.

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "summit"

local c = {
  bg = "#171c23",
  panel = "#1d232c",
  raised = "#28313d",
  border = "#2a333f",

  text = "#dce3ea",
  bright = "#f0f4f8",
  muted = "#8693a1",
  dim = "#5c6773",
  comment = "#6e7a88",

  teal = "#4fd1c5",
  teal_bright = "#81e6d9",
  blue = "#7cb7ff",
  purple = "#b9a3f5",
  green = "#84cc6a",
  amber = "#e3b341",
  red = "#f47067",
  property = "#c5cfd9",

  selection = "#223f44",
  search = "#5a4a1a",
  bracket = "#2f4a4f",

  diff_add = "#1c2e24",
  diff_add_strong = "#2a4a34",
  diff_del = "#33211f",
  diff_del_strong = "#55302c",
}

local function hi(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function link(group, target)
  vim.api.nvim_set_hl(0, group, { link = target })
end

-- Editor ---------------------------------------------------------------------

hi("Normal", { fg = c.text, bg = c.bg })
hi("NormalFloat", { fg = c.text, bg = c.panel })
hi("FloatBorder", { fg = c.border, bg = c.panel })
hi("FloatTitle", { fg = c.teal, bg = c.panel, bold = true })
hi("FloatFooter", { fg = c.muted, bg = c.panel })

hi("Cursor", { fg = c.bg, bg = c.teal })
link("lCursor", "Cursor")
link("CursorIM", "Cursor")
hi("TermCursor", { fg = c.bg, bg = c.teal })
hi("CursorLine", { bg = c.panel })
hi("CursorColumn", { bg = c.panel })
hi("ColorColumn", { bg = c.panel })
hi("CursorLineNr", { fg = c.text })
hi("LineNr", { fg = c.dim })
link("LineNrAbove", "LineNr")
link("LineNrBelow", "LineNr")
hi("SignColumn", { fg = c.dim })
hi("FoldColumn", { fg = c.dim })
link("CursorLineSign", "SignColumn")
link("CursorLineFold", "FoldColumn")
hi("Folded", { fg = c.muted, bg = c.panel })

hi("Visual", { bg = c.selection })
link("VisualNOS", "Visual")
hi("Search", { bg = c.search })
hi("IncSearch", { fg = c.bg, bg = c.amber })
hi("CurSearch", { fg = c.bg, bg = c.amber })
hi("Substitute", { fg = c.bg, bg = c.red })
hi("MatchParen", { bg = c.bracket, bold = true })
hi("QuickFixLine", { bg = c.raised, bold = true })

hi("Pmenu", { fg = c.text, bg = c.panel })
hi("PmenuSel", { fg = c.bright, bg = c.selection })
hi("PmenuKind", { fg = c.muted, bg = c.panel })
hi("PmenuKindSel", { fg = c.property, bg = c.selection })
hi("PmenuExtra", { fg = c.dim, bg = c.panel })
hi("PmenuExtraSel", { fg = c.property, bg = c.selection })
hi("PmenuMatch", { fg = c.teal, bold = true })
hi("PmenuMatchSel", { fg = c.teal_bright, bold = true })
hi("PmenuSbar", { bg = c.raised })
hi("PmenuThumb", { bg = c.dim })
link("PmenuBorder", "FloatBorder")
link("WildMenu", "PmenuSel")
hi("ComplMatchIns", { fg = c.muted })
hi("SnippetTabstop", { bg = c.raised })

hi("StatusLine", { fg = c.text, bg = c.raised })
hi("StatusLineNC", { fg = c.muted, bg = c.panel })
link("StatusLineTerm", "StatusLine")
link("StatusLineTermNC", "StatusLineNC")
hi("TabLine", { fg = c.muted, bg = c.panel })
hi("TabLineFill", { bg = c.panel })
hi("TabLineSel", { fg = c.bright, bg = c.bg, bold = true })
hi("WinBar", { fg = c.text, bold = true })
hi("WinBarNC", { fg = c.muted })
hi("WinSeparator", { fg = c.border })
link("VertSplit", "WinSeparator")

hi("NonText", { fg = c.dim })
hi("EndOfBuffer", { fg = c.border })
hi("Whitespace", { fg = c.border })
hi("SpecialKey", { fg = c.dim })
hi("Conceal", { fg = c.dim })
hi("Directory", { fg = c.blue })
hi("Title", { fg = c.blue, bold = true })

hi("ErrorMsg", { fg = c.red })
hi("WarningMsg", { fg = c.amber })
hi("MoreMsg", { fg = c.teal })
hi("Question", { fg = c.teal })
hi("ModeMsg", { fg = c.text, bold = true })
hi("MsgSeparator", { fg = c.border, bg = c.panel })
hi("OkMsg", { fg = c.green })
hi("StderrMsg", { fg = c.red })
hi("StdoutMsg", { fg = c.text })

hi("DiffAdd", { bg = c.diff_add })
hi("DiffDelete", { fg = c.diff_del_strong, bg = c.diff_del })
hi("DiffChange", { bg = c.raised })
hi("DiffText", { bg = c.search })
hi("DiffTextAdd", { bg = c.diff_add_strong })
hi("Added", { fg = c.green })
hi("Changed", { fg = c.amber })
hi("Removed", { fg = c.red })

hi("SpellBad", { undercurl = true, sp = c.red })
hi("SpellCap", { undercurl = true, sp = c.amber })
hi("SpellLocal", { undercurl = true, sp = c.teal })
hi("SpellRare", { undercurl = true, sp = c.purple })

-- Syntax ---------------------------------------------------------------------

hi("Comment", { fg = c.comment, italic = true })
hi("SpecialComment", { fg = c.muted, italic = true })
hi("Todo", { fg = c.amber, bold = true })

hi("Constant", { fg = c.amber })
hi("Number", { fg = c.amber })
hi("Float", { fg = c.amber })
hi("Boolean", { fg = c.amber })
hi("String", { fg = c.green })
hi("Character", { fg = c.green })

hi("Identifier", { fg = c.text })
hi("Function", { fg = c.blue })

hi("Statement", { fg = c.purple })
hi("Conditional", { fg = c.purple })
hi("Repeat", { fg = c.purple })
hi("Label", { fg = c.purple })
hi("Keyword", { fg = c.purple })
hi("Exception", { fg = c.purple })
hi("Operator", { fg = c.muted })

hi("PreProc", { fg = c.amber })
hi("Define", { fg = c.amber })
hi("Macro", { fg = c.amber })
hi("PreCondit", { fg = c.amber })
hi("Include", { fg = c.purple })

hi("Type", { fg = c.teal })
hi("StorageClass", { fg = c.purple })
hi("Structure", { fg = c.purple })
hi("Typedef", { fg = c.purple })

hi("Special", { fg = c.teal_bright })
hi("SpecialChar", { fg = c.teal_bright })
hi("Tag", { fg = c.red })
hi("Delimiter", { fg = c.muted })
hi("Debug", { fg = c.amber })

hi("Underlined", { fg = c.teal, underline = true })
hi("Ignore", { fg = c.dim })
hi("Error", { fg = c.red })

-- Treesitter -----------------------------------------------------------------

hi("@variable", { fg = c.text })
hi("@variable.builtin", { fg = c.purple, italic = true })
hi("@variable.parameter", { fg = c.text, italic = true })
hi("@variable.parameter.builtin", { fg = c.text, italic = true })
hi("@variable.member", { fg = c.property })
hi("@property", { fg = c.property })

hi("@constant", { fg = c.text })
hi("@constant.builtin", { fg = c.amber })
hi("@constant.macro", { fg = c.amber })
hi("@boolean", { fg = c.amber })
hi("@number", { fg = c.amber })
hi("@number.float", { fg = c.amber })

hi("@module", { fg = c.teal })
hi("@module.builtin", { fg = c.teal })
hi("@label", { fg = c.text })

hi("@string", { fg = c.green })
hi("@string.documentation", { fg = c.comment, italic = true })
hi("@string.regexp", { fg = c.teal_bright })
hi("@string.escape", { fg = c.teal_bright })
hi("@string.special", { fg = c.teal_bright })
hi("@string.special.symbol", { fg = c.amber })
hi("@string.special.path", { fg = c.green })
hi("@string.special.url", { fg = c.teal, underline = true })
hi("@character", { fg = c.green })
hi("@character.special", { fg = c.teal_bright })

hi("@type", { fg = c.teal })
hi("@type.builtin", { fg = c.teal })
hi("@type.definition", { fg = c.teal })
hi("@attribute", { fg = c.amber })
hi("@attribute.builtin", { fg = c.amber })

hi("@function", { fg = c.blue })
hi("@function.builtin", { fg = c.blue })
hi("@function.call", { fg = c.blue })
hi("@function.macro", { fg = c.blue })
hi("@function.method", { fg = c.blue })
hi("@function.method.call", { fg = c.blue })
hi("@constructor", { fg = c.teal })

hi("@operator", { fg = c.muted })
hi("@punctuation.delimiter", { fg = c.muted })
hi("@punctuation.bracket", { fg = c.muted })
hi("@punctuation.special", { fg = c.purple })

hi("@keyword", { fg = c.purple })
hi("@keyword.coroutine", { fg = c.purple })
hi("@keyword.function", { fg = c.purple })
hi("@keyword.operator", { fg = c.purple })
hi("@keyword.import", { fg = c.purple })
hi("@keyword.type", { fg = c.purple })
hi("@keyword.modifier", { fg = c.purple })
hi("@keyword.repeat", { fg = c.purple })
hi("@keyword.return", { fg = c.purple })
hi("@keyword.debug", { fg = c.purple })
hi("@keyword.exception", { fg = c.purple })
hi("@keyword.conditional", { fg = c.purple })
hi("@keyword.conditional.ternary", { fg = c.muted })
hi("@keyword.directive", { fg = c.amber })
hi("@keyword.directive.define", { fg = c.amber })

hi("@comment", { fg = c.comment, italic = true })
hi("@comment.documentation", { fg = c.comment, italic = true })
hi("@comment.error", { fg = c.red, bold = true })
hi("@comment.warning", { fg = c.amber, bold = true })
hi("@comment.todo", { fg = c.amber, bold = true })
hi("@comment.note", { fg = c.blue, bold = true })

hi("@markup.strong", { fg = c.bright, bold = true })
hi("@markup.italic", { fg = c.text, italic = true })
hi("@markup.strikethrough", { strikethrough = true })
hi("@markup.underline", { underline = true })
hi("@markup.heading", { fg = c.blue, bold = true })
for level = 1, 6 do
  hi("@markup.heading." .. level, { fg = c.blue, bold = true })
end
hi("@markup.quote", { fg = c.muted, italic = true })
hi("@markup.math", { fg = c.teal_bright })
hi("@markup.link", { fg = c.teal })
hi("@markup.link.label", { fg = c.teal })
hi("@markup.link.url", { fg = c.teal, underline = true })
hi("@markup.raw", { fg = c.green })
hi("@markup.raw.block", { fg = c.green })
hi("@markup.list", { fg = c.purple })
hi("@markup.list.checked", { fg = c.green })
hi("@markup.list.unchecked", { fg = c.muted })

hi("@diff.plus", { fg = c.green })
hi("@diff.minus", { fg = c.red })
hi("@diff.delta", { fg = c.amber })

hi("@tag", { fg = c.red })
hi("@tag.builtin", { fg = c.red })
hi("@tag.attribute", { fg = c.amber })
hi("@tag.delimiter", { fg = c.muted })

-- Language-specific captures where one generic colour would break the mapping.
hi("@keyword.import.c", { fg = c.amber })
hi("@keyword.import.cpp", { fg = c.amber })
hi("@variable.parameter.bash", { fg = c.amber })
hi("@punctuation.special.python", { fg = c.teal_bright })
hi("@label.markdown", { fg = c.green })
hi("@label.vimdoc", { fg = c.teal })
hi("@markup.link.markdown_inline", { fg = c.muted })
hi("@punctuation.special.markdown", { fg = c.muted })
hi("@keyword.directive.markdown", { fg = c.comment })
hi("@constructor.lua", { fg = c.muted })
-- Keys in data files and CSS property names are blue; CSS selectors and JSX components are teal.
for _, lang in ipairs({ "json", "jsonc", "json5", "yaml", "toml", "css", "scss" }) do
  hi("@property." .. lang, { fg = c.blue })
end
for _, lang in ipairs({ "css", "scss", "tsx", "javascript" }) do
  hi("@tag." .. lang, { fg = c.teal })
end

-- LSP semantic tokens --------------------------------------------------------

link("@lsp.type.class", "@type")
link("@lsp.type.comment", "@comment")
link("@lsp.type.decorator", "@attribute")
link("@lsp.type.enum", "@type")
hi("@lsp.type.enumMember", { fg = c.amber })
link("@lsp.type.event", "@property")
link("@lsp.type.function", "@function")
link("@lsp.type.interface", "@type")
link("@lsp.type.keyword", "@keyword")
link("@lsp.type.macro", "@function.macro")
link("@lsp.type.method", "@function.method")
link("@lsp.type.modifier", "@keyword.modifier")
link("@lsp.type.namespace", "@module")
link("@lsp.type.number", "@number")
link("@lsp.type.operator", "@operator")
link("@lsp.type.parameter", "@variable.parameter")
link("@lsp.type.property", "@property")
link("@lsp.type.regexp", "@string.regexp")
link("@lsp.type.string", "@string")
link("@lsp.type.struct", "@type")
link("@lsp.type.type", "@type")
link("@lsp.type.typeParameter", "@type")
-- Left empty on purpose: plain variables keep the more specific Treesitter colour
-- (this, self, constants) instead of being repainted as generic variables.
hi("@lsp.type.variable", {})

-- Types that servers add on top of the standard set.
link("@lsp.type.selfParameter", "@variable.builtin")
link("@lsp.type.selfKeyword", "@variable.builtin")
link("@lsp.type.clsParameter", "@variable.builtin")
link("@lsp.type.builtinType", "@type.builtin")
link("@lsp.type.typeAlias", "@type")
link("@lsp.type.concept", "@type")
link("@lsp.type.builtinConstant", "@constant.builtin")
link("@lsp.type.boolean", "@boolean")
link("@lsp.type.magicFunction", "@function")
link("@lsp.type.escapeSequence", "@string.escape")
link("@lsp.type.formatSpecifier", "@string.escape")
link("@lsp.type.annotation", "@attribute")
link("@lsp.type.attribute", "@attribute")
link("@lsp.type.label", "@label")
link("@lsp.type.punctuation", "@punctuation.delimiter")

link("@lsp.typemod.variable.defaultLibrary", "@variable")
link("@lsp.typemod.variable.global", "@variable")
link("@lsp.typemod.function.defaultLibrary", "@function.builtin")
link("@lsp.typemod.method.defaultLibrary", "@function.builtin")
link("@lsp.typemod.type.defaultLibrary", "@type.builtin")
link("@lsp.typemod.class.defaultLibrary", "@type.builtin")
hi("@lsp.mod.deprecated", { strikethrough = true })

hi("LspReferenceText", { bg = c.raised })
hi("LspReferenceRead", { bg = c.raised })
hi("LspReferenceWrite", { bg = c.raised })
hi("LspReferenceTarget", { bg = c.raised })
hi("LspInlayHint", { fg = c.dim, italic = true })
hi("LspCodeLens", { fg = c.dim })
hi("LspCodeLensSeparator", { fg = c.border })
hi("LspSignatureActiveParameter", { bg = c.selection, bold = true })

-- Diagnostics ----------------------------------------------------------------

local diagnostics = {
  Error = c.red,
  Warn = c.amber,
  Info = c.blue,
  Hint = c.teal,
  Ok = c.green,
}

for name, colour in pairs(diagnostics) do
  hi("Diagnostic" .. name, { fg = colour })
  hi("DiagnosticVirtualText" .. name, { fg = colour })
  hi("DiagnosticVirtualLines" .. name, { fg = colour })
  hi("DiagnosticUnderline" .. name, { undercurl = true, sp = colour })
  hi("DiagnosticSign" .. name, { fg = colour })
  hi("DiagnosticFloating" .. name, { fg = colour, bg = c.panel })
end
hi("DiagnosticDeprecated", { strikethrough = true, sp = c.muted })
hi("DiagnosticUnnecessary", { fg = c.dim })

-- Runtime syntax files -------------------------------------------------------
-- Without a Treesitter parser Neovim falls back to its bundled syntax files, whose
-- default links do not follow the mapping (HTML tags as statements, JSON keys as
-- labels, TypeScript built-in methods as keywords). Group names below are the ones
-- shipped in the 0.12 runtime; each is linked to the group that carries its colour.

local runtime = {
  Tag = [[htmlTagName htmlSpecialTagName xmlTagName tsxNameSpace]],

  ["@tag.attribute"] = [[htmlArg xmlAttrib tsxAttrib shOption]],

  Delimiter = [[htmlTag htmlEndTag xmlTag xmlEndTag xmlAttribPunct xmlProcessingDelim xmlCdataStart xmlCdataEnd
    xmlDocTypeDecl tsxCloseString javaScriptBraces typescriptBraces typescriptParens typescriptEndColons
    typescriptTypeAnnotation typescriptObjectColon typescriptDotNotation typescriptOptionalMark typescriptBinaryOp
    typescriptUnaryOp typescriptTernaryOp typescriptAssign typescriptRestOrSpread typescriptDefaultParam jsonNoise
    jsonQuote yamlKeyValueDelimiter yamlFlowIndicator yamlMappingKeyStart yamlBlockScalarHeader
    yamlBlockCollectionItemStart yamlDocumentStart yamlDocumentEnd cssBraces cssSelectorOp cssSelectorOp2
    cssAttrComma cssNoise markdownRule markdownLinkDelimiter markdownLinkTextDelimiter markdownIdDelimiter]],

  ["@property"] = [[javaScriptMember typescriptMember typescriptProp typescriptObjectLabel
    typescriptDestructureLabel typescriptBOMWindowProp goField]],

  Type = [[tsxTagName cssTagName cssClassName cssClassNameDot cssIdentifier cssPseudoClassId
    cssAttributeSelector pythonClass pythonExceptions javaScriptGlobal typescriptGlobal
    typescriptNodeGlobal typescriptBOM typescriptBOMWindowCons typescriptXHRGlobal typescriptCryptoGlobal
    typescriptEncodingGlobal typescriptDOMEventCons typescriptInterfaceName typescriptClassName
    typescriptClassHeritage typescriptTypeReference typescriptTypeParameter typescriptAliasDeclaration
    typescriptEnum]],

  Keyword = [[pythonOperator javaScriptIdentifier javaScriptOperator typescriptOperator typescriptKeywordOp
    typescriptEnumKeyword typescriptUsing typescriptCastKeyword typescriptMappedIn typescriptAbstract
    typescriptArrowFunc typescriptFuncTypeArrow typescriptMethodAccessor typescriptTemplateSB cssAtKeyword
    cssAtRule cssImportant cssUnitDecorators markdownListMarker markdownOrderedListMarker]],

  Function = [[goBuiltins goFunctionCall javaScriptMessage typescriptMessage typescriptGlobalMethod
    typescriptBOMWindowMethod shStatement]],

  -- Keys and section headers in data files, and CSS property names, are blue.
  SummitKey = [[jsonKeyword yamlMappingKey yamlFlowMappingKey yamlBlockMappingKey tomlKey tomlKeySq tomlKeyDq
    tomlTable tomlTableArray cssProp cssVendor]],

  Constant = [[pythonBoolean pythonConstant jsonNull javaScriptNull javaScriptConstant]],

  PreProc = [[cInclude pythonDecoratorName typescriptDecorator xmlProcessing goBuildDirectives yamlDirectiveName]],

  Special = [[xmlEntity xmlEntityPunct javaScriptRegexpString]],

  Identifier = [[typescriptFuncCallArg typescriptDestructureVariable goVarAssign goVarDefs shDerefSimple shDeref
    shDerefVar shVariable cssCustomProp]],

  String = [[shQuote yamlPlainScalar markdownCode markdownCodeBlock markdownCodeDelimiter
    typescriptBOMWindowEvent typescriptPaymentEvent]],

  ["@variable.parameter"] = [[typescriptCall typescriptParamImpl typescriptArrowFuncArg goParamName
    goReceiverVar]],

  ["@variable.builtin"] = [[pythonClassVar]],
  ["@markup.quote"] = [[markdownBlockquote]],
  ["@markup.link.label"] = [[markdownLinkText markdownId markdownIdDeclaration]],
  ["@markup.link.url"] = [[markdownUrl markdownAutomaticLink]],
  ["@markup.heading"] = [[markdownHeadingDelimiter markdownHeadingRule gitcommitSummary]],
}

hi("SummitKey", { fg = c.blue })

for target, names in pairs(runtime) do
  for name in names:gmatch("%S+") do
    link(name, target)
  end
end

-- TypeScript and TSX ship one group per built-in API; by default all link to Keyword or Title.
local typescript = {
  Function = [[ArrayMethod ArrayStaticMethod BOMHistoryMethod BOMLocationMethod BOMNavigatorMethod BlobMethod
    CacheMethod ConsoleMethod CryptoMethod DOMDocMethod DOMElemFuncs DOMEventMethod DOMEventTargetMethod
    DOMFormMethod DOMNodeMethod DOMStorageMethod DateMethod DateStaticMethod ES6MapMethod ES6SetMethod
    EncodingMethod FileListMethod FileMethod FileReaderMethod FunctionMethod GeolocationMethod HeadersMethod
    IntlMethod JSONStaticMethod MathStaticMethod NumberMethod NumberStaticMethod ObjectMethod ObjectStaticMethod
    PaymentMethod PaymentResponseMethod PromiseMethod PromiseStaticMethod ProxyAPI ReflectMethod RegExpMethod
    RequestMethod ResponseMethod ServiceWorkerMethod StringMethod StringStaticMethod SubtleCryptoMethod
    SymbolStaticMethod URLStaticMethod XHRMethod]],

  ["@property"] = [[BOMHistoryProp BOMLocationProp BOMNavigatorProp BOMNetworkProp CryptoProp DOMDocProp
    DOMElemAttrs DOMEventProp DOMFormProp DOMNodeProp DOMNodeType DOMStorage DOMStorageProp DOMStyle ES6MapProp
    ES6SetProp EncodingProp FileReaderProp MathStaticProp NumberStaticProp PaymentAddressProp PaymentProp
    PaymentResponseProp PaymentShippingOptionProp RegExpProp RegExpStaticProp RequestProp ResponseProp
    ServiceWorkerProp SymbolStaticProp URLUtilsProp XHRProp]],

  String = [[AnimationEvent CSSEvent DOMMutationEvent DatabaseEvent DocumentEvent DragEvent ElementEvent
    FocusEvent FormEvent FrameEvent InputDeviceEvent MediaEvent MenuEvent NetworkEvent ProgressEvent
    ResourceEvent SVGEvent ScriptEvent SensorEvent ServiceWorkerEvent SessionHistoryEvent StorageEvent TabEvent
    TextEvent TouchEvent UncategorizedEvent UpdateEvent ValueChangeEvent ViewEvent WebsocketEvent WindowEvent]],
}

for target, names in pairs(typescript) do
  for name in names:gmatch("%S+") do
    link("typescript" .. name, target)
  end
end

-- Documentation tags inside comments keep the comment's italics.
hi("typescriptDocNotation", { fg = c.purple, italic = true })
hi("typescriptDocTags", { fg = c.purple, italic = true })
hi("typescriptDocParam", { fg = c.muted, italic = true })
hi("typescriptDocNumParam", { fg = c.muted, italic = true })
hi("typescriptDocParamName", { fg = c.muted, italic = true })

-- Diff: old file red, new file green, other headers and hunk ranges purple.
hi("diffFile", { fg = c.purple })
hi("diffOldFile", { fg = c.red })
hi("diffNewFile", { fg = c.green })
hi("diffLine", { fg = c.purple })
hi("diffSubname", { fg = c.text })
hi("diffIndexLine", { fg = c.muted })

-- Terminal -------------------------------------------------------------------

vim.g.terminal_color_0 = "#28313d"
vim.g.terminal_color_1 = "#f47067"
vim.g.terminal_color_2 = "#84cc6a"
vim.g.terminal_color_3 = "#e3b341"
vim.g.terminal_color_4 = "#7cb7ff"
vim.g.terminal_color_5 = "#b9a3f5"
vim.g.terminal_color_6 = "#4fd1c5"
vim.g.terminal_color_7 = "#c5cfd9"
vim.g.terminal_color_8 = "#5c6773"
vim.g.terminal_color_9 = "#ff8a80"
vim.g.terminal_color_10 = "#a0e088"
vim.g.terminal_color_11 = "#f2c968"
vim.g.terminal_color_12 = "#9ccaff"
vim.g.terminal_color_13 = "#d0bfff"
vim.g.terminal_color_14 = "#81e6d9"
vim.g.terminal_color_15 = "#f0f4f8"
