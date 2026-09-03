import AppForgeDesignSystem
import AppKit
import SwiftUI

struct WorkspaceHomeView: View {
    @Bindable var viewModel: WorkspaceHomeViewModel
    @State private var selectedSection: WorkspaceSection? = .projects

    var body: some View {
        NavigationSplitView {
            List(WorkspaceSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("AppForge Pro")
            .frame(minWidth: 210)
        } detail: {
            if selectedSection == .environment {
                EnvironmentDoctorView(viewModel: viewModel.environmentDoctorViewModel)
            } else {
                dashboard
            }
        }
        .sheet(isPresented: $viewModel.isPresentingProjectSetup) {
            if let projectSetupViewModel = viewModel.projectSetupViewModel {
                ProjectSetupView(
                    viewModel: projectSetupViewModel,
                    onClose: viewModel.dismissProjectSetup
                )
            }
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppForgeSpacing.large) {
                hero
                valueOverview
                architectureNote
            }
            .padding(AppForgeSpacing.extraLarge)
            .frame(maxWidth: 1080, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var hero: some View {
        AppForgeCard {
            HStack(alignment: .center, spacing: AppForgeSpacing.extraLarge) {
                VStack(alignment: .leading, spacing: AppForgeSpacing.medium) {
                    Text("Von Ihrer Geschäftsidee zur eigenen App")
                        .font(.system(size: 32, weight: .bold, design: .rounded))

                    Text(
                        "Wählen Sie Prozesse, Rollen, Daten, Plattformen und Design. "
                            + "AppForge Pro übersetzt diese Entscheidungen in getesteten Source Code."
                    )
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    Button(action: viewModel.startProjectSetup) {
                        Label("Neues Business-Projekt", systemImage: "wand.and.stars")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.appForgeAccent)
                    .controlSize(.large)
                    .accessibilityHint("Öffnet die geführte Projektkonfiguration")
                }

                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 104))
                    .foregroundStyle(Color.appForgeAccent.gradient)
                    .accessibilityHidden(true)
            }
        }
    }

    private var valueOverview: some View {
        HStack(alignment: .top, spacing: AppForgeSpacing.medium) {
            valueCard(
                icon: "person.3.sequence.fill",
                title: "Rollen vorab testen",
                detail: "Demo-Zugänge zeigen, was Owner, Manager und Mitarbeiter wirklich dürfen."
            )
            valueCard(
                icon: "externaldrive.badge.icloud",
                title: "Offline produktiv",
                detail: "Lokale SSOT und Sync-Outbox halten die App auch ohne Internet arbeitsfähig."
            )
            valueCard(
                icon: "shippingbox.and.arrow.backward.fill",
                title: "Source Code besitzen",
                detail: "Keine proprietäre Runtime: Das erzeugte Projekt bleibt vollständig editierbar."
            )
        }
    }

    private var architectureNote: some View {
        AppForgeCard {
            Label {
                VStack(alignment: .leading, spacing: AppForgeSpacing.small) {
                    Text("Professionelle Architektur ist bereits eingebaut")
                        .font(.headline)
                    Text(
                        "MVVM, Feature-First, Repository Pattern, Use Cases, Clean Code, KISS, DRY, "
                            + "SOLID und Single Source of Truth sind Standards – keine verwirrenden Optionen."
                    )
                    .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(Color.appForgeAccent)
            }
        }
    }

    private func valueCard(icon: String, title: String, detail: String) -> some View {
        AppForgeCard {
            VStack(alignment: .leading, spacing: AppForgeSpacing.small) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(Color.appForgeAccent)
                Text(title)
                    .font(.headline)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private enum WorkspaceSection: String, CaseIterable, Identifiable {
    case projects
    case templates
    case packages
    case environment
    case quality
    case releases

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .projects: "Projekte"
        case .templates: "Business-Vorlagen"
        case .packages: "Packages"
        case .environment: "Entwicklungsumgebung"
        case .quality: "Qualität"
        case .releases: "Releases"
        }
    }

    var icon: String {
        switch self {
        case .projects: "square.grid.2x2"
        case .templates: "rectangle.3.group"
        case .packages: "shippingbox"
        case .environment: "wrench.and.screwdriver"
        case .quality: "checkmark.seal"
        case .releases: "arrow.up.forward.app"
        }
    }
}
