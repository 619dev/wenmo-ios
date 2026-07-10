import UIKit

final class GuideViewController: UIViewController {
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "问墨输入法"
        view.backgroundColor = .systemGroupedBackground

        let icon = UILabel()
        icon.text = "墨"
        icon.font = .systemFont(ofSize: 44, weight: .bold)
        icon.textAlignment = .center
        icon.textColor = .white
        icon.backgroundColor = .label
        icon.layer.cornerRadius = 18
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false

        let headline = UILabel()
        headline.text = "离线、克制、专注输入"
        headline.font = .preferredFont(forTextStyle: .title2)
        headline.textAlignment = .center

        let privacy = UILabel()
        privacy.text = "不申请网络权限 · 不申请录音权限\n词库随应用提供，输入内容只在本机处理"
        privacy.font = .preferredFont(forTextStyle: .body)
        privacy.textColor = .secondaryLabel
        privacy.textAlignment = .center
        privacy.numberOfLines = 0

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        let settingsButton = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "打开键盘设置"
        configuration.cornerStyle = .large
        settingsButton.configuration = configuration
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let instructions = UILabel()
        instructions.text = "在“键盘”中选择“添加新键盘…”，添加“问墨”。无需开启“允许完全访问”。"
        instructions.font = .preferredFont(forTextStyle: .callout)
        instructions.textColor = .secondaryLabel
        instructions.textAlignment = .center
        instructions.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, headline, privacy, settingsButton, instructions, statusLabel])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 88),
            icon.heightAnchor.constraint(equalToConstant: 88),
            icon.centerXAnchor.constraint(equalTo: stack.centerXAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -18),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusLabel.text = "设置完成后，点输入框左下角的地球键即可切换到问墨。"
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
