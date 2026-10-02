# Diretrizes para Agentes de Desenvolvimento (AGENTS.md)

Este documento estabelece o contexto de arquitetura, restrições de hardware e regras de codificação para agentes de IA que atuarem neste repositório.

---

## 1. Contexto do Ambiente e Restrições Críticas de Hardware

- **Sistema Operacional**: NixOS (Linux).
- **Desktop Environment**: KDE Plasma 6 (direcionado e testado no Plasma 6.7+, Qt 6 e KF6).
- **Restrição de Memória RAM**:
  - A máquina host possui cerca de **6.5 a 7 GB de RAM disponível**, com swap zram de 7 GB.
  - A CPU possui 12 threads virtuais.
  - ⚠️ **REGRA CRÍTICA DE COMPILAÇÃO**:
    - **NUNCA** execute comandos de compilação sem restringir o paralelismo. Disparar 12 processos de compilação do `g++`/`clang++` com cabeçalhos do Qt6/KF6 causa estouro de memória (OOM) imediato e congelamento do sistema por *thrashing* no zram.
    - **Sempre utilize dois processos**, independentemente do hardware: `cmake --build build --parallel 2` ou `-j2` no `ninja`/`make`. Esse é o padrão conservador global do projeto.
    - Instale com `cmake --install build` após uma compilação bem-sucedida, sem disparar outra compilação. Scripts devem interromper imediatamente após falhas de configuração ou build.
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

- Deve ser compilado como um plugin QML registrado sob um namespace seguro (`org.kde.plasma.private.windowtitleandbuttons`), instalado e empacotado tanto no QMLDIR quanto diretamente no diretório do Plasmoid (`contents/plugin/`).
- O QML do Plasmoid carrega o módulo via import relativo (`import "../plugin" as WTButtons`), tornando o widget 100% autossuficiente e imune à perda de variáveis de ambiente de sessão (como `QML2_IMPORT_PATH`) após reinicializações.
- Utiliza a biblioteca oficial de gerenciamento de tarefas do KDE Workspace (`PW::LibTaskManager` / `TaskManager::TasksModel`).
- Um `TaskFilterProxyModel` público filtra o `TasksModel` sem agrupamento. Todos os estados e comandos do controlador usam os índices desse proxy, que encaminha as ações à janela de origem.
- **Comportamento do Controlador**:
  - Filtra e rastreia a janela em foco na tela (`screen`), área de trabalho virtual (`virtualDesktop`) e atividade atuais. A atividade acompanha `ActivityInfo::currentActivityChanged`; janelas solicitando atenção não ignoram os filtros (`demandingAttentionSkipsFilters = false`). Janelas configuradas para todas as atividades/desktops continuam elegíveis nesses contextos.
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
    - `cycleWindow(int direction)`: Alterna o foco entre as janelas elegíveis na mesma tela/desktop/atividade (ciclo circular). Uma única janela sem foco deve ser ativada; se já estiver ativa, não executa ação. Sem janelas ou com direção zero, não executa ação.
    - `setBorderlessMaximizedWindows(bool enabled)`: Ajusta a opção no arquivo `kwinrc` (`[Windows] BorderlessMaximizedWindows`) e solicita ao KWin a recarga via DBus (`qdbus6 org.kde.KWin /KWin reconfigure`).
  - **Preferência global do KWin**: `KWinSettings` é a fonte reativa de `BorderlessMaximizedWindows`. A inicialização apenas lê o estado; nunca aplica valores salvos por instância. A interface altera essa preferência explicitamente, com efeito imediato em todos os monitores, e acompanha alterações externas em `kwinrc`. Falhas de gravação e de recarga via D-Bus devem ser exibidas, sem reverter alterações concorrentes de outras instâncias.

### 3.2. Frontend QML (`package/contents/`)
- Segue estritamente as diretrizes do **Plasma 6 / Kirigami**:
  - Importação de `org.kde.plasma.plasmoid`, `org.kde.plasma.core`, `org.kde.plasma.components 3.0 as PlasmaComponents3` e `org.kde.kirigami as Kirigami`.
  - Layout dinâmico que respeita a espessura e orientação do painel (horizontal ou vertical).
  - Animações fluidas em transições de hover e visibilidade (usando `NumberAnimation` ou `Behavior on opacity`).
- **Regras de Visibilidade e Interação da Interface**:
  1. **Expansão Dinâmica**: O widget ocupa dinamicamente todo o espaço disponível no painel (`Layout.fillWidth: true`, `Layout.fillHeight: true`).
  2. O **Título** pode ser exibido ou oculto conforme a configuração, independentemente do ícone e dos botões. Quando habilitado, exibe o nome da janela ativa ou `"Plasma Workspace"`. Pode ser alinhado à **Esquerda**, **Centro** ou **Direita**.
  3. Os **Botões de controle** só devem ser visíveis quando a janela ativa estiver maximizada (`isMaximized === true`) e se a opção estiver ativada nas configurações.
  4. O **Ícone da janela** pode ser exibido ou oculto conforme a configuração.
  5. **Sincronização de Posição**:
     - O título e os botões não podem ocupar a mesma ponta (se título à esquerda, botões à direita; se título à direita, botões à esquerda).
     - A posição é resolvida pela mesma regra no applet e na configuração (`ButtonPlacement.qml`). Se o título ocupar a única extremidade livre, os botões ficam ocultos e a configuração explica como resolver o conflito. Não se move o título nem se sobrescreve a preferência de lado dos botões automaticamente; quando houver uma combinação válida, a exibição pode retornar conforme a configuração.
     - Quando o título estiver ao centro, os botões podem ficar à esquerda ou à direita, com contrapesos de largura para garantir centralização matemática perfeita.
     - **Centralização Absoluta no Painel (`centerInPanel`)**: Opção extra com checkbox quando o título está ao centro. Garante que o título permaneça matematicamente centralizado no comprimento total do painel, calculando a posição global do widget e compensando elementos assimétricos (ex: bandeja do sistema à esquerda).
       - `PanelCenteredTitle.qml` usa a largura efetivamente exibida, fora do `RowLayout`, e reserva espaço apenas para botões visíveis. Quando o centro não cabe na área disponível, limita a posição à área livre do widget para evitar sobreposição.
     - **Detecção de Extremidades do Painel**:
       - Detecta se o applet está encostado na ponta esquerda (`isAtLeftEdge`) ou direita (`isAtRightEdge`) do painel.
       - `PanelEdges.qml` identifica os vizinhos visíveis por `isAppletContainer` no painel Plasma 6.7, sem tolerância fixa em pixels. Margens auxiliares não contam como widgets. Layout desconhecido, sobreposto, sem tamanho ou em edição invalida as extremidades (`edgesKnown = false`) sem apagar preferências. A desmarcação por dois lados ocupados só ocorre após estabilização.
       - Se houver outros elementos em uma das extremidades, os botões só podem ser posicionados na extremidade livre.
       - Se houver outros elementos em **ambas as extremidades** (widget no meio do painel), a opção de botões de controle é desabilitada e desmarcada, exibindo um botão de ajuda contextual Kirigami (`?`) com tooltip explicativo.
  6. **Ações no Título**:
     - Clique esquerdo: minimiza a janela focada quando maximizada; caso contrário, maximiza, respeitando as capacidades da janela. Sem janela ativa, não executa ação.
     - Scroll da roda do mouse ou clique do meio (scroll click): aciona `cycleWindow()` navegando pelas janelas abertas, incluindo minimizadas. Os filtros de janela oculta e minimizada devem permanecer desativados; monitor, desktop, atividade e exclusão da barra de tarefas continuam respeitados.
     - O scroll acumula movimento vertical até 120 unidades angulares ou 40 pixels, preferindo pixels quando disponíveis. Cada evento troca no máximo uma janela, com intervalo mínimo de 300 ms e descarte de excesso, sem fila. Pausa de 200 ms, saída do ponteiro ou inversão de direção descarta movimento parcial. O clique do meio continua imediato.
  7. **Estilos e Tamanhos dos Botões**:
     - Todos os estilos mantêm a mesma ordem: Minimizar, Maximizar/Restaurar, Fechar. No estilo macOS, as cores acompanham as ações: amarelo, verde, vermelho.
     - Todos os estilos usam controles nativos com foco por Tab, ativação por Espaço, indicação visual de foco e nomes acessíveis traduzidos via `i18n()`. Maximizar muda para Restaurar quando a janela está maximizada.
     - Cada botão exige janela ativa e a capacidade correspondente (`canClose`, `canMinimize`, `canMaximize`); botões indisponíveis ficam desabilitados. A ação de acessibilidade e os métodos do backend também respeitam essa disponibilidade.
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

Testes automatizados isolam `kwinrc` em um diretório temporário e usam um serviço KWin simulado em D-Bus privado (requerem Qt Test e `dbus-run-session`, disponíveis no shell Nix):

```bash
cmake -B build -S . -DBUILD_TESTING=ON
cmake --build build --parallel 2
ctest --test-dir build --output-on-failure
```

---

## 5. Integridade do Código
- Sempre mantenha os comentários informativos no código.
- Utilize nomes de variáveis em inglês no código fonte C++ e QML (`isMaximized`, `windowTitle`, `cycleWindow`), mantendo a consistência com as APIs do Qt/KDE.
- A interface de usuário (textos no QML e configurações) deve usar `i18n()` do KDE para suporte a internacionalização, com termos em Português e Inglês.
