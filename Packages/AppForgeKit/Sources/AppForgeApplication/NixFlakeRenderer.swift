import AppForgeDomain

public struct NixFlakeRenderer: Sendable {
    public init() {}

    public func render(
        _ plan: NixEnvironmentPlan
    ) -> String {
        let systems = plan.systems
            .map { "\"\($0.rawValue)\"" }
            .joined(separator: " ")
        let packages = plan.packages
            .map(\.rawValue)
            .map { "          \($0)" }

        return FlutterGeneratedText.lines(
            [
                "{",
                "  description = \"AppForge Pro reproducible development environment\";",
                "",
                "  inputs.nixpkgs.url = \"\(plan.nixpkgsInput)\";",
                "",
                "  outputs = { self, nixpkgs }:",
                "    let",
                "      systems = [ \(systems) ];",
                "      forAllSystems = nixpkgs.lib.genAttrs systems;",
                "    in",
                "    {",
                "      devShells = forAllSystems (system:",
                "        let",
                "          pkgs = import nixpkgs { inherit system; };",
                "        in",
                "        {",
                "          default = pkgs.mkShellNoCC {",
                "            packages = with pkgs; ["
            ]
                + packages
                + [
                    "            ];",
                    "          };",
                    "        });",
                    "    };",
                    "}",
                    ""
                ]
        )
    }
}
