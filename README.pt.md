# LÖVR Window Manager

Gerenciador de cenas e telas leve e eficiente para **LÖVR**, feito para navegação simples entre menus, níveis e transições.

## 🚀 Funcionalidades

* **Transições de Cena**: Transições visuais suaves (Fade, Slide, etc.).
* **Passagem de Dados**: Envie objetos de dados entre cenas através do método `load()`.
* **Leve**: Design minimalista, sem dependências externas.
* **Encapsulado**: Modular e fácil de integrar em qualquer projeto LÖVR.

## 🛠️ Instalação

Coloque o módulo na sua pasta `lib/` (ou onde preferir):

```lua
local window_manager = require 'lib.window_manager'
```

## 🎮 Como usar

### 1. Registrar Cenas

Registre as cenas usando `window_manager.register('nome_da_cena', require 'caminho.para.cena')`:

```lua
-- main.lua
local window_manager = require 'lib.window_manager'

function lovr.load()
  window_manager.register('intro', require 'src.intro')
  window_manager.register('menu', require 'src.menu')
  window_manager.register('level', require 'src.level')
  window_manager.switch('intro')
end

function lovr.update(dt)
  window_manager.update(dt)
end

function lovr.draw(pass)
  window_manager.draw(pass)
end
```

Cada cena é um módulo Lua com funções de ciclo de vida opcionais (`load`, `update`, `draw`, `exit`).

```lua
-- src/intro.lua
local window_manager = require 'lib.window_manager'

local intro = {}

function intro.load(lang)
  print("\nCARREGANDO INTRO")
end

function intro.update(dt)
  -- seu código de update aqui
end

function intro.draw(pass)
  pass:text("Esta é a cena de INTRO", 0, 0, -10)
end

function intro.exit()
  -- executado ao mudar para outra cena
end
```

### 2. Trocar de Cena (com Dados)

Você pode passar qualquer objeto Lua (tabelas, strings, números) como parâmetro. O dado é recebido na função `load()` da cena de destino.

```lua
-- Troca para a cena 'game' enviando configurações customizadas
wm.switch('game', 'fade', 0.5, { dificuldade = 'hard', nivel = 1 })

-- Dentro de game.lua
function game.load(data)
  if data then
    print("Iniciando nível: " .. data.nivel)
  end
end
```

## 🔄 Transições

O gerenciador inclui as seguintes transições nativas:

* `wm.Transitions.NONE`
* `wm.Transitions.FADE`
* `wm.Transitions.SLIDE_LEFT`
* `wm.Transitions.SLIDE_RIGHT`
* `wm.Transitions.SLIDE_UP`
* `wm.Transitions.SLIDE_DOWN`

## 📖 Referência da API

| Função | Descrição |
| --- | --- |
| `wm.register(nome, cena)` | Registra um módulo de cena. |
| `wm.switch(nome, tipo, duracao, dados)` | Troca para a cena especificada. |
| `wm.update(dt)` | Atualiza o gerenciador e a cena atual. |
| `wm.draw(pass)` | Desenha a cena atual com transição (se houver). |
