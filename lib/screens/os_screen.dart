import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'os_detalhes_screen.dart';

class OsScreen extends StatefulWidget {
  @override
  State<OsScreen> createState() => _OsScreenState();
}

class _OsScreenState extends State<OsScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final String cloudName = 'dawfhy2w1';
  final String uploadPreset = 'elitecell_os';

  final clienteController = TextEditingController();
  final telefoneController = TextEditingController();
  final imeiController = TextEditingController();
  final marcaController = TextEditingController();
  final modeloController = TextEditingController();
  final defeitoController = TextEditingController();
  final valorController = TextEditingController();
  final observacaoController = TextEditingController();

  String statusSelecionado = 'Em análise';
  String? tecnicoSelecionado;

  String? pecaSelecionada;
  final quantidadePecaController = TextEditingController();

  String busca = '';
  bool salvando = false;

  bool chkLiga = true;
  bool chkTouch = true;
  bool chkTela = true;
  bool chkFaceId = true;
  bool chkBiometria = true;
  bool chkCameraFrontal = true;
  bool chkCameraTraseira = true;
  bool chkWifi = true;
  bool chkBluetooth = true;
  bool chkMicrofone = true;
  bool chkAltoFalante = true;
  bool chkConector = true;
  bool chkOxidado = false;

  File? fotoFrente;
  File? fotoTras;
  File? fotoImei;
  File? fotoAntesDepois;

  final os = FirebaseFirestore.instance.collection('ordens_servico');

  Future<void> escolherFoto(
    ImageSource origem,
    String tipo,
    void Function(void Function()) setModalState,
  ) async {
    final picker = ImagePicker();

    final imagem = await picker.pickImage(
      source: origem,
      imageQuality: 75,
    );

    if (imagem != null) {
      setState(() {
        if (tipo == 'frente') fotoFrente = File(imagem.path);
        if (tipo == 'tras') fotoTras = File(imagem.path);
        if (tipo == 'imei') fotoImei = File(imagem.path);
        if (tipo == 'antesDepois') fotoAntesDepois = File(imagem.path);
      });

      setModalState(() {});
    }
  }

  Future<String> uploadCloudinary(File? arquivo, String pasta) async {
    if (arquivo == null) return '';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;
    request.fields['folder'] = pasta;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        arquivo.path,
      ),
    );

    final response = await request.send();
    final resposta = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final json = jsonDecode(resposta);
      return json['secure_url'] ?? '';
    } else {
      throw Exception('Erro ao enviar foto para Cloudinary: $resposta');
    }
  }

  Future<void> salvarOS() async {
    if (salvando) return;

    setState(() {
      salvando = true;
    });

    try {
      final contadorRef = FirebaseFirestore.instance
          .collection('configuracoes')
          .doc('contador_os');

      int novoNumero = 0;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(contadorRef);

        int ultimoNumero = 0;

        if (snapshot.exists) {
          ultimoNumero = snapshot.get('ultimo_numero') ?? 0;
        }

        novoNumero = ultimoNumero + 1;

        transaction.set(contadorRef, {
          'ultimo_numero': novoNumero,
        });
      });

      final numeroOS = 'OS-${novoNumero.toString().padLeft(6, '0')}';
      final pasta = 'elitecell_os/$numeroOS';

      final fotoFrenteUrl = await uploadCloudinary(fotoFrente, pasta);
      final fotoTrasUrl = await uploadCloudinary(fotoTras, pasta);
      final fotoImeiUrl = await uploadCloudinary(fotoImei, pasta);
      final fotoAntesDepoisUrl = await uploadCloudinary(fotoAntesDepois, pasta);

      await os.add({
        'numero_os': numeroOS,
        'cliente': clienteController.text,
        'telefone': telefoneController.text,
        'imei': imeiController.text,
        'marca': marcaController.text,
        'modelo': modeloController.text,
        'defeito': defeitoController.text,
        'valor': valorController.text,
        'observacao': observacaoController.text,
        'status': statusSelecionado,
        'tecnico': tecnicoSelecionado ?? '',
        'peca_usada': pecaSelecionada ?? '',
        'quantidade_peca':
            int.tryParse(quantidadePecaController.text) ?? 0,

        'estoque_baixado': false,

        'checklist': {
          'liga': chkLiga,
          'touch': chkTouch,
          'tela': chkTela,
          'faceId': chkFaceId,
          'biometria': chkBiometria,
          'cameraFrontal': chkCameraFrontal,
          'cameraTraseira': chkCameraTraseira,
          'wifi': chkWifi,
          'bluetooth': chkBluetooth,
          'microfone': chkMicrofone,
          'altoFalante': chkAltoFalante,
          'conector': chkConector,
          'oxidado': chkOxidado,
        },

        'foto_url': fotoFrenteUrl,
        'foto_frente_url': fotoFrenteUrl,
        'foto_tras_url': fotoTrasUrl,
        'foto_imei_url': fotoImeiUrl,
        'foto_antes_depois_url': fotoAntesDepoisUrl,

        'foto_path': '',
        'foto_frente_path': '',
        'foto_tras_path': '',
        'foto_imei_path': '',
        'foto_antes_depois_path': '',

        'data': DateTime.now(),
      });

      clienteController.clear();
      telefoneController.clear();
      imeiController.clear();
      marcaController.clear();
      modeloController.clear();
      defeitoController.clear();
      valorController.clear();
      observacaoController.clear();
      quantidadePecaController.clear();

      setState(() {
        fotoFrente = null;
        fotoTras = null;
        fotoImei = null;
        fotoAntesDepois = null;

        chkLiga = true;
        chkTouch = true;
        chkTela = true;
        chkFaceId = true;
        chkBiometria = true;
        chkCameraFrontal = true;
        chkCameraTraseira = true;
        chkWifi = true;
        chkBluetooth = true;
        chkMicrofone = true;
        chkAltoFalante = true;
        chkConector = true;
        chkOxidado = false;

        tecnicoSelecionado = null;
        statusSelecionado = 'Em análise';
        salvando = false;
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OS salva com técnico responsável')),
      );
    } catch (e) {
      setState(() {
        salvando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar OS: $e')),
      );
    }
  }

  InputDecoration decoracaoCampo(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: dourado),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: dourado),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: dourado, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget campoFormulario(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: decoracaoCampo(label),
      ),
    );
  }

  Widget itemChecklist(
    String titulo,
    bool valor,
    Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      value: valor,
      activeColor: dourado,
      checkColor: Colors.black,
      title: Text(
        titulo,
        style: TextStyle(color: Colors.white),
      ),
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget checklistEntrada(void Function(void Function()) setModalState) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dourado),
      ),
      child: Column(
        children: [
          Text(
            'CHECKLIST DE ENTRADA',
            style: TextStyle(
              color: dourado,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          itemChecklist('Liga', chkLiga, (v) => setModalState(() => chkLiga = v!)),
          itemChecklist('Touch funcionando', chkTouch, (v) => setModalState(() => chkTouch = v!)),
          itemChecklist('Tela sem manchas', chkTela, (v) => setModalState(() => chkTela = v!)),
          itemChecklist('Face ID', chkFaceId, (v) => setModalState(() => chkFaceId = v!)),
          itemChecklist('Biometria', chkBiometria, (v) => setModalState(() => chkBiometria = v!)),
          itemChecklist('Câmera frontal', chkCameraFrontal, (v) => setModalState(() => chkCameraFrontal = v!)),
          itemChecklist('Câmera traseira', chkCameraTraseira, (v) => setModalState(() => chkCameraTraseira = v!)),
          itemChecklist('Wi-Fi', chkWifi, (v) => setModalState(() => chkWifi = v!)),
          itemChecklist('Bluetooth', chkBluetooth, (v) => setModalState(() => chkBluetooth = v!)),
          itemChecklist('Microfone', chkMicrofone, (v) => setModalState(() => chkMicrofone = v!)),
          itemChecklist('Alto-falante', chkAltoFalante, (v) => setModalState(() => chkAltoFalante = v!)),
          itemChecklist('Conector de carga', chkConector, (v) => setModalState(() => chkConector = v!)),
          itemChecklist('Aparelho oxidado', chkOxidado, (v) => setModalState(() => chkOxidado = v!)),
        ],
      ),
    );
  }

  Widget previewFoto(
    String titulo,
    File? arquivo,
    String tipo,
    void Function(void Function()) setModalState,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dourado),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: dourado,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          if (arquivo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                arquivo,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Nenhuma foto',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await escolherFoto(
                      ImageSource.camera,
                      tipo,
                      setModalState,
                    );
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text('Câmera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dourado,
                    side: BorderSide(color: dourado),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await escolherFoto(
                      ImageSource.gallery,
                      tipo,
                      setModalState,
                    );
                  },
                  icon: Icon(Icons.photo),
                  label: Text('Galeria'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dourado,
                    side: BorderSide(color: dourado),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget tecnicoDropdown(void Function(void Function()) setModalState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tecnicos')
          .orderBy('nome')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox();
        }

        final tecnicos = snapshot.data!.docs;

        if (tecnicos.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Nenhum técnico cadastrado',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: tecnicoSelecionado,
            dropdownColor: Color(0xFF111111),
            style: TextStyle(color: Colors.white),
            decoration: decoracaoCampo('Técnico Responsável'),
            items: tecnicos.map((doc) {
              final dados = doc.data() as Map<String, dynamic>;

              return DropdownMenuItem<String>(
                value: dados['nome'],
                child: Text(dados['nome']),
              );
            }).toList(),
            onChanged: (valor) {
              setModalState(() {
                tecnicoSelecionado = valor;
              });
            },
          ),
        );
      },
    );
  }

  void abrirFormulario() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Color(0xFF111111),
              title: Text(
                'Nova OS',
                style: TextStyle(color: dourado),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    campoFormulario(clienteController, 'Cliente'),
                    campoFormulario(telefoneController, 'Telefone'),
                    campoFormulario(imeiController, 'IMEI'),
                    campoFormulario(marcaController, 'Marca'),
                    campoFormulario(modeloController, 'Modelo'),
                    campoFormulario(defeitoController, 'Defeito'),
                    campoFormulario(valorController, 'Valor'),
                    campoFormulario(observacaoController, 'Observações'),

                    SizedBox(height: 12),

                    tecnicoDropdown(setModalState),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('estoque')
                          .orderBy('nome')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox();

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            value: pecaSelecionada,
                            dropdownColor: Color(0xFF111111),
                            style: TextStyle(color: Colors.white),
                            decoration: decoracaoCampo('Peça Utilizada'),
                            items: snapshot.data!.docs.map((doc) {
                              final dados = doc.data() as Map<String, dynamic>;

                              return DropdownMenuItem<String>(
                                value: dados['nome'],
                                child: Text(dados['nome']),
                              );
                            }).toList(),
                            onChanged: (valor) {
                              setModalState(() {
                                pecaSelecionada = valor;
                              });
                            },
                          ),
                        );
                      },
                    ),

                    campoFormulario(
                      quantidadePecaController,
                      'Quantidade da peça',
                    ),

                    checklistEntrada(setModalState),

                    SizedBox(height: 12),

                    previewFoto('Foto frontal', fotoFrente, 'frente', setModalState),
                    previewFoto('Foto traseira', fotoTras, 'tras', setModalState),
                    previewFoto('Foto do IMEI', fotoImei, 'imei', setModalState),
                    previewFoto('Foto antes/depois', fotoAntesDepois, 'antesDepois', setModalState),

                    SizedBox(height: 10),

                    DropdownButtonFormField<String>(
                      value: statusSelecionado,
                      dropdownColor: Color(0xFF111111),
                      style: TextStyle(color: Colors.white),
                      decoration: decoracaoCampo('Status'),
                      items: [
                        'Em análise',
                        'Aprovado',
                        'Aguardando peça',
                        'Em reparo',
                        'Pronto',
                        'Entregue',
                        'Cancelado',
                      ].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        setModalState(() {
                          statusSelecionado = valor!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando
                      ? null
                      : () {
                          setState(() {
                            fotoFrente = null;
                            fotoTras = null;
                            fotoImei = null;
                            fotoAntesDepois = null;
                            tecnicoSelecionado = null;
                            pecaSelecionada = null;
                            quantidadePecaController.clear();
                          });
                          Navigator.pop(context);
                        },
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: salvando ? null : salvarOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dourado,
                    foregroundColor: Colors.black,
                  ),
                  child: salvando
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget leadingOS(Map<String, dynamic> dadosOs) {
    final fotoUrl = (dadosOs['foto_frente_url'] ??
            dadosOs['foto_url'] ??
            '')
        .toString();

    if (fotoUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(fotoUrl),
      );
    }

    return Icon(Icons.build, color: dourado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Ordens de Serviço',
          style: TextStyle(color: dourado),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: dourado),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: abrirFormulario,
        child: Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar OS...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: dourado),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: dourado),
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: dourado, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (valor) {
                setState(() {
                  busca = valor;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: os.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                final filtrados = snapshot.data!.docs.where((doc) {
                  final dadosOs = doc.data() as Map<String, dynamic>;
                  final texto = busca.toLowerCase();

                  return (dadosOs['cliente'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(texto) ||
                      (dadosOs['telefone'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(texto) ||
                      (dadosOs['imei'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(texto) ||
                      (dadosOs['modelo'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(texto) ||
                      (dadosOs['numero_os'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(texto) ||
                      (dadosOs['tecnico'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(texto);
                }).toList();

                return ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
                    final dadosOs = item.data() as Map<String, dynamic>;
                    dadosOs['id'] = item.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OsDetalhesScreen(dados: dadosOs),
                          ),
                        );
                      },
                      child: Card(
                        color: Color(0xFF111111),
                        margin: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: dourado, width: 1),
                        ),
                        child: ListTile(
                          leading: leadingOS(dadosOs),
                          title: Text(
                            '${dadosOs['numero_os'] ?? 'Sem número'} - ${dadosOs['cliente'] ?? ''}',
                            style: TextStyle(
                              color: dourado,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${dadosOs['marca'] ?? ''} ${dadosOs['modelo'] ?? ''}\n'
                            'Técnico: ${dadosOs['tecnico'] ?? 'Não definido'}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: Text(
                            dadosOs['status'] ?? '',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}