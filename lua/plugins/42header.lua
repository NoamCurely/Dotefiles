return {
  "Diogo-ss/42-header.nvim",
  event = "BufEnter *.c,*.h,*.cpp", -- Se charge automatiquement pour les fichiers C/C++
  keys = {
    { "<F1>", mode = "n" }, -- Mapping par défaut
  },
  opts = {
    default_map = true, -- Active le mapping <F1>
    auto_update = true, -- Met à jour le header à la sauvegarde
    user = "nono", -- Remplacez par votre username 42
    mail = "nocurely@gmail.com", -- Remplacez par votre mail 42
    default_settings = { -- Paramètres supplémentaires
      auto_header = true,
      file_type_header = {
        c = "/* ************************************************************************** */",
        h = "/* ************************************************************************** */",
        cpp = "/* ************************************************************************** */",
      },
    },
  },
  config = function(_, opts)
    require("42header").setup(opts)
  end,
}
