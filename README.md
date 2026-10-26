# Elite Cell Assistência

Aplicativo de gestão para assistências técnicas e lojas de celulares. O projeto reúne operação de balcão, clientes, ordens de serviço, estoque, garantias, revenda de aparelhos usados e acompanhamento financeiro em uma aplicação Flutter integrada ao Firebase.

> **Status:** projeto em evolução ativa. A arquitetura está sendo adaptada para múltiplas empresas; alguns módulos já usam isolamento por empresa e outros ainda estão em adequação. Consulte [Multiempresa e segurança](#multiempresa-e-segurança) antes de publicar ou expandir o sistema.

## Sumário

- [Funcionalidades](#funcionalidades)
- [Tecnologias](#tecnologias)
- [Arquitetura e estrutura](#arquitetura-e-estrutura)
- [Pré-requisitos](#pré-requisitos)
- [Como executar](#como-executar)
- [Firebase](#firebase)
- [Multiempresa e segurança](#multiempresa-e-segurança)
- [Módulo de celulares usados](#módulo-de-celulares-usados)
- [Melhorias planejadas](#melhorias-planejadas)
- [Fluxo de contribuição](#fluxo-de-contribuição)

## Funcionalidades

### Módulos disponíveis

- **Autenticação:** cadastro e login de usuários com Firebase Authentication.
- **Cadastro de empresa:** criação da estrutura inicial para empresas atendidas pelo sistema.
- **Dashboard:** ponto central de navegação para os módulos operacionais.
- **Clientes:** cadastro e consulta de clientes, preparado para associação por empresa.
- **Ordens de serviço:** registro e acompanhamento de serviços técnicos.
- **Estoque:** controle de itens e movimentações por empresa.
- **Técnicos:** gerenciamento de técnicos associados à empresa.
- **Garantias:** acompanhamento de garantias vinculadas aos dados da empresa.
- **Financeiro:** lançamentos de entrada e saída, pesquisa, indicadores, gráfico e resumo de saldo por empresa.
- **Celulares usados:** cadastro, busca, indicadores de revenda, status de disponibilidade, reserva, venda, reversão, dossiê técnico por IMEI, composição de custos, margem prevista, termo de compra com assinatura na tela e compartilhamento por WhatsApp.
- **Catálogo do cliente:** visualização de aparelhos disponíveis e botão de interesse via WhatsApp.
- **Relatórios e impressão:** dependências para geração de PDF e impressão estão disponíveis no aplicativo.

### Experiência da interface

- Tema visual escuro com identidade dourada da Elite Cell.
- Atualização reativa dos dados do Firestore por `StreamBuilder`.
- Pesquisa textual nas telas de usados e financeiro.
- Gráficos financeiros de entradas, saídas e saldo.
- Captura ou seleção de imagem para aparelhos usados.
- Ações externas, como contato por WhatsApp, através de `url_launcher`.

## Tecnologias

| Camada | Tecnologia | Uso no projeto |
| --- | --- | --- |
| Aplicativo | Flutter e Dart | Interface multiplataforma e regras da aplicação |
| Dados em tempo real | `StreamBuilder` + Cloud Firestore | Sincronização reativa de coleções e telas |
| Autenticação | Firebase Authentication | Identidade do usuário e origem do `empresaId` |
| Banco de dados | Firebase Cloud Firestore | Clientes, estoque, OS, financeiro, usados e demais registros |
| Backend | Firebase Cloud Functions + Node.js 24 | Estrutura de backend em `functions/`; ainda sem função de negócio ativa |
| Gráficos | `fl_chart` | Resumos visuais do financeiro |
| Documentos | `pdf` e `printing` | Base para geração e impressão de documentos |
| Imagens | `image_picker` | Câmera e galeria para aparelhos usados |
| Integrações externas | `url_launcher` | WhatsApp e links externos |
| Qualidade | `flutter_lints`, `flutter_test`, ESLint | Análise estática e testes |

### Dependências Flutter principais

```yaml
firebase_core: ^4.9.0
cloud_firestore: ^6.4.1
firebase_auth: ^6.5.1
pdf: ^3.12.0
printing: ^5.14.3
url_launcher: ^6.3.2
fl_chart: ^1.2.0
image_picker: ^1.2.2
http: ^1.6.0
```

## Arquitetura e estrutura

```text
lib/
├── main.dart                         # Inicialização do Flutter e Firebase
└── screens/
    ├── login_screen.dart              # Autenticação
    ├── cadastro_empresa_screen.dart   # Cadastro de empresa
    ├── dashboard_screen.dart          # Navegação principal
    ├── clientes_screen.dart           # Clientes
    ├── os_screen.dart                 # Ordens de serviço
    ├── estoque_screen.dart            # Estoque
    ├── tecnicos_screen.dart           # Técnicos
    ├── garantia_screen.dart           # Garantias
    ├── financeiro_screen.dart         # Financeiro
    ├── celulares_usados_screen.dart   # Revenda de aparelhos usados
    └── catalogo_cliente_screen.dart   # Catálogo de aparelhos

assets/images/                         # Logo e ícone do app
android/                               # Configuração Android e Firebase
functions/                             # Estrutura de Firebase Cloud Functions
test/                                  # Testes Flutter
```

O aplicativo inicializa o Firebase em `lib/main.dart`. A autenticação entrega o UID do usuário ao dashboard como `empresaId`; os módulos em adequação recebem esse valor por construtor e o usam ao gravar e consultar documentos.

## Pré-requisitos

- Flutter **3.47.8** ou compatível.
- Dart SDK compatível com `sdk: ^3.12.0`.
- Git.
- Android Studio com Android SDK, Platform Tools, Build Tools e NDK **28.2.13676358** para compilar Android.
- Um emulador Android funcional, BlueStacks ou dispositivo físico com depuração USB para testes Android.
- Projeto Firebase configurado e acesso autorizado ao ambiente correspondente.
- Node.js **24** e Firebase CLI, somente para trabalhar com Cloud Functions.

## Como executar

### 1. Obter dependências

```powershell
flutter pub get
```

### 2. Validar o ambiente

```powershell
flutter doctor
flutter devices
```

### 3. Executar em um dispositivo disponível

```powershell
flutter run
```

Para selecionar um destino específico:

```powershell
flutter run -d windows
flutter run -d <id-do-dispositivo>
```

Durante o `flutter run`, use `r` para hot reload, `R` para reiniciar o app e `q` para encerrar a sessão de desenvolvimento.

### 4. Gerar APK Android de teste

```powershell
flutter build apk --debug
```

O APK será gerado em:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Esse arquivo pode ser instalado manualmente em um dispositivo Android ou emulador compatível, como o BlueStacks. Para distribuição, use uma assinatura de release e nunca publique uma versão de depuração como versão final.

### 5. Verificações antes de enviar alterações

```powershell
flutter analyze
flutter test
git diff
git status --short
```

## Firebase

### Aplicativo Flutter

- `firebase_core` inicializa a conexão com o Firebase.
- `firebase_auth` realiza cadastro e login.
- `cloud_firestore` armazena os dados operacionais.
- A configuração Android está em `android/app/google-services.json`.

Não inclua arquivos de credenciais, chaves privadas, tokens, bancos exportados ou dados reais de clientes em commits, issues, screenshots ou Pull Requests.

### Cloud Functions

O diretório `functions/` contém a estrutura inicial do Firebase Functions:

```powershell
cd functions
npm install
npm run lint
npm run serve
```

No estado atual, `functions/index.js` define apenas opções globais de execução e contém o exemplo padrão comentado. Não há uma função de negócio ativa documentada nesse arquivo.

Para publicar funções, use somente um ambiente Firebase autorizado:

```powershell
npm run deploy
```

## Multiempresa e segurança

O sistema está em migração para atender diversas assistências técnicas. O identificador de empresa é o UID do usuário autenticado, propagado pelo dashboard como `empresaId`.

### Módulos já alinhados ao `empresaId`

Clientes, estoque, ordens de serviço, técnicos, garantias e financeiro já recebem `empresaId`, gravam esse campo e consultam os documentos da empresa atual.

### Pontos ainda pendentes

- `CelularesUsadosScreen` ainda cria e consulta documentos sem `empresaId`.
- `CatalogoClienteScreen` consulta a coleção inteira e filtra a disponibilidade apenas no cliente.
- O dashboard ainda abre essas duas telas sem repassar `empresaId`.
- Vendas de usados criam lançamentos financeiros sem `empresaId`.
- `firestore.rules` protege as coleções operacionais por `empresaId`, exige uma empresa ativa e impede troca de empresa em atualizações.
- O histórico técnico e o termo de compra do dossiê são imutáveis após o registro. Isso preserva a evidência operacional do MVP.
- `firestore.indexes.json` define os índices para consultas de estoque e técnicos filtradas por empresa e ordenadas por nome.
- As regras e os índices só passam a valer no ambiente Firebase após revisão e publicação explícita.

> Filtrar consultas na interface não é um mecanismo de autorização. As regras do Firestore precisam validar a identidade autenticada, a posse do `empresaId` e os dados permitidos em cada operação. Não use regras permissivas como `allow read, write: if true`.

## Módulo de celulares usados

### Estado atual

O módulo cadastra aparelhos na coleção `celulares_usados` com marca, modelo, IMEI, conservação, cor, capacidade, bateria, valores de compra e venda, observações, status, foto e data. Os documentos são isolados por `empresaId`, e as ações de edição, exclusão, venda e reversão verificam a empresa responsável.

Os status operacionais incluem `Em avaliação`, `Em reparo`, `Pronto para venda`, `Disponível`, `Reservado` e `Vendido`. Ao marcar uma venda, a tela atualiza o status do aparelho e cria uma entrada no financeiro na mesma transação. Ao reverter, torna o aparelho disponível e cria uma saída de estorno.

### Dossiê de aquisição e recondicionamento

Cada aparelho possui um dossiê acessível pelo ícone de pasta na listagem. O recurso mantém um histórico interno vinculado ao IMEI, sem expor informações sensíveis no catálogo.

- Registro de diagnóstico, peças, mão de obra e ajustes na subcoleção `processo`.
- Cálculo em tempo real de custo de compra, custos do processo, custo total, lucro previsto e margem sobre o preço de venda.
- Status técnico independente para acompanhar a etapa de recondicionamento.
- Termo de compra e cessão com nome do vendedor, dados de contato opcionais, declaração de legitimidade e assinatura desenhada na tela.
- Registro de data/hora, usuário autenticado e método de assinatura para compor a trilha de auditoria inicial.

> A assinatura registrada no MVP é uma evidência operacional. Antes de usá-la como requisito jurídico, defina com assessoria jurídica a redação do termo, a retenção de dados, a necessidade de testemunhas e uma eventual integração com assinatura eletrônica avançada.

### Limitações atuais

- Fotos são salvas como caminhos locais; não ficam disponíveis para outros aparelhos ou para um catálogo público.
- O catálogo não possui uma flag explícita de publicação e usa um número de WhatsApp fixo.
- O termo ainda não gera PDF imutável, hash de conteúdo ou integração com provedor de assinatura eletrônica.
- Peças e mão de obra do dossiê ainda não movimentam o estoque ou o financeiro automaticamente.

### Direção de evolução recomendada

1. Publicar as regras e os índices em ambiente de homologação, validando os fluxos com duas empresas distintas.
2. Migrar imagens para um armazenamento compartilhado, como Firebase Storage, guardando URLs em vez de caminhos locais.
3. Ligar peças e mão de obra a movimentações de estoque e financeiro após validar o fluxo contábil.
4. Gerar PDF do termo, preservar versões e integrar assinatura eletrônica quando a política jurídica for definida.
5. Definir se o catálogo é interno ou público. Se público, criar uma representação com campos permitidos, sem custo de compra, margem, IMEI completo ou dados do termo.
6. Tornar o contato do catálogo configurável por empresa.

## Melhorias planejadas

### Prioridade alta

- [ ] Concluir o isolamento por `empresaId` em todos os módulos remanescentes.
- [x] Versionar regras seguras do Firestore e índices das consultas multiempresa.
- [ ] Publicar regras e índices em homologação após validar acessos de duas empresas.
- [x] Integrar vendas de usados ao financeiro de forma atômica e idempotente.
- [x] Adicionar edição, exclusão e validação de aparelhos usados.
- [x] Criar dossiê de aquisição e recondicionamento com custos e margem.
- [x] Registrar termo de compra com declaração e assinatura na tela.
- [ ] Integrar peças e mão de obra do dossiê ao estoque e ao financeiro.
- [ ] Gerar PDF versionado do termo e avaliar assinatura eletrônica avançada.
- [ ] Substituir caminhos locais de imagens por armazenamento compartilhado.
- [ ] Definir uma estratégia segura para o catálogo público.

### Qualidade e experiência

- [ ] Criar testes unitários e de widget para fluxos críticos.
- [ ] Cobrir cenários com duas empresas, incluindo tentativas de acesso indevido.
- [ ] Padronizar valores monetários, datas e validações de formulário.
- [ ] Melhorar mensagens de erro, carregamento e estados vazios.
- [x] Implementar índices necessários para estoque e técnicos por empresa.
- [ ] Revisar codificação de caracteres e padronizar arquivos em UTF-8.
- [ ] Documentar processos de backup, restauração e publicação.

### Backend e operação

- [ ] Implementar funções de negócio no Firebase Functions quando houver necessidade validada de processamento confiável no servidor.
- [ ] Configurar ambientes separados de desenvolvimento e produção.
- [ ] Criar observabilidade para erros de Functions e operações sensíveis.
- [ ] Definir processo de assinatura, versionamento e distribuição do APK.

## Fluxo de contribuição

O projeto é desenvolvido em paralelo por mais de uma pessoa. Para reduzir conflitos:

1. Atualize as referências remotas e confira o estado do repositório.
2. Não trabalhe diretamente na `main`.
3. Crie uma branch específica, por exemplo `modulo-celulares-usados`.
4. Preserve alterações locais de outros desenvolvedores; não use `reset --hard` nem descarte arquivos sem autorização.
5. Leia os arquivos atuais antes de modificá-los.
6. Faça mudanças pequenas, commits descritivos e validações proporcionais ao risco.
7. Execute análise, testes e revisão de diff antes de abrir uma Pull Request.
8. Não altere módulos de outro responsável, regras do Firestore ou configurações de produção sem alinhamento prévio.

## Licença

Este repositório não declara uma licença pública. Consulte os responsáveis pelo projeto antes de reutilizar, redistribuir ou publicar o código.
