// cronogramaClases.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../repositorio_api/repositorio_api.dart';
import '../services/auth_service.dart';

class CronogramaClasesScreen extends StatefulWidget {
  final RepositorioAPI api;

  const CronogramaClasesScreen({Key? key, required this.api}) : super(key: key);

  @override
  _CronogramaClasesScreenState createState() => _CronogramaClasesScreenState();
}

class _CronogramaClasesScreenState extends State<CronogramaClasesScreen> {
  late Future<void> _cargarDatos;
  List<dynamic> cronograma = [];
  DateTime selectedMonth = DateTime.now();
  String? clienteDni;

  // Colores para diferentes clases
  final Map<String, Color> claseColors = {};
  final List<Color> availableColors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos = _obtenerCronograma();
  }

  Future<void> _obtenerCronograma() async {
    // 1️⃣ Obtener el DNI del usuario
    final userData = await AuthService.getUserData();
    clienteDni = userData?['dni'];
    if (clienteDni == null) return;

    // 2️⃣ Obtener el cronograma específico del usuario
    try {
      cronograma = await widget.api.obtenerCronograma(clienteDni!);

      // Asignar colores únicos a cada clase
      _asignarColoresClases();

      setState(() {});
    } catch (e) {
      print('Error al obtener cronograma: $e');
      cronograma = [];
      setState(() {});
    }
  }

  void _asignarColoresClases() {
    claseColors.clear();
    Set<String> nombresClases = {};

    // Obtener todos los nombres únicos de clases
    for (var clase in cronograma) {
      if (clase['nombre'] != null) {
        nombresClases.add(clase['nombre']);
      }
    }

    // Asignar colores a cada clase
    int colorIndex = 0;
    for (var nombreClase in nombresClases) {
      if (colorIndex < availableColors.length) {
        claseColors[nombreClase] = availableColors[colorIndex];
        colorIndex++;
      } else {
        // Si hay más clases que colores disponibles, usar colores aleatorios
        claseColors[nombreClase] =
            Colors.primaries[colorIndex % Colors.primaries.length];
        colorIndex++;
      }
    }
  }

  Color _obtenerColorClase(String nombreClase) {
    return claseColors[nombreClase] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cronograma de Clases'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _cargarDatos = _obtenerCronograma();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _cargarDatos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          return _buildCalendarioCompleto();
        },
      ),
    );
  }

  Widget _buildCalendarioCompleto() {
    return Column(
      children: [
        // Selector de mes
        _buildSelectorMes(),

        // Días de la semana
        _buildDiasSemana(),

        // Calendario
        Expanded(
          child: _buildCalendario(),
        ),
      ],
    );
  }

  Widget _buildSelectorMes() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () {
              setState(() {
                selectedMonth =
                    DateTime(selectedMonth.year, selectedMonth.month - 1);
              });
            },
          ),
          Text(
            DateFormat.yMMMM('es_ES').format(selectedMonth).toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: () {
              setState(() {
                selectedMonth =
                    DateTime(selectedMonth.year, selectedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiasSemana() {
    final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: diasSemana.map((dia) {
          return Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dia,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendario() {
    int year = selectedMonth.year;
    int month = selectedMonth.month;

    // Primer día del mes
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    // Día de la semana del primer día (0 = domingo, 1 = lunes, ..., 6 = sábado)
    int firstWeekday = firstDayOfMonth.weekday;
    // Ajustar para que la semana empiece en lunes (1)
    int startingDay = firstWeekday == 7 ? 0 : firstWeekday;

    int daysInMonth = DateUtils.getDaysInMonth(year, month);

    // Calcular el número total de celdas (días del mes + días vacíos al inicio)
    int totalCells = ((startingDay + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        // Calcular el día correspondiente a esta celda
        int dayNumber = index - startingDay + 1;

        if (dayNumber < 1 || dayNumber > daysInMonth) {
          // Celda vacía (fuera del mes actual)
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        DateTime day = DateTime(year, month, dayNumber);
        List<dynamic> clasesDia = _obtenerClasesDelDia(day);

        return GestureDetector(
          onTap: () => _mostrarClasesDia(day, clasesDia),
          child: Container(
            decoration: BoxDecoration(
              color: _obtenerColorDia(clasesDia),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: day.day == DateTime.now().day &&
                        month == DateTime.now().month &&
                        year == DateTime.now().year
                    ? Colors.blue
                    : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: clasesDia.isNotEmpty ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (clasesDia.isNotEmpty)
                  Text(
                    '${clasesDia.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<dynamic> _obtenerClasesDelDia(DateTime day) {
    return cronograma.where((clase) {
      if (clase['fecha'] != null) {
        DateTime fechaClase = DateTime.parse(clase['fecha']);
        return fechaClase.year == day.year &&
            fechaClase.month == day.month &&
            fechaClase.day == day.day;
      }
      return false;
    }).toList();
  }

  Color _obtenerColorDia(List<dynamic> clasesDia) {
    if (clasesDia.isEmpty) {
      return Colors.grey[200]!;
    }

    // Si hay múltiples clases, usar el color de la primera clase
    // o puedes modificar esto para hacer un gradiente si quieres mostrar múltiples colores
    String nombrePrimeraClase = clasesDia.first['nombre'] ?? '';
    return _obtenerColorClase(nombrePrimeraClase).withOpacity(0.8);
  }

  void _mostrarClasesDia(DateTime day, List<dynamic> clasesDia) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Clases del ${DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(day)}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: clasesDia.isEmpty
            ? Text('No hay clases agendadas para este día.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: clasesDia.map((clase) {
                    Color colorClase =
                        _obtenerColorClase(clase['nombre'] ?? '');

                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colorClase.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(color: colorClase, width: 4),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorClase,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          clase['nombre'] ?? 'Clase sin nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorClase,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (clase['descripcion'] != null &&
                                clase['descripcion'].isNotEmpty)
                              Text(
                                clase['descripcion'],
                                style: TextStyle(fontSize: 12),
                              ),
                            if (clase['fecha'] != null)
                              Text(
                                'Hora: ${DateFormat('HH:mm').format(DateTime.parse(clase['fecha']))}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CronogramaClasesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api != widget.api) {
      _cargarDatos = _obtenerCronograma();
    }
  }
}
