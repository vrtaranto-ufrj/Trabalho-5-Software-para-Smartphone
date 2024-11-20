import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class Tarefa {
  late final String titulo;
  late bool feito;
  bool isDeleting = false;
  Timer? deletingTimer;
  bool isAnimating = false;
  BuildContext? itemContext;


  Tarefa({required this.titulo, this.feito = false});
}

class Mensagem {
  final String papel;
  final String conteudo;

  Mensagem({required this.papel, required this.conteudo});
}

class Conversa {
  final String id;
  final DateTime criacao;
  final DateTime ultimaAlteracao;
  final List<Mensagem> mensagens;

  Conversa({required this.id, required this.criacao, required this.ultimaAlteracao, required this.mensagens});
}

class RespostaChat {
  final String? pergunta;
  final List<Tarefa>? tarefas;

  RespostaChat({this.pergunta, this.tarefas});
}

class Conexao {
  String? token;
  late String email;
  late String senha;
  static const String maquinaUrl = 'barra.cos.ufrj.br';
  static const int porta = 443;
  static const String urlBase = '$maquinaUrl:$porta';

  Future<void> fazerLogin([String? email, String? senha]) async {
    email ??= this.email;
    senha ??= this.senha;
    final Uri url = Uri.https(urlBase, '/rest/rpc/fazer_login');

    const Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final Map<String, String> body = {
      'email': email,
      'senha': senha,
    };

    final String jsonBody = json.encode(body);

    try {
      final http.Response response =
          await http.post(url, headers: headers, body: jsonBody);
      switch (response.statusCode) {
        case 200:
          final Map<String, dynamic> data = json.decode(response.body);

          if (data.containsKey('token')) {
            token = data['token'];
            this.email = email;
            this.senha = senha;
          } else {
            throw Exception('Token não encontrado na resposta.');
          }
          break;
        case 401:
          throw Exception('Usuário não encontrado ou senha incorreta.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception(
          'Ocorreu um erro em fazer login: ${e.toString().split(' ').skip(1).join(' ')}');
    }
  }

  Future<void> fazerCadastro(
      String nome, String email, String celular, String senha) async {
    final Uri url = Uri.https(urlBase, '/rest/rpc/registra_usuario');

    const Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final Map<String, String> body = {
      'nome': nome,
      'email': email,
      'celular': celular,
      'senha': senha,
    };

    final String jsonBody = json.encode(body);

    try {
      final http.Response response =
          await http.post(url, headers: headers, body: jsonBody);
      switch (response.statusCode) {
        case 200:
          this.email = email;
          this.senha = senha;
          break;
        default:
          throw Exception('Erro: ${response.statusCode} - ${jsonDecode(response.body)['message']}');
      }
    } catch (e) {
      throw Exception('Ocorreu um erro em fazer cadastro: ${e.toString()}');
    }
  }

  Future<List<Tarefa>?> getTarefas() async {
    final Uri url = Uri.https(urlBase, '/rest/tarefas');

    late Map<String, String> headers = {
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final http.Response response = await http.get(url, headers: headers);

      switch (response.statusCode) {
        case 200:
          final List<dynamic> data = json.decode(response.body);
          if (data.isEmpty) {
            return null;
          }
          final List<dynamic> lista = data[0]['valor'];

          return lista
              .map(
                (tarefa) => Tarefa(
                  titulo: tarefa['titulo'],
                  feito: tarefa['feito'],
                ),
              )
              .toList();

        case 401:
          throw Exception('Você não está autenticado.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Ocorreu um erro em pegar as tarefas: ${e.toString()}');
    }
  }

  Future<void> atualizaTarefas(List<Tarefa> tarefas) async {
    final Uri url = Uri.https(urlBase, '/rest/tarefas');

    late Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      'email': email,
      'valor': tarefas
          .map((tarefa) => {
                'titulo': tarefa.titulo,
                'feito': tarefa.feito,
              })
          .toList(),
    };

    final String jsonBody = json.encode(body);

    try {
      final http.Response response =
          await http.patch(url, headers: headers, body: jsonBody);

      switch (response.statusCode) {
        case 204:
          break;
        case 401:
          throw Exception('Você não está autenticado.');
        case 403:
          throw Exception('Você não tem permissão para acessar este recurso.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception(
          'Ocorreu um erro em atualizar tarefas: ${e.toString().split(' ').skip(1).join(' ')}');
    }
  }

  Future<void> deletarLista() async {
    final Uri url = Uri.https(urlBase, '/rest/tarefas');

    late Map<String, String> headers = {
      'accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final http.Response response = await http.delete(url, headers: headers);

      switch (response.statusCode) {
        case 204:
          break;
        case 401:
          throw Exception('Você não está autenticado.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Ocorreu um erro em deletar lista: ${e.toString()}');
    }
  }

  Future<void> criaLista() async {
    final Uri url = Uri.https(urlBase, '/rest/tarefas');

    late Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      'email': email,
      'valor': [],
    };

    final String jsonBody = json.encode(body);

    try {
      final http.Response response =
          await http.post(url, headers: headers, body: jsonBody);

      switch (response.statusCode) {
        case 201:
          break;
        case 401:
          throw Exception('Você não está autenticado.');
        case 403:
          throw Exception('Você não tem permissão para acessar este recurso.');
        case 409:
          throw Exception('Já existe uma lista para este usuário.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Ocorreu um erro em criar lista: ${e.toString()}');
    }
  }

  Future<String?> criarConversa() async {
    final Uri url = Uri.https(urlBase, '/rest/rpc/cria_conversa');

    late Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final http.Response response = await http.post(url, headers: headers);

      switch (response.statusCode) {
        case 200:
          return response.body;
        case 401:
          throw Exception('Você não está autenticado.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Ocorreu um erro em criar conversa: ${e.toString()}');
    }

  }

  Future<List<Conversa>?> getConversas() async {
    final Uri url = Uri.https(urlBase, '/rest/conversas');

    late Map<String, String> headers = {
      'accept': 'application/json',
      'Authorization' : 'Bearer $token',
    };

    try {
      final http.Response response = await http.get(url, headers: headers);

      switch (response.statusCode) {
        case 200:
          final List<dynamic> lista = json.decode(response.body);
          if (lista.isEmpty) {
            return null;
          }

          return lista
              .map(
                (conversa) => Conversa(
                  id: conversa['id'],
                  criacao: DateTime.parse(conversa['criacao']),
                  ultimaAlteracao: DateTime.parse(conversa['ultima_alteracao']),
                  mensagens: (conversa['mensagens'] as List<dynamic>)
                      .map(
                        (mensagem) => Mensagem(
                          papel: mensagem['papel'],
                          conteudo: mensagem['conteudo'],
                        ),
                      )
                      .toList(),
                ),
              )
              .toList();
      
        case 401:
          throw Exception('Você não está autenticado.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Ocorreu um erro em pegar as conversas: ${e.toString()}');
    }
  }

  Future<RespostaChat> getRespostaChat(String mensagem, String id) async {
    final Uri url = Uri.https(urlBase, '/rest/rpc/envia_resposta');

    late Map<String, String> headers = {
      'accept': 'application/json',
      'Authorization' : 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final Map<String, dynamic> body = {
      'conversa_id': id,
      'resposta': mensagem,
    };

    try {
      final http.Response response = await http.post(url, headers: headers, body: json.encode(body));

      switch (response.statusCode) {
        case 200:
          final Map<String,dynamic> respostaChat = json.decode(response.body);

          final String? pergunta = respostaChat['pergunta'];
          if (pergunta != null) {
            return RespostaChat(pergunta: pergunta);
          }
          final List<dynamic>? tarefas = respostaChat['tarefas'];
          if (tarefas != null) {
            return RespostaChat(tarefas: tarefas.map((tarefa) => Tarefa(titulo: tarefa)).toList());
          }
          throw Exception('Resposta inválida. Nem pergunta nem tarefas encontradas.');
        case 401:
          throw Exception('Você não está autenticado.');
        default:
          throw Exception('Erro: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Ocorreu um erro em pegar a resposta do chat: ${e.toString()}');
    }
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Lista de Tarefas',
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.conexao});
  final Conexao conexao;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Menu'),
          ),
          ListTile(
            title: const Text('Lista de Tarefas'),
            onTap: () {
              // Navegar apenas se não estiver na mesma tela
              if (ModalRoute.of(context)?.settings.name != '/task_list') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskListScreen(conexao: conexao),
                    settings: const RouteSettings(name: '/task_list'),
                  ),
                );
              } else {
                Navigator.pop(context); // Fecha o Drawer
              }
            },
          ),
          ListTile(
            title: const Text('Chat'),
            onTap: () {
              if (ModalRoute.of(context)?.settings.name != '/chat') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(conexao: conexao),
                    settings: const RouteSettings(name: '/chat'),
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
          ),
          ListTile(
            title: const Text('Nova Conversa'),
            onTap: () {
              conexao.criarConversa().then((value) {
                if (value == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao criar conversa.'),
                    ),
                  );
                }
              }).catchError((e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao criar conversa: ${e.toString()}'),
                  ),
                );
              });
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(conexao: conexao),
                  settings: const RouteSettings(name: '/chat'),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Logout'),
            onTap: () {
              conexao.token = null;
              conexao.email = '';
              conexao.senha = '';
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                  settings: const RouteSettings(name: '/login'),
                  ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String email = _emailController.text.trim();
    String senha = _senhaController.text.trim();

    Conexao conexao = Conexao();
    try {
      await conexao.fazerLogin(email, senha);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(conexao: conexao),
            settings: const RouteSettings(name: '/task_list'), // Define o nome da rota
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().split(' ').skip(1).join(' ');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Formato de email inválido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Entrar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen(),
                        settings: const RouteSettings(name: '/register'), // Define o nome da rota
                      ),
                  );
                },
                child: const Text('Não tem conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Registration Screen
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  RegistrationScreenState createState() => RegistrationScreenState();
}

class RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmSenhaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _errorMessage;

  void _register() async {
    if (!_formKey.currentState!.validate()) {
      // Se o formulário for inválido, não prosseguir
      return;
    }

    String nome = _nomeController.text.trim();
    String email = _emailController.text.trim();
    String celular = _celularController.text.trim();
    String senha = _senhaController.text.trim();
    String confirmSenha = _confirmSenhaController.text.trim();

    if (senha != confirmSenha) {
      setState(() {
        _errorMessage = 'As senhas não coincidem.';
      });
      return;
    }

    Conexao conexao = Conexao();
    bool success = false;
    try {
      await conexao.fazerCadastro(nome, email, celular, senha);
      success = true;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      return;
    }

    if (success) {
      // Cadastro bem-sucedido
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const LoginScreen(),
              settings: const RouteSettings(name: '/login'), // Define o nome da rota
            ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cadastro'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu nome';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu email';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Formato de email inválido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _celularController,
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira seu número de celular';
                      }
                      final celularRegex =
                          RegExp(r'^\(?\d{2}\)?[\s-]?\d{4,5}-?\d{4}$');
                      if (!celularRegex.hasMatch(value)) {
                        return 'Formato de celular inválido';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _senhaController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira uma senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _confirmSenhaController,
                    decoration: const InputDecoration(
                      labelText: 'Confirme a Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != _senhaController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Registrar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                            settings: const RouteSettings(name: '/login'), // Define o nome da rota
                          ),
                      );
                    },
                    child: const Text('Já tem conta? Faça login'),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

// Task List Screen
class TaskListScreen extends StatefulWidget {
  final Conexao conexao;
  final List<Tarefa>? tarefas;

  const TaskListScreen({required this.conexao, super.key, this.tarefas});

  @override
  TaskListScreenState createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  List<Tarefa> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;
  late Animation<double> animation;
  late AnimationController animationController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late Animation<double> rotationAnimation;
  double _rotationAngle = 0.0;

  // Variáveis adicionadas
  bool _isAnimating = false;
  Widget? _animatedTask;
  double _animationTop = 0.0;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadTasks();
  }

  void _loadTasks() async {
    if (widget.tarefas != null) {
      setState(() {
        _tasks = widget.tarefas!;
        _isLoading = false;
      });
      return;
    }
    try {
      List<Tarefa>? tasks = await widget.conexao.getTarefas();
      if (tasks == null) {
        // Nenhuma tarefa encontrada, criar uma nova lista
        await widget.conexao.criaLista();
        tasks = [];
      }
      setState(() {
        _tasks = tasks ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('Você não está autenticado.')) {
        _showSessionExpiredDialog();
      }
      setState(() {
        _errorMessage = e.toString().split(' ').skip(1).join(' ');
        _isLoading = false;
      });
    }
  }

  void _addTask() {
    String input = _controller.text.trim();
    if (input.isEmpty) return;

    // Verificar duplicatas
    bool duplicate = _tasks.any((task) => task.titulo.toLowerCase() == input.toLowerCase());
    if (duplicate) return;

    Tarefa newTask = Tarefa(titulo: input, feito: false);

    setState(() {
      _tasks.add(newTask);
      _controller.clear();
    });

    _listKey.currentState?.insertItem(_tasks.length - 1);
    _saveTasks();
  }

  void _deleteTask(int index) {
    Tarefa task = _tasks[index];
    String taskTitle = task.titulo;

    setState(() {
      task.isDeleting = true;
      task.deletingTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          // Encontrar o índice atual da tarefa
          int currentIndex = _tasks.indexWhere((t) => t.titulo == taskTitle && t.isDeleting);
          if (currentIndex != -1) {
            // Remover a tarefa da lista de dados
            _tasks.removeAt(currentIndex);
            // Remover o item da AnimatedList
            _listKey.currentState?.removeItem(
              currentIndex,
              (context, animation) => _buildRemovedTaskItem(context, currentIndex, task, animation),
            );
            _saveTasks();
          }
        });
      });
    });
  }

  void _undoDelete(int index) {
    Tarefa task = _tasks[index];

    setState(() {
      task.isDeleting = false;
      task.deletingTimer?.cancel();
      task.deletingTimer = null;
    });
  }

  void _toggleCompletion(int index) async {
    final task = _tasks[index];

    // Obter a posição atual do item
    final RenderBox? itemRenderBox = task.itemContext?.findRenderObject() as RenderBox?;
    if (itemRenderBox == null) return; // Não foi possível encontrar o RenderBox
    final Offset itemPosition = itemRenderBox.localToGlobal(Offset.zero);
    final Size itemSize = itemRenderBox.size;

    // Determinar o índice de destino sem alterar a lista
    int targetIndex;
    if (!task.feito) {
      // Tarefa sendo marcada como concluída - mover para a última posição
      targetIndex = _tasks.length - 1;
    } else {
      // Tarefa sendo desmarcada - mover para a primeira posição
      targetIndex = 0;
    }

    if (targetIndex == index) {
      // Se o índice não mudar, não é necessário animar
      setState(() {
        task.feito = !task.feito;
      });
      _saveTasks();
      return;
    }

    // Obter a posição de destino
    double targetPositionDy;
    if (targetIndex < _tasks.length) {
      final targetTask = _tasks[targetIndex];
      final RenderBox? targetRenderBox = targetTask.itemContext?.findRenderObject() as RenderBox?;
      if (targetRenderBox == null) return;
      final Offset targetPosition = targetRenderBox.localToGlobal(Offset.zero);
      targetPositionDy = targetPosition.dy;
    } else {
      // Se movendo para o final da lista
      final listRenderBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
      if (listRenderBox == null) return;
      targetPositionDy = listRenderBox.localToGlobal(Offset.zero).dy + listRenderBox.size.height - itemSize.height;
    }

    // Configurar a animação
    setState(() {
      _isAnimating = true;
      _animationTop = itemPosition.dy;
      _rotationAngle = 0.1;
      _animatedTask = _buildAnimatedTask(task);
      task.isAnimating = true; // Oculta a tarefa na lista durante a animação
    });

    animationController.reset();
    
    animation = Tween<double>(
      begin: itemPosition.dy - 130,
      end: targetPositionDy - 130,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    rotationAnimation = Tween<double>(
      begin: 0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    animationController.addListener(() {
      setState(() {
        _animationTop = animation.value;
        _rotationAngle = rotationAnimation.value;
      });
    });

    await animationController.forward();

    // Após a animação, atualizar a lista de tarefas e a AnimatedList
    setState(() {
      _isAnimating = false;
      _animatedTask = null;
      task.isAnimating = false;

      // Atualizar o estado de conclusão da tarefa
      task.feito = !task.feito;

      // Remover a tarefa da posição antiga
      _tasks.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => const SizedBox.shrink(),
        duration: const Duration(milliseconds: 0),
      );

      // Inserir a tarefa na nova posição
      if (task.feito) {
        _tasks.add(task);
        _listKey.currentState?.insertItem(_tasks.length - 1, duration: const Duration(milliseconds: 0));
      } else {
        _tasks.insert(0, task);
        _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 0));
      }
    });

    animationController.removeListener(() {});

    _saveTasks();
  }

  void _saveTasks() async {
    try {
      await widget.conexao.atualizaTarefas(_tasks);
    } catch (e) {
      if (e.toString().contains('Você não está autenticado.')) {
        _showSessionExpiredDialog();
      }
      setState(() {
        _errorMessage = e.toString().split(' ').skip(1).join(' ');
      });
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sessão Expirada'),
          content: const Text('Sua sessão expirou. Por favor, faça login novamente.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    animationController.dispose();
    for (var task in _tasks) {
      task.deletingTimer?.cancel();
    }
    super.dispose();
  }

  Widget _buildTaskItem(BuildContext context, int index) {
    if (index >= _tasks.length) {
      // Índice inválido
      return const SizedBox.shrink();
    }
    final task = _tasks[index];

    if (task.isAnimating) {
      // Ocultar o item original durante a animação
      return const SizedBox.shrink();
    }

    Color bgColor;
    if (task.isDeleting) {
      bgColor = Colors.red.shade100;
    } else {
      bgColor = index % 2 == 0 ? Colors.grey.shade200 : Colors.white;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 3,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: ValueKey(task.titulo), // Use um ValueKey em vez de GlobalKey
        background: Container(
          color: Colors.green,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.check, color: Colors.white),
        ),
        secondaryBackground: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (task.isDeleting) return false;
          if (direction == DismissDirection.endToStart) {
            // Deslizar para deletar
            _deleteTask(index);
            return false;
          } else if (direction == DismissDirection.startToEnd) {
            // Deslizar para concluir
            _toggleCompletion(index);
            return false;
          }
          return false;
        },
        child: Builder(
          builder: (context) {
            // Salvar o BuildContext para obter a posição do widget mais tarde
            task.itemContext = context;
            return ListTile(
              leading: Checkbox(
                value: task.feito,
                onChanged: (bool? value) {
                  _toggleCompletion(index);
                },
              ),
              title: task.isDeleting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task.titulo,
                          style: TextStyle(
                            decoration: task.feito
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: Colors.red,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _undoDelete(index);
                          },
                          child: const Text(
                            'Desfazer',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      task.titulo,
                      style: TextStyle(
                        decoration: task.feito
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
              trailing: task.isDeleting
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteTask(index);
                      },
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedTask(Tarefa task) {
    return Positioned(
      top: _animationTop,
      left: 0,
      right: 0,
      child: Transform(
        alignment: Alignment.topLeft,
        transform: Matrix4.identity()
          ..rotateZ(_rotationAngle),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.yellowAccent, // Cor diferenciada durante a animação
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 3,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: Checkbox(
              value: task.feito,
              onChanged: null, // Desabilitar interação durante a animação
            ),
            title: Text(
              task.titulo,
              style: TextStyle(
                decoration: task.feito ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            trailing: const IconButton(
              icon: Icon(Icons.delete),
              onPressed: null, // Desabilitar interação durante a animação
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemovedTaskItem(BuildContext context, int index, Tarefa task, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: _buildTaskItem(context, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Tarefas'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                // Logout e navega para a tela de login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
        drawer: AppDrawer(conexao: widget.conexao),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Entrada de Tarefa
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  labelText: 'Nova Tarefa',
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (value) => _addTask(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addTask,
                              child: const Text('Adicionar'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Lista de Tarefas
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _tasks.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Nenhuma tarefa adicionada.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : AnimatedList(
                                        key: _listKey,
                                        initialItemCount: _tasks.length,
                                        itemBuilder: (context, index, animation) {
                                          return SizeTransition(
                                            sizeFactor: animation,
                                            child: _buildTaskItem(context, index),
                                          );
                                        },
                                      ),
                              ),
                              if (_isAnimating && _animatedTask != null)
                                Positioned(
                                  top: _animationTop,
                                  left: 0,
                                  right: 0,
                                  child: _animatedTask!,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conexao});
  final Conexao conexao;


  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  List<Conversa> _conversas = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false; // Para gerenciar o estado do envio de mensagem


  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      drawer: AppDrawer(conexao: widget.conexao),
      body: Column(
        children: [
          Expanded(
            child: _conversas.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _conversas.first.mensagens.length,
                    itemBuilder: (context, index) {
                      final mensagem = _conversas.first.mensagens[index];
                      final isLeft = mensagem.papel == 'usuario'; // Alinhamento
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Align(
                          alignment: isLeft
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Callout(
                            triangleSize: 20,
                            triangleHeight: 10,
                            backgroundColor: isLeft
                                ? Colors.grey[300]!
                                : Colors.blue,
                            isLeft: isLeft,
                            position: isLeft ? "left" : "right",
                            child: Text(
                              mensagem.conteudo,
                              style: TextStyle(
                                color: isLeft
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isSending ? Icons.hourglass_top : Icons.send,
                    color: _isSending ? Colors.grey : Colors.blue,
                  ),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _loadConversations() async {
    try {
      List<Conversa>? conversas = await widget.conexao.getConversas();
      if (conversas == null) {
        // Nenhuma conversa encontrada, criar uma nova
        await widget.conexao.criarConversa();
        conversas = await widget.conexao.getConversas();
      }
      setState(() {
        _conversas = conversas ?? [];
      });
    } catch (e) {
      if (e.toString().contains('Você não está autenticado.')) {
        _showSessionExpiredDialog();
      }
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    // Adiciona a mensagem do usuário na conversa
    setState(() {
      _isSending = true;
      _conversas.first.mensagens.add(Mensagem(
        papel: 'usuario',
        conteudo: messageText,
      ));
      _messageController.clear();
    });

    try {
      // Chama a API para obter a resposta do chat
      final resposta = await widget.conexao.getRespostaChat(messageText, _conversas.first.id);

      if (resposta.pergunta != null) {
        // Adiciona a resposta como mensagem do sistema
        setState(() {
          _conversas.first.mensagens.add(Mensagem(
            papel: 'sistema',
            conteudo: resposta.pergunta!,
          ));
        });
      } else if (resposta.tarefas != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaskListScreen(
              conexao: widget.conexao,
              tarefas: resposta.tarefas,
            ),
            settings: const RouteSettings(name: '/task_list'),
          ),
        );
        return;
      }
    } catch (e) {
      // Tratar erros ao enviar mensagem
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar mensagem: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sessão Expirada'),
          content: const Text('Sua sessão expirou. Por favor, faça login novamente.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context)
                  ..pop()
                  ..pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
              },
            ),
          ],
        );
      },
    );
  }
}

class CalloutPainter extends CustomPainter {
  final double triangleSize;
  final double triangleHeight;
  final String position;
  final Color backgroundColor;
  final bool isLeft; // Define se o balão é da esquerda ou direita

  CalloutPainter({
    required this.triangleSize,
    required this.triangleHeight,
    required this.position,
    required this.backgroundColor,
    this.isLeft = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final Path balloonPath = Path();

    // Definir o corpo do balão (retângulo arredondado)
    const double margin = 10;
    const double radius = 8;
    final double bodyHeight = size.height - triangleHeight - margin;

    balloonPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(margin, margin, size.width - 2 * margin, bodyHeight),
      const Radius.circular(radius),
    ));

    // Desenhar a seta na parte de baixo com inclinação para fora
    final Path trianglePath = Path();

    if (position == "left") {
      // Seta no lado esquerdo inferior, inclinada para a esquerda (obtusa)
      trianglePath.moveTo(
          margin + 10, bodyHeight + margin); // Base esquerda da seta
      trianglePath.lineTo(margin + 10 + triangleSize,
          bodyHeight + margin); // Base direita da seta
      trianglePath.lineTo(
          margin - 10, size.height); // Ponta da seta inclinada para fora
    } else if (position == "right") {
      // Seta no lado direito inferior, inclinada para a direita (obtusa)
      trianglePath.moveTo(size.width - margin - 10 - triangleSize,
          bodyHeight + margin); // Base esquerda da seta
      trianglePath.lineTo(size.width - margin - 10,
          bodyHeight + margin); // Base direita da seta
      trianglePath.lineTo(size.width + 10 - margin,
          size.height); // Ponta da seta inclinada para fora
    } else {
      // Seta no centro inferior (isósceles)
      double centerX = (size.width - triangleSize) / 2;
      trianglePath.moveTo(
          centerX, bodyHeight + margin); // Base esquerda da seta
      trianglePath.lineTo(
          centerX + triangleSize, bodyHeight + margin); // Base direita da seta
      trianglePath.lineTo(
          centerX + triangleSize / 2, size.height); // Ponta da seta (centro)
    }

    balloonPath.addPath(trianglePath, Offset.zero);

    // Desenhar o balão e a seta
    canvas.drawShadow(balloonPath, Colors.black, 6, false);
    canvas.drawPath(balloonPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class Callout extends StatelessWidget {
  final Widget child;
  final double triangleSize;
  final double triangleHeight;
  final String position;
  final Color backgroundColor;
  final bool isLeft;

  const Callout({
    super.key,
    required this.child,
    this.triangleSize = 20,
    this.triangleHeight = 10,
    this.position = "left",
    this.backgroundColor = Colors.white,
    this.isLeft = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CalloutPainter(
        triangleSize: triangleSize,
        triangleHeight: triangleHeight,
        position: position,
        backgroundColor: backgroundColor,
        isLeft: isLeft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
