import AppForgeApplication

@MainActor
struct AppEnvironment {
    let makeProjectSetupViewModel: () -> ProjectSetupViewModel
    let makeEnvironmentDoctorViewModel: () -> EnvironmentDoctorViewModel

    static let live: AppEnvironment = {
        let preferences = UserDefaultsToolchainPreferenceStore()
        let projectOpener = SystemGeneratedProjectOpener()

        return AppEnvironment(
            makeProjectSetupViewModel: {
                ProjectSetupViewModel(
                    createProjectDraft: CreateProjectDraftUseCase(),
                    preferencesStore: preferences,
                    projectBuilder: BuildFlutterProjectUseCase(),
                    projectOpener: projectOpener
                )
            },
            makeEnvironmentDoctorViewModel: {
                EnvironmentDoctorViewModel(
                    doctor: EnvironmentDoctorUseCase(
                        detector: SystemToolDetector()
                    ),
                    preferencesStore: preferences,
                    projectOpener: projectOpener,
                    flutterInstaller: VerifiedFlutterSDKInstaller()
                )
            }
        )
    }()

    static let test: AppEnvironment = {
        let preferences = UserDefaultsToolchainPreferenceStore(
            key: "appforge.toolchain.preferences.tests"
        )
        let projectOpener = SystemGeneratedProjectOpener()

        return AppEnvironment(
            makeProjectSetupViewModel: {
                ProjectSetupViewModel(
                    createProjectDraft: CreateProjectDraftUseCase(),
                    preferencesStore: preferences,
                    projectBuilder: BuildFlutterProjectUseCase(),
                    projectOpener: projectOpener
                )
            },
            makeEnvironmentDoctorViewModel: {
                EnvironmentDoctorViewModel(
                    doctor: EnvironmentDoctorUseCase(
                        detector: SystemToolDetector()
                    ),
                    preferencesStore: preferences,
                    projectOpener: projectOpener,
                    flutterInstaller: VerifiedFlutterSDKInstaller()
                )
            }
        )
    }()
}
