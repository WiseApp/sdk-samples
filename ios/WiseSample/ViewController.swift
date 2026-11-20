import MobileRTC
import UIKit
import WiseSDK

final class ViewController: UIViewController {

    private let sdk = WiseSDK.shared
    private let defaults = UserDefaults.standard
    private var ready = false

    private let namespace = Field(label: "Namespace", placeholder: "e.g. yourcompany", key: "namespace")
    private let classPublicId = Field(label: "Class public ID", placeholder: "32-character ID from the class's public link", key: "classPublicId")
    private let displayName = Field(label: "Display name", placeholder: "Name shown in the class", key: nil)
    private let classId = Field(label: "Class ID", placeholder: "24-character class ID", key: "classId")
    private let ssoToken = UITextView()
    private let signInTitle = ViewController.section("Sign in (once per install)")
    private lazy var signInButton = button("Sign in", #selector(signIn))
    private lazy var signOutButton = button("Sign out", #selector(signOut))
    private let log = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wise SDK sample"
        view.backgroundColor = .systemBackground
        displayName.text = "Student"

        ssoToken.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        ssoToken.autocapitalizationType = .none
        ssoToken.autocorrectionType = .no
        ssoToken.layer.borderColor = UIColor.systemGray4.cgColor
        ssoToken.layer.borderWidth = 1
        ssoToken.layer.cornerRadius = 6
        ssoToken.heightAnchor.constraint(equalToConstant: 80).isActive = true

        log.isEditable = false
        log.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        log.backgroundColor = .secondarySystemBackground
        log.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let stack = UIStackView(arrangedSubviews: [
            Self.section("Your details (from Wise)"), namespace, button("Initialize", #selector(initialize)),
            Self.section("Join as guest"), classPublicId, displayName, button("Join by public ID", #selector(joinPublic)),
            signInTitle, Self.label("SSO token (JWT signed by your backend)"), ssoToken,
            row(signInButton, signOutButton),
            Self.section("Signed-in user"), classId,
            row(button("Join class", #selector(joinClass)), button("Start class (teacher)", #selector(startClass))),
            Self.section("Events"), log,
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scroll = UIScrollView()
        scroll.keyboardDismissMode = .interactive
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -16),
        ])

        // The SDK keeps the session across launches: no need to sign in again while it exists.
        updateSignedIn()
    }

    // MARK: - Actions

    @objc private func initialize() {
        sdk.initialise(namespace: namespace.text)
        // Screen share: App Group and extension bundle ID come from Config.xcconfig via Info.plist.
        if let group = Bundle.main.object(forInfoDictionaryKey: "WiseAppGroup") as? String,
           let extensionId = Bundle.main.object(forInfoDictionaryKey: "WiseScreenShareBundleId") as? String {
            sdk.setScreenShareDetails(appGroupId: group, bundleIdScreenshare: extensionId)
        }
        ready = true
        add("initialise: ok")
    }

    @objc private func joinPublic() {
        guard checkReady() else { return }
        sdk.joinMeeting(token: classPublicId.text, displayName: displayName.text, listener: self, viewController: self)
    }

    @objc private func signIn() {
        guard checkReady() else { return }
        let token = ssoToken.text.components(separatedBy: .whitespacesAndNewlines).joined()
        sdk.loginUsingSSOToken(token: token, listener: self)
    }

    @objc private func signOut() {
        sdk.logoutSSO()
        add("logoutSSO: ok")
        updateSignedIn()
    }

    @objc private func joinClass() {
        guard checkReady() else { return }
        sdk.joinMeeting(classId: classId.text, sessionId: "", listener: self, viewController: self)
    }

    @objc private func startClass() {
        guard checkReady() else { return }
        sdk.startMeeting(classId: classId.text, listener: self, viewController: self)
    }

    // MARK: - Helpers

    private func updateSignedIn() {
        let signedIn = sdk.isLoggedIn()
        ssoToken.isEditable = !signedIn
        ssoToken.backgroundColor = signedIn ? .secondarySystemBackground : .systemBackground
        signInButton.isEnabled = !signedIn
        signOutButton.isEnabled = signedIn
        signInTitle.text = signedIn ? "Sign in · Signed in ✓" : "Sign in (once per install)"
    }

    private func checkReady() -> Bool {
        if !ready { add("Tap Initialize first") }
        return ready
    }

    private func add(_ line: String) {
        DispatchQueue.main.async {
            let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.log.text = "\(time)  \(line)\n" + self.log.text
        }
    }

    private func button(_ title: String, _ action: Selector) -> UIButton {
        let button = UIButton(configuration: .tinted())
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func row(_ views: UIView...) -> UIStackView {
        let row = UIStackView(arrangedSubviews: views)
        row.spacing = 12
        row.distribution = .fillEqually
        return row
    }

    private static func section(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .boldSystemFont(ofSize: 15)
        return label
    }

    static func label(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }
}

// MARK: - SDK callbacks

extension ViewController: MeetingListener, SSOTokenLoginListener {
    func onSDKError(error: LensMeetingError, message: String?) { add("onSDKError \(error.code) \(error) detail=\(WiseSDK.shared.lastErrorDetail) \(message ?? "")") }
    func onMeetingStatus(status: MobileRTCMeetingState) { add("onMeetingStatus \(status.rawValue)") }
    func onMeetingEnded(reason: MobileRTCMeetingEndReason) { add("onMeetingEnded \(reason.rawValue)") }
    func onMeetingNeedPasswordOrDisplayName() { add("onMeetingNeedPasswordOrDisplayName") }
    func onMeetingNotStartedByHostError() { add("onMeetingNotStartedByHostError") }
    func onMeetingStarted() { add("onMeetingStarted") }
    func onInitialised() { add("onInitialised") }

    func onSuccess() {
        add("loginUsingSSOToken: ok")
        DispatchQueue.main.async {
            self.ssoToken.text = ""
            self.updateSignedIn()
        }
    }

    func onError(message: String?) { add("loginUsingSSOToken: \(message ?? "error")") }
}

/// Label + text field; values with a `key` are saved on the device.
private final class Field: UIStackView, UITextFieldDelegate {
    private let field = UITextField()
    private let key: String?

    var text: String {
        get { (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
        set { field.text = newValue }
    }

    init(label: String, placeholder: String, key: String?) {
        self.key = key.map { "wise-sample.\($0)" }
        super.init(frame: .zero)
        axis = .vertical
        spacing = 4
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.delegate = self
        if let k = self.key { field.text = UserDefaults.standard.string(forKey: k) }
        field.addTarget(self, action: #selector(changed), for: .editingChanged)
        addArrangedSubview(ViewController.label(label))
        addArrangedSubview(field)
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func changed() {
        if let k = key { UserDefaults.standard.set(text, forKey: k) }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
