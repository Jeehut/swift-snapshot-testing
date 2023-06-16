#if canImport(SwiftUI)
import Foundation
import SwiftUI
import XCTest

/// The size constraint for a snapshot (similar to `PreviewLayout`).
public enum SwiftUISnapshotLayout {
  #if os(iOS) || os(tvOS)
  /// Center the view in a device container described by`config`.
  case device(config: ViewImageConfig)
  #endif
  /// Center the view in a fixed size container.
  case fixed(width: CGFloat, height: CGFloat)
  /// Fit the view to the ideal size that fits its content.
  case sizeThatFits

  #if os(iOS) || os(tvOS)
  @available(iOS 13.0, tvOS 13.0, *)
  public static func previewDevice(_ previewDevice: PreviewDevice, orientation: ViewImageConfig.Orientation = .portrait) -> Self {
    switch previewDevice.rawValue {
    case "iPhone 8":
      return .device(config: .iPhone8(orientation))
    case "iPhone 8 Plus":
      return .device(config: .iPhone8Plus(orientation))
    case "iPhone X":
      return .device(config: .iPhoneX(orientation))
    case "iPhone Xs":
      return .device(config: .iPhoneX(orientation))
    case "iPhone Xs Max", "iPhone 11 Pro Max":
      return .device(config: .iPhoneXsMax(orientation))
    case "iPhone Xʀ", "iPhone 11", "iPhone 11 Pro":
      return .device(config: .iPhoneXr(orientation))
    case "iPhone SE (2nd generation)", "iPhone SE (3rd generation)":
      return .device(config: .iPhoneSe(orientation))
    case "iPhone 12 mini", "iPhone 13 mini":
      return .device(config: .iPhone13Mini(orientation))
    case "iPhone 12":
      return .device(config: .iPhone12(orientation))
    case "iPhone 12 Pro":
      return .device(config: .iPhone12Pro(orientation))
    case "iPhone 12 Pro Max":
      return .device(config: .iPhone12ProMax(orientation))
    case "iPhone 13 Pro":
      return .device(config: .iPhone13Pro(orientation))
    case "iPhone 13 Pro Max", "iPhone 14 Plus", "iPhone 14 Pro Max":
      return .device(config: .iPhone13ProMax(orientation))
    case "iPhone 13", "iPhone 14", "iPhone 14 Pro":
      return .device(config: .iPhone13(orientation))
    case "Apple TV":
      return .fixed(width: 1920, height: 1080)
    default:
      if previewDevice.rawValue.contains("Apple TV 4K") {
        return .fixed(width: 3840, height: 2160)
      } else if previewDevice.rawValue.contains("iPad") {
        if previewDevice.rawValue.contains("(11-inch)") {
          return .device(config: .iPadPro11(orientation))
        } else if previewDevice.rawValue.contains("(12.9-inch)") {
          return .device(config: .iPadPro12_9(orientation))
        } else if previewDevice.rawValue.contains("iPad mini") {
          return .device(config: .iPadMini(orientation))
        } else {
          return .device(config: .iPad9_7(orientation))
        }
      }

      XCTFail("Unsupported device: \(previewDevice.rawValue)")
      return .sizeThatFits
    }
  }
  #endif
}

#if os(iOS) || os(tvOS)
@available(iOS 13.0, tvOS 13.0, *)
extension Snapshotting where Value: SwiftUI.View, Format == UIImage {

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  public static var image: Snapshotting {
    return .image()
  }

  /// A snapshot strategy for comparing SwiftUI Views based on pixel equality.
  ///
  /// - Parameters:
  ///   - drawHierarchyInKeyWindow: Utilize the simulator's key window in order to render `UIAppearance` and `UIVisualEffect`s. This option requires a host application for your tests and will _not_ work for framework test targets.
  ///   - precision: The percentage of pixels that must match.
  ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
  ///   - layout: A view layout override.
  ///   - traits: A trait collection override.
  public static func image(
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    perceptualPrecision: Float = 1,
    layout: SwiftUISnapshotLayout = .sizeThatFits,
    traits: UITraitCollection = .init()
    )
    -> Snapshotting {
      let config: ViewImageConfig

      switch layout {
      #if os(iOS) || os(tvOS)
      case let .device(config: deviceConfig):
        config = deviceConfig
      #endif
      case .sizeThatFits:
        config = .init(safeArea: .zero, size: nil, traits: traits)
      case let .fixed(width: width, height: height):
        let size = CGSize(width: width, height: height)
        config = .init(safeArea: .zero, size: size, traits: traits)
      }

      return SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision, scale: traits.displayScale).asyncPullback { view in
        var config = config

        let controller: UIViewController

        if config.size != nil {
          controller = UIHostingController.init(
            rootView: view
          )
        } else {
          let hostingController = UIHostingController.init(rootView: view)

          let maxSize = CGSize(width: 0.0, height: 0.0)
          config.size = hostingController.sizeThatFits(in: maxSize)

          controller = hostingController
        }

        return snapshotView(
          config: config,
          drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
          traits: traits,
          view: controller.view,
          viewController: controller
        )
      }
  }
}
#endif
#endif
