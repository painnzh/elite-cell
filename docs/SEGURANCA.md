# Segurança operacional

## Configurações por empresa

As configurações são gravadas em `empresas/{empresaId}/configuracoes/geral`.
As regras do Firestore permitem acesso somente à empresa autenticada e ativa,
validam os campos aceitos e bloqueiam exclusões.

## Equipe e perfis

Convites de colaboradores ficam em `empresas/{empresaId}/membros/{email}`. Apenas o dono da empresa pode criar, alterar ou remover convites. O colaborador só pode ler o próprio convite, identificado pelo e-mail autenticado, e a única alteração própria permitida é ativá-lo uma vez, vinculando seu UID.

Não crie colaboradores alterando diretamente documentos no console sem conferir o e-mail. Para ativar o acesso, a pessoa deve criar a conta no aplicativo usando o mesmo e-mail do convite. A separação efetiva de dados é aplicada pelas regras do Firestore; ocultar um botão no aplicativo nunca substitui a regra.

## Fotos de ordens de serviço

As fotos de OS usam Cloudinary. O app móvel não pode guardar o segredo da
Cloudinary; por isso, uma proteção real contra uploads indevidos exige uma
assinatura emitida por servidor.

Antes de disponibilizar a aplicação amplamente, configure o preset
`elitecell_os` no painel Cloudinary para:

- aceitar somente imagens (`jpg`, `jpeg`, `png` e `webp`);
- limitar o tamanho máximo do arquivo;
- desabilitar sobrescrita e criação arbitrária de pastas;
- restringir o uso por assinatura de upload emitida em backend;
- revisar periodicamente as imagens armazenadas e suas políticas de retenção.

Não coloque `api_secret` da Cloudinary, credenciais administrativas do Firebase
ou dados reais de clientes no aplicativo, no Git ou em mensagens.

## Próximas medidas

- Habilitar Firebase App Check para Android antes da distribuição externa.
- Restringir a chave Android do Firebase por pacote e certificado SHA-1/SHA-256
  no Google Cloud Console.
- Criar papéis de acesso antes de disponibilizar contas para técnicos ou caixas.
- Definir política LGPD para fotos, IMEI, termos e assinaturas.
