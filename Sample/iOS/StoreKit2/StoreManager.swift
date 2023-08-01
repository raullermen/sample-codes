//
//  StoreManager2.swift
//  FacilBula
//
//  Created by Raul Lermen on 09/07/23.
//

import Foundation
import StoreKit

protocol StoreManagerProtocol {
    func didActivateSubscription()
    func didGetErrorRestoringSubscription()
}

@MainActor
class StoreManager: ObservableObject {
    
    @Published var subscriptions: [Product] = []
    
    private let keychainManager: KeychainManager
    private var updates: Task<Void, Error>?
    
    var delegate: StoreManagerProtocol?
    
    init(keychainManager: KeychainManager = KeychainManager()) {
        self.keychainManager = keychainManager
        self.updates = listenForTransactionUpdates()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        self.updates?.cancel()
    }
    
    var appOpenedBefore: Bool {
        get { keychainManager.appOpenedBefore }
        set { keychainManager.appOpenedBefore = newValue }
    }
    
    var hasUnlockedPremium: Bool {
        keychainManager.premiumSubscriptionEnabled
    }
}

extension StoreManager {
    
    func loadProducts() async {
        let productIds: [String] = ProductOption.allCases.map { $0.rawValue }
        guard let products = try? await Product.products(for: productIds) else { return }
        subscriptions = products
    }
    
    func purchase(_ product: Product) async {
        let result = try? await product.purchase()
        
        switch result {
        case let .success(.verified(transaction)):
            activatePremium()
            await transaction.finish()
        case let .success(.unverified(_, error)):
            print(error)
            break
        case .pending, .userCancelled, .none:
            break
        @unknown default:
            break
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print(error)
        }
    }
    
    // MARK: - Private
        
    @MainActor
    private func updatePurchasedProducts() async {
        guard let statuses = try? await subscriptions.first?.subscription?.status else { return }
        guard let _ = statuses
            .first(where: { [.subscribed, .inBillingRetryPeriod, .inGracePeriod].contains($0.state) }) else {
            disablePremium()
            return
        }
        activatePremium()
    }
    
    private func activatePremium() {
        keychainManager.premiumSubscriptionEnabled = true
        delegate?.didActivateSubscription()
        objectWillChange.send()
    }
    
    private func disablePremium() {
        keychainManager.premiumSubscriptionEnabled = false
        delegate?.didGetErrorRestoringSubscription()
        objectWillChange.send()
    }
    
    private func listenForTransactionUpdates() -> Task<Void, Error> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                guard case .verified(let transaction) = verificationResult else { return }
                activatePremium()
                await transaction.finish()
            }
        }
    }
}
