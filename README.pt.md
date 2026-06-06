# Gerenciador de Janelas LÖVR (Window Manager)

Um gerenciador de cenas/telas leve e eficiente para **LÖVR**, projetado para uma navegação fluida entre menus, níveis e transições.

## 🚀 Funcionalidades

* **Transições de Cena**: Transições visuais suaves entre cenas (Fade, Slide, etc.).
* **Passagem de Dados**: Transfira facilmente objetos de dados entre cenas através do método de ciclo de vida `load()`.
* **Leve**: Design minimalista e sem dependências externas.
* **Encapsulado**: Projetado para ser modular e fácil de integrar em qualquer projeto LÖVR.

## 🛠️ Instalação

Basta copiar o ficheiro `init.lua` (ou `window_manager.lua`) para a pasta do seu projeto. Recomendamos utilizá-lo como um módulo:

```lua
local wm = require 'window_manager.init'

```

## 🎮 Utilização

### 1. Registar Cenas

Cada cena é um módulo Lua com funções de ciclo de vida opcionais (`load`, `update`, `draw`, `exit`).

```lua
local menu = {
  name = 'menu',
  load = function() print("Menu carregado!") end,
  draw = function(pass) -- Desenhe a sua cena aqui end
}

wm.register('menu', menu)

```

### 2. Trocar de Cenas (com Dados)

Pode passar qualquer objeto Lua (tabelas, strings, números) como parâmetro ao trocar de cena. Os dados são recebidos na função `load()` da cena de destino.

```lua
-- Mudar para a cena 'game' passando uma configuração personalizada
wm.switch('game', 'fade', 0.5, { difficulty = 'hard', level = 1 })

-- Dentro de game.lua
function game.load(data)
  if data then
    print("A iniciar nível: " .. data.level)
  end
end

```

## 🔄 Transições

O gestor inclui transições integradas:

* `wm.Transitions.NONE`
* `wm.Transitions.FADE`
* `wm.Transitions.SLIDE_LEFT`
* `wm.Transitions.SLIDE_RIGHT`
* `wm.Transitions.SLIDE_UP`
* `wm.Transitions.SLIDE_DOWN`

## 📖 Referência da API

| Função | Descrição |
| --- | --- |
| `wm.register(name, scene)` | Regista um módulo de cena. |
| `wm.switch(name, trans, dur, data)` | Muda para uma nova cena, com transição e dados opcionais. |
| `wm.update(dt)` | Atualiza a cena ativa e processa as transições. |
| `wm.draw(pass)` | Renderiza a cena ativa e qualquer transição em curso. |

