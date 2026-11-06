import 'package:flutter/material.dart';

import '../services/configuracao_empresa_service.dart';
import '../theme/tema_empresa_controller.dart';
import '../utils/valor_monetario.dart';

enum SecaoConfiguracao { perfil, geral, personalizacao, meta }

class ConfiguracoesEmpresaScreen extends StatefulWidget {
  const ConfiguracoesEmpresaScreen({
    super.key,
    required this.empresaId,
    this.secaoInicial = SecaoConfiguracao.perfil,
  });

  final String empresaId;
  final SecaoConfiguracao secaoInicial;

  @override
  State<ConfiguracoesEmpresaScreen> createState() =>
      _ConfiguracoesEmpresaScreenState();
}

class _ConfiguracoesEmpresaScreenState
    extends State<ConfiguracoesEmpresaScreen> {
  late final ConfiguracaoEmpresaService _service;
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _logoUrl = TextEditingController();
  final _telefone = TextEditingController();
  final _endereco = TextEditingController();
  final _informacoes = TextEditingController();
  final _metaMensal = TextEditingController();
  final _maoDeObra = TextEditingController();
  final _trocaTela = TextEditingController();
  final _trocaConector = TextEditingController();
  late SecaoConfiguracao _secao;
  ThemeMode _tema = ThemeMode.dark;
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _service = ConfiguracaoEmpresaService(widget.empresaId);
    _secao = widget.secaoInicial;
    _carregar();
  }

  double _numero(String valor) => ValorMonetario.paraDouble(valor);

  Future<void> _carregar() async {
    final dados = await _service.carregar();
    if (!mounted) return;
    final servicos = Map<String, dynamic>.from(dados['valoresServico'] ?? {});
    setState(() {
      _nome.text = dados['nomeEmpresa']?.toString() ?? '';
      _logoUrl.text = dados['logoUrl']?.toString() ?? '';
      _telefone.text = dados['telefone']?.toString() ?? '';
      _endereco.text = dados['endereco']?.toString() ?? '';
      _informacoes.text = dados['informacoesComerciais']?.toString() ?? '';
      _metaMensal.text = (dados['metaMensal'] ?? 5000).toString();
      _maoDeObra.text = (dados['maoDeObraPadrao'] ?? 70).toString();
      _trocaTela.text = (servicos['trocaTela'] ?? 0).toString();
      _trocaConector.text = (servicos['trocaConector'] ?? 0).toString();
      _tema = temaDoValor(dados['tema']);
      _carregando = false;
    });
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);
    try {
      await _service.salvar({
        'nomeEmpresa': _nome.text.trim(),
        'logoUrl': _logoUrl.text.trim(),
        'telefone': _telefone.text.trim(),
        'endereco': _endereco.text.trim(),
        'informacoesComerciais': _informacoes.text.trim(),
        'metaMensal': _numero(_metaMensal.text),
        'maoDeObraPadrao': _numero(_maoDeObra.text),
        'valoresServico': {
          'trocaTela': _numero(_trocaTela.text),
          'trocaConector': _numero(_trocaConector.text),
        },
        'tema': valorDoTema(_tema),
      });
      temaEmpresaController.value = _tema;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas com sucesso.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar as configurações.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _campo(
    TextEditingController controller,
    String rotulo, {
    TextInputType teclado = TextInputType.text,
    bool obrigatorio = false,
    int linhas = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: teclado,
        maxLines: linhas,
        decoration: InputDecoration(
          labelText: rotulo,
          border: const OutlineInputBorder(),
        ),
        validator: obrigatorio
            ? (valor) => valor == null || valor.trim().isEmpty
                  ? 'Informe $rotulo.'
                  : null
            : null,
      ),
    );
  }

  Widget _conteudo() {
    switch (_secao) {
      case SecaoConfiguracao.perfil:
        return Column(
          children: [
            _campo(_nome, 'Nome da empresa', obrigatorio: true),
            _campo(_logoUrl, 'URL do logotipo'),
            _campo(_telefone, 'Telefone', teclado: TextInputType.phone),
            _campo(_endereco, 'Endereço', linhas: 2),
            _campo(_informacoes, 'Informações comerciais', linhas: 3),
          ],
        );
      case SecaoConfiguracao.geral:
        return Column(
          children: [
            _campo(
              _maoDeObra,
              'Mão de obra padrão (R\$)',
              teclado: const TextInputType.numberWithOptions(decimal: true),
            ),
            _campo(
              _trocaTela,
              'Mão de obra: troca de tela (R\$)',
              teclado: const TextInputType.numberWithOptions(decimal: true),
            ),
            _campo(
              _trocaConector,
              'Mão de obra: troca de conector (R\$)',
              teclado: const TextInputType.numberWithOptions(decimal: true),
            ),
            const Text(
              'Esses valores só são usados em novas OS. Uma OS já criada mantém seu orçamento.',
            ),
          ],
        );
      case SecaoConfiguracao.personalizacao:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema visual', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: _tema,
              onChanged: (v) => setState(() => _tema = v!),
              title: const Text('Modo escuro premium'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: _tema,
              onChanged: (v) => setState(() => _tema = v!),
              title: const Text('Modo claro'),
            ),
            const Text('A preferência é salva apenas para esta empresa.'),
          ],
        );
      case SecaoConfiguracao.meta:
        return Column(
          children: [
            _campo(
              _metaMensal,
              'Meta mensal de faturamento (R\$)',
              teclado: const TextInputType.numberWithOptions(decimal: true),
              obrigatorio: true,
            ),
            const Text(
              'O dashboard usa as entradas financeiras do mês para atualizar o progresso automaticamente.',
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulos = {
      SecaoConfiguracao.perfil: 'Perfil da empresa',
      SecaoConfiguracao.geral: 'Configurações',
      SecaoConfiguracao.personalizacao: 'Personalização',
      SecaoConfiguracao.meta: 'Meta e valores',
    };
    return Scaffold(
      appBar: AppBar(title: Text(titulos[_secao]!)),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SegmentedButton<SecaoConfiguracao>(
                    segments: const [
                      ButtonSegment(
                        value: SecaoConfiguracao.perfil,
                        icon: Icon(Icons.business),
                        label: Text('Perfil'),
                      ),
                      ButtonSegment(
                        value: SecaoConfiguracao.geral,
                        icon: Icon(Icons.settings),
                        label: Text('Geral'),
                      ),
                      ButtonSegment(
                        value: SecaoConfiguracao.personalizacao,
                        icon: Icon(Icons.palette),
                        label: Text('Tema'),
                      ),
                      ButtonSegment(
                        value: SecaoConfiguracao.meta,
                        icon: Icon(Icons.flag),
                        label: Text('Meta'),
                      ),
                    ],
                    selected: {_secao},
                    onSelectionChanged: (valor) =>
                        setState(() => _secao = valor.first),
                  ),
                  const SizedBox(height: 24),
                  _conteudo(),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _salvando ? null : _salvar,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _salvando ? 'Salvando...' : 'Salvar configurações',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _nome,
      _logoUrl,
      _telefone,
      _endereco,
      _informacoes,
      _metaMensal,
      _maoDeObra,
      _trocaTela,
      _trocaConector,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }
}
