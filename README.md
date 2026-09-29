# Plasma Title & Buttons

> 🌐 **Idioma / Language**: [Read in English (README.en.md)](README.en.md)

Um applet (plasmoid) elegante e altamente configurável para o painel do **KDE Plasma 6**, integrando o título da janela ativa e botões de controle de janela (Minimizar, Maximizar/Restaurar e Fechar) diretamente na sua barra de tarefas ou painel superior.

> Projetado especialmente para fluxos de trabalho estilo Unity ou macOS, permitindo economia máxima de espaço vertical ao remover a barra de título nativa de janelas maximizadas.

> [!IMPORTANT]
> Este projeto foi desenvolvido principalmente para uso pessoal, com auxílio de ferramentas de inteligência artificial generativa. Embora seja testado antes das versões publicadas, é fornecido sem garantias e pode não receber manutenção contínua. Relatos de bugs, sugestões e pull requests da comunidade são bem-vindos.

---

## 🚀 Principais Recursos

- **Título Inteligente da Janela Ativa**:
  - Exibe o título da janela atualmente em foco com suporte a ícone customizável da aplicação.
  - Quando nenhuma janela estiver em foco, exibe suavemente `Plasma Workspace`.
  - **Ações Rápidas no Título**:
    - **Clique esquerdo**: Alterna entre maximizar e restaurar a janela em foco.
    - **Roda do mouse (Scroll) ou clique do botão do meio**: Percorre e alterna ciclicamente entre as janelas abertas na mesma tela e na mesma área de trabalho virtual.
- **Botões de Controle Condicionais**:
  - Os botões de Fechar, Minimizar e Maximizar/Restaurar aparecem **apenas quando a janela ativa estiver maximizada**, liberando espaço nos outros momentos.
- **Estilos de Botões Selecionáveis**:
  - **Tema do Sistema (Padrão)**: Utiliza os ícones do tema de decorações ativo do Plasma/KWin (Breeze, etc.).
  - **macOS / Círculos Coloridos**: Botões circulares clássicos (vermelho, amarelo e verde) com ícones que se revelam no hover.
  - **Minimalista**: Visual geométrico limpo e discreto.
- **Disposição Dinâmica e Alinhamento Sincronizado**:
  - **Expansão Automática**: Ocupa dinamicamente todo o espaço disponível no painel sem comprimentos fixos arbitrários.
  - **Posicionamento do Título**: Escolha entre **Esquerda**, **Centro** ou **Direita**.
  - **Centralização Absoluta no Painel**: Opção que mantém o título matematicamente centralizado na largura total do painel, compensando assimetrias causadas por outros elementos (como bandeja do sistema, relógio ou lançadores de aplicativos).
  - **Detecção Inteligente de Bordas do Painel**:
    - Detecta dinamicamente se o applet está encostado na ponta esquerda ou direita da barra.
    - Se uma das pontas do painel estiver ocupada por outros elementos, a configuração restringe os botões à extremidade livre.
    - Se ambas as pontas estiverem ocupadas (widget posicionado no meio de outros elementos), os botões são desativados com aviso de ajuda contextual explicativo (`?`).
  - **Sincronização com os Botões**: A interface impede automaticamente que o título e os botões ocupem a mesma ponta.
  - **Controle de Tamanho dos Botões**: Opções de tamanho **Pequeno (Compacto)**, **Normal / Padrão** e **Grande (Espaçoso)**:
    - **Largura / área de clique**: 24 px (pequeno), 32 px (médio) e 44 px (grande);
    - **Tamanho-base dos ícones**: 14 px (pequeno), 18 px (médio) e 22 px (grande);
    - **Altura**: adaptativa conforme a espessura do painel (com suporte otimizado a painéis compactos de 24–26 px).
  - Ativação/desativação independente de cada elemento: Título, Ícone e Botões.
- **Ocultação de Barra de Título Nativa**:
  - Integração nativa com o KWin para alternar `BorderlessMaximizedWindows`, ocultando a barra de título original da janela quando ela estiver maximizada.

---

## 🛠️ Requisitos de Sistema

- **Sistema Operacional**: Qualquer distribuição Linux com KDE Plasma 6.
- **Ambiente Desktop**: KDE Plasma 6.7 ou mais recente (Qt 6 e KF6).
  > [!NOTE]
  > Atualmente testado e validado no **KDE Plasma 6.7**. Versões anteriores ou posteriores podem exigir adaptações devido a mudanças nas APIs internas do Plasma Workspace (em especial `PW::LibTaskManager` e a integração com KWin).
- **Dependências de Build**:
  - CMake 3.20+
  - Compilador compatível com C++20 (GCC ou Clang)
  - Extra CMake Modules (ECM)
  - Ninja (recomendado) ou Make
  - Qt 6 (Core, Gui, Qml, Quick, Svg)
  - KDE Frameworks 6 (KCoreAddons, KI18n, KConfig, KWindowSystem)
  - Plasma 6 Workspace (`libplasma`, `PW::LibTaskManager`)

---

## 🏗️ Compilação e Instalação

### Opção 1: Compilação Padrão (Qualquer Distribuição Linux)

Clone o repositório e compile o projeto utilizando CMake e Ninja:

```bash
# 1. Configurar o build para instalação local do usuário (~/.local)
cmake -B build -S . -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME/.local

# 2. Compilar (use -j2 ou ajuste conforme a quantidade de memória do seu sistema)
ninja -C build -j$(nproc)

# 3. Instalar
ninja -C build install
```

> [!TIP]
> **Dica de Memória RAM**: A compilação de código C++ moderno com cabeçalhos pesados do Qt 6 e KDE Frameworks pode consumir bastante memória. Em sistemas com 8 GB de RAM ou menos, recomenda-se limitar o número de compilações paralelas usando `ninja -C build -j2`.

### Opção 2: Ambiente Reproduzível com Nix / NixOS (`shell.nix`)

Para usuários do **Nix** ou **NixOS**, o repositório inclui um arquivo [`shell.nix`](shell.nix) pronto que disponibiliza todas as dependências, ferramentas de compilação e variáveis de ambiente necessárias:

```bash
# 1. Entrar no shell do Nix
nix-shell

# 2. Compilar e instalar no prefixo local do usuário (~/.local)
build-applet

# 3. (Opcional) Executar o applet em janela de teste isolada
run-test
```

### Aplicando as Alterações na Sessão do Plasma

Após a instalação, reinicie a barra de tarefas do Plasma para carregar a nova versão:

```bash
systemctl --user restart plasma-plasmashell.service
```

---

## ⚙️ Configurações Disponíveis

Clicando com o botão direito no widget e selecionando **Configurar Título e Botões de Janela...**, é possível ajustar:

1. **Exibir Ícone da Janela**: Alterna a visibilidade do ícone do aplicativo.
2. **Exibir Título da Janela**: Alterna a visibilidade do nome da janela em foco.
3. **Exibir Botões de Controle**: Alterna a exibição dos botões de fechar, minimizar e maximizar.
4. **Posição do Título**: Escolha entre **Esquerda**, **Centro** ou **Direita**.
5. **Centralizar em relação ao painel inteiro**: Caixa de seleção disponível quando o título está ao centro para mantê-lo matematicamente centralizado no comprimento total do painel.
6. **Posição dos Botões**: Escolha entre **Esquerda** ou **Direita** (sincronizado automaticamente e restrito às pontas livres do painel).
7. **Estilo dos Botões**: Tema do Sistema, macOS (Círculos coloridos) ou Minimalista.
8. **Tamanho dos Botões**: Pequeno, Médio (Padrão) ou Grande.
9. **Remover borda da janela maximizada**: Alterna a opção `BorderlessMaximizedWindows` do KWin.

---

## 📂 Estrutura do Repositório

```text
.
├── shell.nix                     # Ambiente de desenvolvimento reprozudível Nix/NixOS
├── CMakeLists.txt                # Configuração principal do sistema de build CMake
├── README.md                     # Documentação em Português
├── README.en.md                  # Documentação em Inglês
├── AGENTS.md                     # Diretrizes técnicas para agentes e automações
├── src/                          # Backend C++ (integração KWin e LibTaskManager)
│   ├── CMakeLists.txt            # Módulo QML nativo (qt_add_qml_module)
│   ├── windowcontroller.h        # Declaração do controlador de janelas
│   └── windowcontroller.cpp      # Lógica de foco, ciclo de janelas e KWin
└── package/                      # Pacote Plasmoid para Plasma 6
    ├── metadata.json             # Metadados e manifesto do widget
    └── contents/
        ├── config/
        │   ├── main.xml          # Esquema de opções persistidas via KConfigXT
        │   └── config.qml        # Registro das páginas de configuração
        └── ui/
            ├── main.qml          # Componente raiz do plasmoid e gerenciamento de layout
            ├── WindowTitle.qml   # Componente de renderização e eventos do título
            ├── WindowButtons.qml # Componente de renderização dos botões de controle
            └── configGeneral.qml # Interface gráfica de configurações do usuário
```

---

## 🤝 Contribuições

Contribuições da comunidade, sugestões de melhorias de arquitetura, correções de bugs e traduções são muito bem-vindas! Sinta-se à vontade para abrir uma *Issue* ou enviar um *Pull Request*.

---

## 💡 Inspirações e Agradecimentos

Este projeto foi desenvolvido de forma independente, mas foi inspirado pelo trabalho de [Michail Vourlakos (psifidotos)](https://github.com/psifidotos) nos applets [Window Title](https://github.com/psifidotos/applet-window-title) e [Window Buttons](https://github.com/psifidotos/applet-window-buttons).

Também agradeço a [dhruv8sh](https://github.com/dhruv8sh), pela adaptação do Window Title para o Plasma 6, e a [moodyhunter](https://github.com/moodyhunter), pela adaptação do Window Buttons para o Plasma 6.

Nenhum código desses projetos foi incorporado diretamente a este repositório.

---

## 📄 Licença

Este projeto é software livre distribuído sob os termos da **GNU General Public License v3.0** (**GPLv3**). Consulte o cabeçalho dos arquivos para detalhes de copyright.
