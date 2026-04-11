local M = {}

M.options = {
  auto_build = true,
  project_conf = "vimtex.conf",
  settings_path = "settings.json",
  show_success = false,
}

M.project_settings = {
  default_recipe = "xelatex -> bibtex -> xelatex*2",
  out_dir = nil,
  tools = {
    {
      name = "xelatex",
      command = "xelatex",
      args = {
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-output-directory=%OUTDIR%",
        "%DOCFILE%",
      },
    },
    {
      name = "pdflatex",
      command = "pdflatex",
      args = {
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-output-directory=%OUTDIR%",
        "%DOCFILE%",
      },
    },
    {
      name = "latexmk",
      command = "latexmk",
      args = {
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-pdf",
        "-outdir=%OUTDIR%",
        "%DOCFILE%",
      },
    },
    {
      name = "bibtex",
      command = "bibtex",
      args = {
        "%DOCFILE%",
      },
    },
  },
  recipes = {
    {
      name = "XeLaTeX",
      tools = {
        "xelatex",
      },
    },
    {
      name = "PDFLaTeX",
      tools = {
        "pdflatex",
      },
    },
    {
      name = "BibTeX",
      tools = {
        "bibtex",
      },
    },
    {
      name = "LaTeXmk",
      tools = {
        "latexmk",
      },
    },
    {
      name = "xelatex -> bibtex -> xelatex*2",
      tools = {
        "xelatex",
        "bibtex",
        "xelatex",
        "xelatex",
      },
    },
    {
      name = "pdflatex -> bibtex -> pdflatex*2",
      tools = {
        "pdflatex",
        "bibtex",
        "pdflatex",
        "pdflatex",
      },
    },
  },
}

return M
