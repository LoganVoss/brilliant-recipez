import SwiftUI
import AVFoundation
import UIKit
struct CameraPicker: UIViewControllerRepresentable {
    var onImagePicked: (Data?) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onImagePicked = onImagePicked
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
}
class CameraViewController: UIViewController {
    var onImagePicked: ((Data?) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    private var flashMode: AVCaptureDevice.FlashMode = .off

    private var previewView: UIView!
    private var shutterButton: UIButton!
    private var flashButton: UIButton!
    private var cancelButton: UIButton!
    private var shutterBorderGradient: CAGradientLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        view.clipsToBounds = false

        previewView = UIView(frame: view.bounds)
        previewView.backgroundColor = .clear
        previewView.clipsToBounds = false
        previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(previewView)

        setupCamera()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        DispatchQueue.main.async { [weak self] in
            self?.startShutterButtonAnimation()
        }

        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            print("Stopping capture session on thread: \(Thread.current)")
            self?.captureSession?.stopRunning()
        }

        shutterBorderGradient?.removeAllAnimations()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
        previewLayer?.frame = previewView.bounds
        updateOverlayFrames()

        if shutterButton.bounds != .zero {
            shutterBorderGradient?.frame = shutterButton.bounds
        }

    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupCamera() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted else {
                print("Camera access denied")
                DispatchQueue.main.async {
                    self?.onImagePicked?(nil)
                    self?.dismiss(animated: true, completion: nil)
                }
                return
            }

            DispatchQueue.main.async {
                print("Camera access granted, initializing camera")
                self?.initializeCamera()
            }
        }
    }

    private func initializeCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        captureSession = session

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Error: Unable to initialize camera")
            onImagePicked?(nil)
            dismiss(animated: true, completion: nil)
            return
        }

        if session.canAddInput(input) {
            print("Adding camera input")
            session.addInput(input)
        } else {
            print("Error: Unable to add camera input")
            onImagePicked?(nil)
            dismiss(animated: true, completion: nil)
            return
        }

        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            print("Adding photo output")
            session.addOutput(output)
            photoOutput = output
        } else {
            print("Error: Unable to add photo output")
            onImagePicked?(nil)
            dismiss(animated: true, completion: nil)
            return
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = previewView.bounds
        previewView.layer.addSublayer(layer)
        previewLayer = layer
        print("Preview layer added with frame: \(layer.frame)")

        DispatchQueue.global(qos: .userInitiated).async { [weak session] in
            print("Starting capture session on thread: \(Thread.current)")
            session?.startRunning()
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let session = session else { return }
                print("Session running: \(session.isRunning)")
                self.previewLayer?.connection?.isEnabled = true
                self.previewLayer?.frame = self.previewView.bounds
                print("Preview layer updated after session start: \(self.previewLayer?.frame ?? .zero)")
            }
        }
    }

    private func setupOverlay() {
        shutterButton = UIButton(type: .custom)
        shutterButton.backgroundColor = .white
        shutterButton.layer.cornerRadius = 40
        shutterButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        view.addSubview(shutterButton)

        let gradient = CAGradientLayer()
        gradient.frame = shutterButton.bounds
        gradient.type = .conic
        gradient.colors = [
            UIColor.red.cgColor,
            UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0).cgColor,
            UIColor.orange.cgColor,
            UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1.0).cgColor,
            UIColor.yellow.cgColor,
            UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 1.0).cgColor,
            UIColor.green.cgColor,
            UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor,
            UIColor.blue.cgColor,
            UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0).cgColor,
            UIColor.purple.cgColor,
            UIColor(red: 0.75, green: 0.0, blue: 0.5, alpha: 1.0).cgColor,
            UIColor.red.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)

        let shape = CAShapeLayer()
        let path = UIBezierPath(roundedRect: shutterButton.bounds.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 37.5)
        shape.path = path.cgPath
        shape.lineWidth = 5
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = nil

        gradient.mask = shape
        shutterButton.layer.addSublayer(gradient)
        shutterBorderGradient = gradient

        flashButton = UIButton(type: .custom)
        flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        flashButton.tintColor = .white
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        view.addSubview(flashButton)

        cancelButton = UIButton(type: .custom)
        cancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)

        updateOverlayFrames()
    }

    private func updateOverlayFrames() {
        let safeArea = view.safeAreaInsets
        let shutterButtonSize: CGFloat = 80

        shutterButton.frame = CGRect(
            x: (view.bounds.width - shutterButtonSize) / 2,
            y: view.bounds.height - shutterButtonSize - safeArea.bottom - 20,
            width: shutterButtonSize,
            height: shutterButtonSize
        )

        flashButton.frame = CGRect(
            x: 20,
            y: safeArea.top + 30,
            width: 40,
            height: 40
        )

        cancelButton.frame = CGRect(
            x: view.bounds.width - 60,
            y: safeArea.top + 30,
            width: 40,
            height: 40
        )

        if shutterButton.bounds != .zero {
            shutterBorderGradient?.frame = shutterButton.bounds
            if let shape = shutterBorderGradient?.mask as? CAShapeLayer {
                shape.path = UIBezierPath(roundedRect: shutterButton.bounds.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 37.5).cgPath
            }
        }
    }

    private func startShutterButtonAnimation() {
        guard let gradient = shutterBorderGradient else { return }

        if gradient.frame == .zero {
            print("Gradient frame is zero, skipping animation start")
            return
        }

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = 2 * Double.pi
        rotationAnimation.duration = 5.0
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        gradient.add(rotationAnimation, forKey: "rotationAnimation")

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.7
        opacityAnimation.toValue = 1.0
        opacityAnimation.duration = 2.0
        opacityAnimation.repeatCount = .infinity
        opacityAnimation.autoreverses = true
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradient.add(opacityAnimation, forKey: "opacityAnimation")
    }

    @objc private func takePhoto() {
        print("Shutter button tapped, frame: \(shutterButton.frame)")
        guard let photoOutput = photoOutput else {
            print("Error: Photo output not available")
            return
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func toggleFlash() {
        print("Flash button tapped, frame: \(flashButton.frame)")
        flashMode = (flashMode == .off) ? .on : .off
        let imageName = flashMode == .on ? "bolt.fill" : "bolt.slash.fill"
        flashButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @objc private func cancel() {
        print("Cancel button tapped, frame: \(cancelButton.frame)")
        onImagePicked?(nil)
        dismiss(animated: true, completion: nil)
    }
}
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            onImagePicked?(nil)
            dismiss(animated: true, completion: nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData),
              let compressedData = image.jpegData(compressionQuality: 0.8) else {
            print("Error processing photo data")
            onImagePicked?(nil)
            dismiss(animated: true, completion: nil)
            return
        }

        onImagePicked?(compressedData)
        dismiss(animated: true, completion: nil)
    }
}
