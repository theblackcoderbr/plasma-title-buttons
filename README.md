# Plasma Title & Buttons

> 🌐 **Language**: [Read in English (README.en.md)](README.en.md)

Um applet (plasmoid) elegante e altamente configurável para painéis do **KDE Plasma 6**, integrando a barra de título da janela ativa e botões de controle de janela (Minimizar, Maximizar/Restaurar e Fechar) diretamente na sua barra de tarefas ou painel superior.

Projetado especialmente para fluxos de trabalho estilo Unity ou macOS, permitindo economia máxima de espaço vertical ao remover a barra de título nativa de janelas maximizadas.

> [!WARNING]
> ### ⚠️ Aviso Importante / Isenção de Responsabilidade
> - **Desenvolvido com auxílio de Inteligência Artificial**: Este projeto foi construído com a assistência de ferramentas de IA generativa. O autor por trás do projeto não possui formação acadêmica ou profissional na área de tecnologia.
> - **Uso por Conta e Risco**: O software é disponibilizado "como está" (*as-is*), sem garantias de qualquer natureza. Qualquer problema, incompatibilidade ou falha decorrente de seu uso é de inteira responsabilidade do usuário.
> - **Uso Pessoal e Sem Garantia de Manutenção**: Esta extensão foi concebida primariamente para atender às necessidades de uso pessoal do próprio autor, que não se compromete a prestar suporte, lançar atualizações contínuas ou manter o projeto a longo prazo.
> - **Contribuições de Profissionais são Bem-vindas**: Sugestões, correções de bugs, dicas de otimização e *pull requests* de pessoas com formação ou experiência na área são extremamente bem-vindos!

---

## 🚀 Principais Recursos

- **Título Inteligente da Janela Ativa**:
  - Exibe o título da janela atualmente em foco com suporte a ícone customizável.
  - Quando nenhuma janela estiver em foco, exibe suavemente `Plasma Workspace`.
  - **Ações no Título**:
    - **Clique esquerdo**: Alterna entre maximizar e restaurar a janela.
    - **Roda do mouse (Scroll) ou clique do botão do meio**: Percorre e alterna ciclicamente entre as janelas abertas na mesma tela e na mesma área de trabalho virtual.
- **Botões de Controle Condicionais**:
  - Os botões de Fechar, Minimizar e Maximizar/Restaurar aparecem **apenas quando a janela ativa estiver maximizada**, liberando espaço nos outros momentos.
- **Estilos de Botões Selecionáveis**:
  - **Tema do Sistema (Padrão)**: Utiliza os ícones do tema de decorações ativo do Plasma/KWin (Breeze, etc.).
  - **macOS / Círculos Coloridos**: Botões circulares clássicos (vermelho, amarelo e verde) com ícones que se revelam no hover.
  - **Minimalista**: Visual geométrico limpo e discreto.
- **Disposição Dinâmica e Alinhamento Sincronizado**:
  - **Expansão Automática**: Ocupa dinamicamente todo o espaço disponível no painel sem tamanhos fixos.
  - **Posicionamento do Título**: Escolha entre **Esquerda**, **Centro** ou **Direita**.
  - **Sincronização com os Botões**: A interface impede automaticamente que o título e os botões fiquem na mesma ponta (quando o título é à esquerda, os botões vão para a direita e vice-versa; no centro, permite escolher a ponta desejada com balanceamento de simetria).
  - **Controle de Tamanho dos Botões**: Opções de tamanho **Pequeno (Compacto)**, **Normal / Padrão** e **Grande (Espaçoso)**, distinguindo com precisão:
    - **Largura / área de clique**: 24 px (pequeno), 32 px (médio) e 44 px (grande);
    - **Tamanho-base dos ícones**: 14 px (pequeno), 18 px (médio) e 22 px (grande);
    - **Altura**: adaptativa conforme a espessura do painel (com suporte otimizado a painéis compactos de 24–26 px).
  - Ativação/desativação independente de cada elemento: Título, Ícone e Botões.
- **Ocultação de Barra de Título Nativa**:
  - Integração com o KWin para habilitar/desabilitar `BorderlessMaximizedWindows`, ocultando a barra de título original da aplicação quando ela estiver maximizada.

---

## 🛠️ Requisitos e Ambiente

- **Sistema Operacional**: Linux (desenvolvido e otimizado no NixOS).
- **Ambiente Desktop**: KDE Plasma 6 (>= 6.0, testado no 6.7+).
- **Frameworks e Bibliotecas**:
  - Qt 6 (Core, Gui, Qml, Quick, Svg)
  - KDE Frameworks 6 (Extra CMake Modules, KCoreAddons, KI18n, KConfig, KWindowSystem)
  - Plasma 6 Workspace (`libplasma`, `PW::LibTaskManager`)
  - Ninja e CMake 3.20+

---

## 🛡️ Compilação Segura em Recursos Limitados (NixOS)

O projeto foi preparado para compilação segura em máquinas com **~7GB de RAM**. Como a compilação C++ com Qt 6 e KF6 em 12 threads pode causar esgotamento de memória e *swapping* no zram, o ambiente está configurado para limitar estritamente o paralelismo a **2 threads**.

### 1. Entrar no Ambiente de Desenvolvimento
```bash
nix-shell
```

### 2. Compilar e Instalar Localmente
Dentro do `nix-shell`, você pode usar o atalho:
```bash
build-applet
```
Ou executar manualmente:
```bash
cmake -B build -S . -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$HOME/.local
ninja -C build -j2
ninja -C build install
```

### 3. Testar com o Plasmoidviewer
Para testar a interface do applet sem precisar reiniciar a sessão do Plasma:
```bash
run-test
# ou manualmente:
plasmoidviewer -a org.kde.plasma.windowtitleandbuttons
```

---

## 📂 Estrutura do Repositório

```text
.
├── shell.nix                     # Ambiente reproduzível NixOS com limites de memória
├── CMakeLists.txt                # Configuração global de build do projeto
├── README.md                     # Documentação para usuários e desenvolvedores
├── AGENTS.md                     # Diretrizes e regras de contexto para agentes de IA
├── src/                          # Backend C++ (integração KWin e LibTaskManager)
│   ├── CMakeLists.txt            # Módulo QML nativo gerado via qt_add_qml_module
│   ├── windowcontroller.h        # Declaração do controlador de janelas
│   └── windowcontroller.cpp      # Lógica de ciclo, foco e decorações
└── package/                      # Pacote do Plasmoid Plasma 6
    ├── metadata.json             # Metadados e identificador do widget
    └── contents/
        ├── config/
        │   ├── main.xml          # Definições do KConfigXT
        │   └── config.qml        # Configuração das páginas de opções
        └── ui/
            ├── main.qml          # Visão principal do applet
            ├── WindowTitle.qml   # Componente do título e captura de eventos
            ├── WindowButtons.qml # Componente dos botões de janela
            └── configGeneral.qml # Painel de configurações do usuário
```

---

## ⚙️ Configurações Disponíveis no Plasma

Clicando com o botão direito no widget e selecionando **Configurar Título e Botões de Janela...**, o usuário pode ajustar:
1. **Exibir Ícone da Janela**: Ativar/desativar ícone da aplicação.
2. **Exibir Título da Janela**: Ativar/desativar texto do título.
3. **Exibir Botões de Controle**: Ativar/desativar os botões de fechar, minimizar e maximizar.
4. **Posição do Título**: Escolher entre Esquerda, Centro ou Direita.
5. **Posição dos Botões**: Escolher entre Esquerda ou Direita (sincronizado automaticamente).
6. **Estilo dos Botões**: Tema do Sistema, macOS ou Minimalista.
7. **Tamanho dos Botões**: Pequeno, Médio / Padrão ou Grande — distinguindo largura de clique (24, 32 e 44 px), tamanho-base dos ícones (14, 18 e 22 px) e altura adaptativa à espessura do painel.
8. **Remover borda da janela maximizada**: Alterna `BorderlessMaximizedWindows` no KWin.

---

## 📄 Licença

Distribuído sob a licença **GPLv3** (**GNU General Public License version 3**), compatível com o ecossistema KDE Plasma.
