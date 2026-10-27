import OSLog
import StoreKit
import SwiftUI

private let log = Logger(subsystem: "de.rummeyer.fiestaboard", category: "tips")

/// Tips, through In-App Purchase as the App Store has them: two coffees,
/// each a consumable that unlocks nothing — a thank-you, no more. The
/// products are set up in App Store Connect, and for Xcode in
/// FiestaBoard.storekit.
@MainActor @Observable
final class TipJar {
    static let productIDs = [
        "de.rummeyer.fiestaboard.tip.small",
        "de.rummeyer.fiestaboard.tip.medium",
    ]

    /// Cheapest first; none until the App Store has answered, or where it offers none.
    private(set) var products: [Product] = []
    /// The tip being bought, while Apple's sheet is up.
    private(set) var buying: Product.ID?
    /// After a tip went through, for the thank-you.
    var thanked = false
    var problem: String?

    private var updates: Task<Void, Never>?

    init() {
        // A tip bought elsewhere or left unfinished — an interrupted purchase, one
        // waiting for a parent's approval — is finished whenever it arrives.
        updates = Task {
            for await result in Transaction.updates {
                if case let .verified(transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }

    func load() async {
        guard products.isEmpty else {
            return
        }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            log.info("Tips: \(self.products.count) of \(Self.productIDs.count) from the App Store")
        } catch {
            log.error("Tips: none, \(error.localizedDescription)")
            products = []
        }
    }

    func buy(_ product: Product) async {
        buying = product.id
        problem = nil
        defer { buying = nil }
        do {
            switch try await product.purchase() {
            case let .success(.verified(transaction)):
                await transaction.finish()
                thanked = true
            case .success(.unverified):
                problem = String(localized: "The App Store could not confirm the purchase.")
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            problem = error.localizedDescription
        }
    }
}

/// The coffees in Settings, each with its price; nothing where the App Store offers none.
/// The section they are in loads them and says thank you: see `tipping()`.
struct TipRows: View {
    @Environment(TipJar.self) private var jar

    var body: some View {
        ForEach(jar.products) { product in
            Button {
                Task { await jar.buy(product) }
            } label: {
                HStack {
                    Label {
                        Text(product.displayName)
                    } icon: {
                        LucideIcon("coffee", size: 18, relativeTo: .body)
                    }
                    .foregroundStyle(Style.ink)
                    Spacer()
                    if jar.buying == product.id {
                        ProgressView()
                    } else {
                        Text(product.displayPrice)
                            .monospacedDigit()
                            .foregroundStyle(Style.primaryInk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Style.primary, in: Capsule())
                    }
                }
            }
            .disabled(jar.buying != nil)
        }
        if let problem = jar.problem {
            Label(problem, lucide: "triangle-alert")
                .foregroundStyle(.red)
        }
    }
}

extension View {
    /// Loads the tips as this appears, and thanks for one bought.
    func tipping(_ jar: TipJar) -> some View {
        @Bindable var jar = jar
        return self
            .task { await jar.load() }
            .alert("Thank you!", isPresented: $jar.thanked) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your coffee keeps the app going.")
            }
    }
}
