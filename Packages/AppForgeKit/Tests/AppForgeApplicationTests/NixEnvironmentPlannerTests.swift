import AppForgeApplication
import AppForgeDomain
import XCTest

final class NixEnvironmentPlannerTests: XCTestCase {
    func testFlutterIOSAndAndroidPlanUsesNixForPortableTools() throws {
        let specification = makeSpecification(
            targets: [.iOS, .android]
        )

        let plan = try NixEnvironmentPlanner().plan(
            for: specification
        )

        XCTAssertEqual(
            plan.systems,
            [.aarch64Darwin, .x86Darwin]
        )
        XCTAssertEqual(
            plan.packages,
            [.flutter, .git, .jdk17]
        )
        XCTAssertEqual(
            plan.unmanagedRequirements,
            [.androidSDK, .xcode]
        )
    }

    func testIOSOnlyDoesNotAddJDKOrAndroidSDK() throws {
        let plan = try NixEnvironmentPlanner().plan(
            for: makeSpecification(targets: [.iOS])
        )

        XCTAssertEqual(plan.packages, [.flutter, .git])
        XCTAssertEqual(plan.unmanagedRequirements, [.xcode])
    }

    func testSamePlanProducesByteIdenticalFlake() throws {
        let plan = try NixEnvironmentPlanner().plan(
            for: makeSpecification(targets: [.iOS, .android])
        )
        let renderer = NixFlakeRenderer()

        let first = renderer.render(plan)
        let second = renderer.render(plan)

        XCTAssertEqual(first, second)
        XCTAssertTrue(
            first.contains(
                "systems = [ \"aarch64-darwin\" \"x86_64-darwin\" ];"
            )
        )
        XCTAssertTrue(first.contains("          flutter"))
        XCTAssertTrue(first.contains("          git"))
        XCTAssertTrue(first.contains("          jdk17"))
        XCTAssertFalse(first.contains("xcode"))
        XCTAssertFalse(first.contains("androidSDK"))
    }

    func testUnsupportedRendererFailsClosed() {
        let specification = ProjectSpecification(
            identity: ProjectIdentity(
                name: "Native App",
                organizationIdentifier: "de.example"
            ),
            framework: .swiftUI,
            targetPlatforms: [.iOS],
            backend: .localOnly,
            flutterStateManagement: nil
        )

        XCTAssertThrowsError(
            try NixEnvironmentPlanner().plan(for: specification)
        ) { error in
            XCTAssertEqual(
                error as? NixEnvironmentError,
                .unsupportedFramework(.swiftUI)
            )
        }
    }

    private func makeSpecification(
        targets: Set<TargetPlatform>
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: targets,
            backend: .supabase,
            flutterStateManagement: .riverpod
        )
    }
}
