import AppForgeDomain

struct FlutterGeneratedAppHomeSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/presentation/generated_app_home.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'package:flutter/material.dart';

        class GeneratedAppDestination {
          const GeneratedAppDestination({
            required this.title,
            required this.subtitle,
            required this.builder,
          });

          final String title;
          final String subtitle;
          final WidgetBuilder builder;
        }

        class GeneratedAppHome extends StatelessWidget {
          const GeneratedAppHome({
            super.key,
            required this.title,
            required this.destinations,
          });

          final String title;
          final List<GeneratedAppDestination> destinations;

          @override
          Widget build(BuildContext context) {
            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: SafeArea(
                child: destinations.isEmpty
                    ? const _EmptyBusinessFeatures()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: destinations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final destination = destinations[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: const Icon(Icons.add_business_outlined),
                              title: Text(destination.title),
                              subtitle: Text(destination.subtitle),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _open(context, destination),
                            ),
                          );
                        },
                      ),
              ),
            );
          }

          Future<void> _open(
            BuildContext context,
            GeneratedAppDestination destination,
          ) async {
            final saved = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(builder: destination.builder),
            );
            if (!context.mounted || saved != true) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Saved successfully.')),
              );
          }
        }

        class _EmptyBusinessFeatures extends StatelessWidget {
          const _EmptyBusinessFeatures();

          @override
          Widget build(BuildContext context) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard_customize_outlined, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No create flows are configured.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Edit-only and read-only screens remain generated source.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
