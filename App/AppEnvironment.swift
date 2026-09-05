import AppForgeApplication

@MainActor
struct AppEnvironment {
    let makeProjectSetupViewModel: () -> ProjectSetupViewModel
    let makeEnvironmentDoctorViewModel: () -> EnvironmentDoctorViewModel

    static let live = AppEnvironment(
        makeProjectSetupViewModel: {
            ProjectSetupViewModel(
                createProjectDraft: CreateProjectDraftUseCase(),
                preferencesStore: UserDefaultsToolchainPreferenceStore(),
                projectBuilder: BuildFlutterProjectUseCase(),
                projectOpener: SystemGeneratedProjectOpener()
            )
        },
        makeEnvironmentDoctorViewModel: {
            EnvironmentDoctorViewModel(
                doctor: EnvironmentDoctorUseCase(
                    detector: SystemToolDetector()
                ),
                preferencesStore: UserDefaultsToolchainPreferenceStore(),
                projectOpener: SystemGeneratedProjectOpener(),
                flutterInstaller: VerifiedFlutterSDKInstaller()
            )
        }
    )

    static let testPreferenceKey =
        "appforge.toolchain.preferences.tests"

    static let test = AppEnvironment(
        makeProjectSetupViewModel: {
            ProjectSetupViewModel(
                createProjectDraft: CreateProjectDraftUseCase(),
                preferencesStore: UserDefaultsToolchainPreferenceStore(
                    key: testPreferenceKey
                ),
                projectBuilder: BuildFlutterProjectUseCase(),
                projectOpener: SystemGeneratedProjectOpener()
            )
        },
        makeEnvironmentDoctorViewModel: {
            EnvironmentDoctorViewModel(
                doctor: EnvironmentDoctorUseCase(
                    detector: SystemToolDetector()
                ),
                preferencesStore: UserDefaultsToolchainPreferenceStore(
                    key: testPreferenceKey
                ),
                projectOpener: SystemGeneratedProjectOpener(),
                flutterInstaller: VerifiedFlutterSDKInstaller()
            )
        }
    )
}
