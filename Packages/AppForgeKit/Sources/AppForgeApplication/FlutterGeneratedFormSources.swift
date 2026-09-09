import AppForgeDomain

struct FlutterGeneratedFormSources {
    let specification: ProjectSpecification

    func files() throws -> [GeneratedFile] {
        let screens = FlutterFormRenderingSupport.formScreens(
            in: specification
        )
        guard !screens.isEmpty else {
            return []
        }

        var result = [
            FlutterGeneratedRecordIDSource().file(),
            FlutterGeneratedFormContractSource().file(),
            FlutterGeneratedFormTextFieldsSource().file(),
            FlutterGeneratedFormChoiceFieldsSource().file(),
            FlutterGeneratedFormPickerFieldsSource().file(),
            FlutterGeneratedFormFieldSource().file(),
            FlutterGeneratedEntityFormScreenSource().file()
        ]
        for screen in screens {
            let entity = try FlutterFormRenderingSupport.entity(
                for: screen,
                in: specification
            )
            try result.append(
                FlutterGeneratedFormScreenSource(
                    specification: specification,
                    screen: screen,
                    entity: entity
                ).file()
            )
            try result.append(
                FlutterGeneratedFormViewModelSource(
                    specification: specification,
                    screen: screen,
                    entity: entity
                ).file()
            )
        }
        return result
    }
}
