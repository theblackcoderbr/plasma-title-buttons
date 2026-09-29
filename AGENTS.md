# Diretrizes para Agentes de Desenvolvimento (AGENTS.md)

Este documento estabelece o contexto de arquitetura, restrições de hardware e regras de codificação para agentes de IA que atuarem neste repositório.

---

## 1. Contexto do Ambiente e Restrições Críticas de Hardware

- **Sistema Operacional**: NixOS (Linux).
- **Desktop Environment**: KDE Plasma 6 (>= 6.0, Qt 6 e KF6).
- **Restrição de Memória RAM**:
  - A máquina host possui cerca de **6.5 a 7 GB de RAM disponível**, com swap zram de 7 GB.
  - A CPU possui 12 threads virtuais.
  - ⚠️ **REGRA CRÍTICA DE COMPILAÇÃO**:
    - **NUNCA** execute comandos de compilação sem restringir o paralelismo. Disparar 12 processos de compilação do `g++`/`clang++` com cabeçalhos do Qt6/KF6 causa estouro de memória (OOM) imediato e congelamento do sistema por *thrashing* no zram.
    - **Sempre utilize `-j2`** (no máximo 3) no `ninja` ou `make`.
    - No `shell.nix`, garanta que `CMAKE_BUILD_PARALLEL_LEVEL = 2;` e `NIX_BUILD_CORES = 2;` estejam mantidos.

---

## 2. Tecnologias e Dependências

- **Linguagem**: C++20 (backend) e QML / QtQuick (frontend).
- **Frameworks**:
  - Qt 6 (Core, Gui, Qml, Quick, Svg)
  - KDE Frameworks 6 (ECM, KCoreAddons, KI18n, KConfig, KWindowSystem)
  - Plasma 6 Workspace (`libplasma`, `PW::LibTaskManager`)
- **Sistema de Build**: CMake 3.20+ com Extra CMake Modules (ECM) e gerador Ninja.

---

## 3. Arquitetura e Padrões de Projeto

### 3.1. Backend C++ (`src/`)
- Deve ser compilado como um plugin QML registrado sob um namespace seguro, ex: `org.kde.plasma.private.windowtitleandbuttons`.
- Utiliza a biblioteca oficial de gerenciamento de tarefas do KDE Workspace (`PW::LibTaskManager` / `TaskManager::TasksModel`).
- **Comportamento do Controlador**:
  - Filtra e rastreia a janela em foco na tela (`screen`) e área de trabalho virtual (`virtualDesktop`) ativas.
  - Propriedades reativas para o QML (`Q_PROPERTY` com sinais `NOTIFY`):
    - `hasActiveWindow` (bool)
    - `windowTitle` (QString): Quando não houver janela ativa, deve retornar a string `"Plasma Workspace"`.
    - `windowIcon` (QVariant/QIcon)
    - `isMaximized` (bool)
    - `canMaximize`, `canMinimize`, `canClose` (bool)
  - Métodos invocáveis (`Q_INVOKABLE`):
    - `toggleMaximize()`
    - `minimize()`
    - `close()`
    - `cycleWindow(int direction)`: Alterna o foco para a próxima ou anterior janela ativa na mesma tela/desktop (ciclo circular).
    - `setBorderlessMaximizedWindows(bool enabled)`: Ajusta a opção no arquivo `kwinrc` (`[Windows] BorderlessMaximizedWindows`) e solicita ao KWin a recarga via DBus (`qdbus6 org.kde.KWin /KWin reconfigure`).

### 3.2. Frontend QML (`package/contents/`)
- Segue estritamente as diretrizes do **Plasma 6 / Kirigami**:
  - Importação de `org.kde.plasma.plasmoid`, `org.kde.plasma.core`, `org.kde.plasma.components 3.0 as PlasmaComponents3` e `org.kde.kirigami as Kirigami`.
  - Layout dinâmico que respeita a espessura e orientação do painel (horizontal ou vertical).
  - Animações fluidas em transições de hover e visibilidade (usando `NumberAnimation` ou `Behavior on opacity`).
- **Regras de Visibilidade e Interação da Interface**:
  1. **Expansão Dinâmica**: O widget ocupa dinamicamente todo o espaço disponível no painel (`Layout.fillWidth: true`, `Layout.fillHeight: true`).
  2. O **Título** está sempre visível (exibindo o nome da janela ativa ou `"Plasma Workspace"`). Pode ser alinhado à **Esquerda**, **Centro** ou **Direita**.
  3. Os **Botões de controle** só devem ser visíveis quando a janela ativa estiver maximizada (`isMaximized === true`) e se a opção estiver ativada nas configurações.
  4. O **Ícone da janela** pode ser exibido ou oculto conforme a configuração.
  5. **Sincronização de Posição**:
     - O título e os botões não podem ocupar a mesma ponta (se título à esquerda, botões à direita; se título à direita, botões à esquerda).
     - Quando o título estiver ao centro, os botões podem ficar à esquerda ou à direita, com contrapesos de largura para garantir centralização matemática perfeita.
  6. **Ações no Título**:
     - Clique esquerdo: minimiza/maximiza a janela focada.
     - Scroll da roda do mouse ou clique do meio (scroll click): aciona `cycleWindow()` navegando pelas janelas abertas.
  7. **Estilos e Tamanhos dos Botões**:
     - Estilos: `system` (Tema do sistema ativo, padrão), `macos` (Círculos coloridos: vermelho, amarelo, verde) e `minimal` (Design geométrico limpo).
     - Tamanhos dos Botões:
       - Largura / área de clique: `small` (24px), `medium` (32px, padrão) e `large` (44px).
       - Tamanho-base dos ícones: `small` (14px), `medium` (18px) e `large` (22px).
       - Altura: adaptativa conforme a espessura do painel (com suporte otimizado a painéis compactos de 24–26px).

---

## 4. Comandos de Validação e Teste

Para compilar e testar alterações:

```bash
# Entrar no shell do Nix
nix-shell

# Compilação e instalação no prefixo local do usuário (~/.local)
build-applet

# Execução em janela isolada de teste
run-test
```

---

## 5. Integridade do Código
- Sempre mantenha os comentários informativos no código.
- Utilize nomes de variáveis em inglês no código fonte C++ e QML (`isMaximized`, `windowTitle`, `cycleWindow`), mantendo a consistência com as APIs do Qt/KDE.
- A interface de usuário (textos no QML e configurações) deve usar `i18n()` do KDE para suporte a internacionalização, com termos em Português e Inglês.
