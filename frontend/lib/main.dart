import 'package:material_ui/material_ui.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() {
  runApp(const JeevSwasthApp());
}

class JeevSwasthApp extends StatelessWidget {
  const JeevSwasthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightDynamic ??
                ColorScheme.fromSeed(
                  seedColor: const Color(0xFF4F6F52),
                ),
          ),

          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: const Color(0xFF4F6F52),
                  brightness: Brightness.dark,
                ),
          ),

          themeMode: ThemeMode.system,

          home: const DynamicColorTestScreen(),
        );
      },
    );
  }
}

class DynamicColorTestScreen extends StatelessWidget {
  const DynamicColorTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JeevSwasth'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Dynamic Material 3',
            style: Theme.of(context).textTheme.headlineSmall,
          ),

          const SizedBox(height: 8),

          Text(
            'Colors come from the device dynamic color system.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          _ColorBox(
            name: 'Primary',
            color: colors.primary,
            textColor: colors.onPrimary,
          ),

          _ColorBox(
            name: 'Primary Container',
            color: colors.primaryContainer,
            textColor: colors.onPrimaryContainer,
          ),

          _ColorBox(
            name: 'Secondary',
            color: colors.secondary,
            textColor: colors.onSecondary,
          ),

          _ColorBox(
            name: 'Secondary Container',
            color: colors.secondaryContainer,
            textColor: colors.onSecondaryContainer,
          ),

          _ColorBox(
            name: 'Tertiary',
            color: colors.tertiary,
            textColor: colors.onTertiary,
          ),

          _ColorBox(
            name: 'Tertiary Container',
            color: colors.tertiaryContainer,
            textColor: colors.onTertiaryContainer,
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: () {},
            child: const Text('Material 3 Button'),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Material 3 Card',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            decoration: const InputDecoration(
              labelText: 'Animal name',
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorBox extends StatelessWidget {
  final String name;
  final Color color;
  final Color textColor;

  const _ColorBox({
    required this.name,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}