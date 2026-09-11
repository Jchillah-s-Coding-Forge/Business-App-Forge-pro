import AppForgeDomain

struct FlutterGeneratedRecordIDSource {
    func file() -> GeneratedFile {
        GeneratedFile(
            relativePath: "lib/core/domain/record_id_generator.dart",
            contents: content
        )
    }

    // swiftformat:disable indent trailingSpace
    private var content: String {
        """
        import 'dart:math';

        abstract interface class RecordIdGenerator {
          String next();
        }

        class SecureUuidV4Generator implements RecordIdGenerator {
          SecureUuidV4Generator({Random? random})
            : _random = random ?? Random.secure();

          final Random _random;

          @override
          String next() {
            final bytes = List<int>.generate(
              16,
              (_) => _random.nextInt(256),
              growable: false,
            );
            bytes[6] = (bytes[6] & 0x0f) | 0x40;
            bytes[8] = (bytes[8] & 0x3f) | 0x80;
            final hex = bytes
                .map((value) => value.toRadixString(16).padLeft(2, '0'))
                .join();
            return '${hex.substring(0, 8)}-'
                '${hex.substring(8, 12)}-'
                '${hex.substring(12, 16)}-'
                '${hex.substring(16, 20)}-'
                '${hex.substring(20)}';
          }
        }
        """
            + "\n"
    }
    // swiftformat:enable indent trailingSpace
}
