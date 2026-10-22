# LÖVR Window Manager

Gerenciador de cenas e telas leve e eficiente para **LÖVR**, feito para navegação simples entre menus, níveis e transições.

## 🚀 Funcionalidades

* **Transições de Cena**: Transições visuais suaves (Fade, Slide, etc.).
* **Passagem de Dados**: Envie objetos de dados entre cenas através do método `load()`.
* **Eventos da Engine**: Teclado, mouse, texto, foco, visibilidade e redimensionamento podem ser encaminhados para a cena ativa.
* **Fábricas de Cenas**: Registre uma função para criar uma cena nova a cada visita.
* **Leve**: Design minimalista, sem dependências externas.
* **Encapsulado**: Modular e fácil de integrar em qualquer projeto LÖVR.

## 🛠️ Instalação

Coloque o módulo na sua pasta `lib/` (ou onde preferir):

```lua
local window_manager = require 'lib.window_manager'
```

Neste repositório o módulo fica na raiz do projeto, então o `main.lua` da demo
usa `require 'init'`. Ao copiar o módulo, use o caminho escolhido de forma
consistente no ponto de entrada e em qualquer cena que chame o gerenciador.

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

Você pode passar qualquer objeto Lua (tabelas, strings, números) como
parâmetro. O dado é recebido na função `load()` da cena de destino.

```lua
-- Troca para 'game' com transição e configuração explícitas
window_manager.switch('game', {
  transition = window_manager.Transitions.FADE,
  duration = 0.5,
  data = { dificuldade = 'hard', nivel = 1 },
})

-- Dentro de game.lua
function game.load(data)
  if data then
    print("Iniciando nível: " .. data.nivel)
  end
end
```

A forma posicional antiga continua funcionando:
`window_manager.switch('game', 'fade', 0.5, { dificuldade = 'hard' })`.
Omitir as opções usa `default_transition` e `transition_duration`.

### 3. Fábricas de Cenas

Uma tabela registrada é um singleton, então o estado em variáveis locais do
módulo persiste entre visitas. Registre uma função para criar uma cena nova a
cada troca:

```lua
local function new_level()
  local level = {timer = 0}

  function level.load(data)
    level.timer = 0
  end

  function level.update(dt)
    level.timer = level.timer + dt
  end

  return level
end

window_manager.register('level', new_level)
```

A fábrica é chamada toda vez que a cena é ativada. Use uma tabela comum quando
o estado compartilhado for intencional.

### 4. Eventos da Engine

O gerenciador não registra os callbacks da LÖVR sozinho. Repasse os eventos
que as cenas devem receber a partir do ponto de entrada. O teclado tem
encaminhadores dedicados:

```lua
function lovr.keypressed(key, scancode, isrepeat)
  window_manager.keypressed(key, scancode, isrepeat)
end

function lovr.keyreleased(key, scancode)
  window_manager.keyreleased(key, scancode)
end
```

O mesmo padrão vale para os outros eventos:

```lua
function lovr.mousepressed(...) window_manager.mousepressed(...) end
function lovr.mousereleased(...) window_manager.mousereleased(...) end
function lovr.mousemoved(...) window_manager.mousemoved(...) end
function lovr.wheelmoved(...) window_manager.wheelmoved(...) end
function lovr.textinput(...) window_manager.textinput(...) end
function lovr.focus(...) window_manager.focus(...) end
function lovr.visible(...) window_manager.visible(...) end
function lovr.resize(...) window_manager.resize(...) end
```

As cenas podem então implementar os hooks opcionais correspondentes:

```lua
function level.keypressed(key, scancode, isRepeat) end
function level.mousemoved(x, y, dx, dy, istouch) end
function level.focus(focused, display) end
```

Para um evento customizado, chame `dispatch` diretamente:

```lua
function lovr.filechanged(...)
  window_manager.dispatch('filechanged', ...)
end
```

Cenas que declaram apenas `keyreleased(key)` continuam funcionando.

## 🔄 Transições

O gerenciador inclui as seguintes transições nativas:

* `window_manager.Transitions.NONE`
* `window_manager.Transitions.FADE`
* `window_manager.Transitions.SLIDE_LEFT`
* `window_manager.Transitions.SLIDE_RIGHT`
* `window_manager.Transitions.SLIDE_UP`
* `window_manager.Transitions.SLIDE_DOWN`

Apenas a cena de destino é animada: o `exit()` da cena anterior roda assim que
a troca começa e ela deixa de ser desenhada. Uma nova troca cancela a
transição em andamento. Um nome de transição desconhecido é avisado no console
e cai para `NONE`, em vez de deixar a tela em branco.

## 📖 Referência da API

| Função | Descrição |
| --- | --- |
| `window_manager.register(nome, cena_ou_fabrica)` | Registra uma tabela de cena ou uma função fábrica. |
| `window_manager.switch(nome, opcoes_ou_tipo, duracao, dados)` | Troca para uma cena usando uma tabela de opções ou argumentos posicionais. |
| `window_manager.update(dt)` | Atualiza o gerenciador e a cena atual. |
| `window_manager.draw(pass)` | Desenha a cena atual com transição (se houver). |
| `window_manager.dispatch(evento, ...)` | Chama um hook opcional na cena ativa. |
| `window_manager.keypressed(key, scancode, isRepeat)` | Repassa um key press para a cena ativa. |
| `window_manager.keyreleased(key, scancode)` | Repassa um key release para a cena ativa. |
| `window_manager.setDebug(enabled)` | Alterna o texto de depuração com o nome da cena. |

Encaminhadores adicionais de eventos: `mousepressed`, `mousereleased`, `mousemoved`,
`wheelmoved`, `textinput`, `focus`, `visible` e `resize`.

Veja [CHANGELOG.md](CHANGELOG.md) para mudanças de comportamento e notas de
migração.

## 🧪 Desenvolvimento

A suíte de testes não tem dependências externas:

```sh
luajit tests/run.lua
lua5.4 tests/run.lua
```

A CI roda a mesma suíte com LuaJIT, Lua 5.1 e Lua 5.4.

## 📄 Licença

MIT — veja [LICENSE](LICENSE).
