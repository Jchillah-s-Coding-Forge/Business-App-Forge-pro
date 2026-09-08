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
            result.append(
                try FlutterGeneratedFormScreenSource(
                    specification: specification,
                    screen: screen,
                    entity: entity
                ).file()
            )
        }
        return result
    }
}
