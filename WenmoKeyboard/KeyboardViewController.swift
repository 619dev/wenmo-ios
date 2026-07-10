import UIKit

final class KeyboardViewController: UIInputViewController {
    private enum Page { case letters, numbers, symbols }
    private let engine = LocalInputEngine()
    private let rootStack = UIStackView()
    private let candidateScroll = UIScrollView()
    private let candidateStack = UIStackView()
    private let compositionLabel = UILabel()
    private var page: Page = .letters
    private var heightConstraint: NSLayoutConstraint?

    private var keyboardBackground: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(white: 0.82, alpha: 1) }
    }
    private var keyBackground: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.28, alpha: 1) : .white }
    }
    private var specialKeyBackground: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.19, alpha: 1) : UIColor(white: 0.68, alpha: 1) }
    }
    private var foregroundColor: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? .white : .black }
    }
    private var secondaryForegroundColor: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.72, alpha: 1) : UIColor(white: 0.38, alpha: 1) }
    }

    private let letterRows = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"]
    ]
    private let numberRows = [["1","2","3","4","5","6","7","8","9","0"], ["-","/",":",";","(",")","¥","@","\""], [".",",","?","!","'"]]
    private let symbolRows = [["[","]","{","}","#","%","^","*","+","="], ["_","\\","|","~","<",">","€","£","•"], [".",",","?","!","'"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = keyboardBackground
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 292)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true

        rootStack.axis = .vertical
        rootStack.spacing = 6
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            rootStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rootStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -6)
        ])
        rebuildKeyboard()
    }

    override func textWillChange(_ textInput: UITextInput?) { super.textWillChange(textInput) }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        view.backgroundColor = keyboardBackground
        rebuildKeyboard()
    }

    private func rebuildKeyboard() {
        rootStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addCandidateBar()
        let rows = page == .letters ? letterRows : (page == .numbers ? numberRows : symbolRows)
        for (index, keys) in rows.enumerated() {
            rootStack.addArrangedSubview(makeRow(keys, inset: index == 1 ? 18 : (index == 2 ? 42 : 0)))
        }
        rootStack.addArrangedSubview(makeBottomRow())
        refreshCandidates()
    }

    private func addCandidateBar() {
        candidateScroll.backgroundColor = keyBackground
        candidateScroll.layer.cornerRadius = 6
        candidateScroll.showsHorizontalScrollIndicator = false
        candidateStack.axis = .horizontal
        candidateStack.alignment = .fill
        candidateStack.translatesAutoresizingMaskIntoConstraints = false
        candidateScroll.addSubview(candidateStack)
        NSLayoutConstraint.activate([
            candidateStack.leadingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.leadingAnchor, constant: 8),
            candidateStack.trailingAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.trailingAnchor, constant: -8),
            candidateStack.topAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.topAnchor),
            candidateStack.bottomAnchor.constraint(equalTo: candidateScroll.contentLayoutGuide.bottomAnchor),
            candidateStack.heightAnchor.constraint(equalTo: candidateScroll.frameLayoutGuide.heightAnchor)
        ])
        candidateScroll.heightAnchor.constraint(equalToConstant: 42).isActive = true
        rootStack.addArrangedSubview(candidateScroll)
    }

    private func makeRow(_ titles: [String], inset: CGFloat) -> UIView {
        let container = UIView()
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 5
        row.distribution = .fillEqually
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        titles.forEach { title in
            let button = keyButton(title)
            button.addAction(UIAction { [weak self] _ in self?.tapCharacter(title) }, for: .touchUpInside)
            row.addArrangedSubview(button)
        }
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 48),
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: inset),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset)
        ])
        return container
    }

    private func makeBottomRow() -> UIView {
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 5
        row.heightAnchor.constraint(equalToConstant: 46).isActive = true
        let mode = keyButton(page == .letters ? "123" : "ABC", dark: true)
        mode.addAction(UIAction { [weak self] _ in self?.setPage(self?.page == .letters ? .numbers : .letters) }, for: .touchUpInside)
        let alternate = keyButton(page == .numbers ? "#+=" : (page == .symbols ? "123" : engine.script == .simplified ? "简" : "繁"), dark: true)
        alternate.addAction(UIAction { [weak self] _ in self?.tapAlternate() }, for: .touchUpInside)
        let globe = keyButton("🌐", dark: true)
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        let space = keyButton("空格")
        space.addAction(UIAction { [weak self] _ in self?.commitSpace() }, for: .touchUpInside)
        let delete = keyButton("⌫", dark: true)
        delete.addAction(UIAction { [weak self] _ in self?.backspace() }, for: .touchUpInside)
        let dismiss = keyButton("⌄", dark: true)
        dismiss.addAction(UIAction { [weak self] _ in self?.dismissKeyboard() }, for: .touchUpInside)
        let enter = keyButton("换行", dark: true)
        enter.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText("\n") }, for: .touchUpInside)
        [mode, alternate, globe, space, delete, dismiss, enter].forEach { row.addArrangedSubview($0) }
        space.widthAnchor.constraint(equalTo: mode.widthAnchor, multiplier: 2.4).isActive = true
        return row
    }

    private func keyButton(_ title: String, dark: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(foregroundColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: title.count == 1 ? 21 : 15)
        button.backgroundColor = dark ? specialKeyBackground : keyBackground
        button.layer.cornerRadius = 6
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.14
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        return button
    }

    private func tapCharacter(_ value: String) {
        if page == .letters { engine.type(value) } else { textDocumentProxy.insertText(value) }
        refreshCandidates()
    }

    private func refreshCandidates() {
        candidateStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        compositionLabel.text = engine.composition.isEmpty ? "问墨 · 离线" : engine.composition
        compositionLabel.font = .systemFont(ofSize: 16, weight: engine.composition.isEmpty ? .regular : .semibold)
        compositionLabel.textColor = engine.composition.isEmpty ? secondaryForegroundColor : foregroundColor
        compositionLabel.setContentHuggingPriority(.required, for: .horizontal)
        candidateStack.addArrangedSubview(compositionLabel)
        for candidate in engine.candidates.prefix(24) {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.plain()
            configuration.title = candidate
            configuration.baseForegroundColor = foregroundColor
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
                var attributes = attributes
                attributes.font = .systemFont(ofSize: 20)
                return attributes
            }
            button.configuration = configuration
            button.addAction(UIAction { [weak self] _ in self?.commit(candidate) }, for: .touchUpInside)
            candidateStack.addArrangedSubview(button)
        }
    }

    private func commit(_ text: String) { textDocumentProxy.insertText(text); engine.clear(); refreshCandidates() }
    private func commitSpace() {
        if let first = engine.candidates.first { commit(first) } else {
            if !engine.composition.isEmpty { textDocumentProxy.insertText(engine.composition); engine.clear() }
            textDocumentProxy.insertText(" "); refreshCandidates()
        }
    }
    private func backspace() {
        if engine.composition.isEmpty { textDocumentProxy.deleteBackward() } else { engine.backspace(); refreshCandidates() }
    }
    private func setPage(_ newPage: Page?) { guard let newPage else { return }; page = newPage; rebuildKeyboard() }
    private func tapAlternate() {
        if page == .numbers { setPage(.symbols) }
        else if page == .symbols { setPage(.numbers) }
        else { engine.script = engine.script == .simplified ? .traditional : .simplified; rebuildKeyboard() }
    }
}
