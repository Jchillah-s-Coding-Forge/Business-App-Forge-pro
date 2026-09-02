import AppForgeApplication

@MainActor
struct AppEnvironment {
    let makeProjectSetupViewModel: () -> ProjectSetupViewModel
    let makeEnvironmentDoctorViewModel: () -> EnvironmentDoctorViewModel

    static let live = AppEnvironment(
        makeProjectSetupViewModel: {
            ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        },
        makeEnvironmentDoctorViewModel: {
            EnvironmentDoctorViewModel(
                doctor: EnvironmentDoctorUseCase(detector: SystemToolDetector()),
                preferencesStore: UserDefaultsToolchainPreferenceStore(),
                projectOpener: SystemGeneratedProjectOpener(),
                flutterInstaller: VerifiedFlutterSDKInstaller()
            )
        }
    )

    static let test = AppEnvironment(
        makeProjectSetupViewModel: {
            ProjectSetupViewModel(createProjectDraft: CreateProjectDraftUseCase())
        },
        makeEnvironmentDoctorViewModel: {
            EnvironmentDoctorViewModel(
                doctor: EnvironmentDoctorUseCase(detector: SystemToolDetector()),
                preferencesStore: UserDefaultsToolchainPreferenceStore(key: "appforge.toolchain.preferences.tests"),
                projectOpener: SystemGeneratedProjectOpener(),
                flutterInstaller: VerifiedFlutterSDKInstaller()
            )
        }
    )
}
