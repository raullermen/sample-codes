//
//  StoreManager.swift
//  Quiz
//
//  Created by Raul Lermen on 30/11/20.
//  Copyright © 2020 Raul Lermen. All rights reserved.
//

import Foundation
import StoreKit

protocol StoreManagerProtocol {
    func didBuyProduct(product: ProductOptions)
}

@MainActor
class StoreManager: NSObject, ObservableObject {
    
    private let keychainManager: KeychainManager
    
    private var request: SKProductsRequest!
    private let productOptions: [ProductOptions] = ProductOptions.allCases
    private var products: [SKProduct] = []
    
    var delegate: StoreManagerProtocol?
    
    var loadingTransactions = false {
        didSet { updateObservables() }
    }
    
    var buyingProduct = false {
        didSet { updateObservables() }
    }
    
    //
    //MARK: Life Cycle
    
    init(keychainManager: KeychainManager = KeychainManager()) {
        self.keychainManager = keychainManager
        super.init()
        SKPaymentQueue.default().add(self)
        loadProducts()
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    //
    //MARK: Methods
    
    func updateObservables() {
        objectWillChange.send()
    }
    
    //
    //MARK: Public
    
    func restorePurchases() {
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().restoreCompletedTransactions()
            
            loadingTransactions = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.loadingTransactions = false
            }
        }
    }
    
    func buyProduct(productOption: ProductOptions) {
        if keychainManager.purchesedUnlockAll { return }
        if !buyingProduct, let product = products.filter({ $0.productIdentifier == productOption.rawValue }).first {
            let pay = SKPayment(product: product)
            SKPaymentQueue.default().add(pay as SKPayment)
            
            buyingProduct = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.buyingProduct = false
            }
        }
    }
    
    func productIsPurcheased(_ product: ProductOptions) -> Bool {
        
        let everythingBought = keychainManager.purchesedAdvancedSearch &&
        keychainManager.purchesedSaveQuestions &&
        keychainManager.purchesedCreateTests
        
        if everythingBought || keychainManager.purchesedUnlockAll { return true }
        
        switch product {
        case .advancedSearch:
            return keychainManager.purchesedAdvancedSearch
        case .saveQuestions:
            return keychainManager.purchesedSaveQuestions
        case .createTests:
            return keychainManager.purchesedCreateTests
        default:
            return false
        }
    }
    
    func productPrice(_ product: ProductOptions) -> String {
        if let item = products.filter({ $0.productIdentifier == product.rawValue }).first {
            return item.priceString ?? "Indisponível"
        }
        return "Indisponível"
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        for transaction in queue.transactions {
            let productId = transaction.payment.productIdentifier as String
            if let product = ProductOptions(rawValue: productId) {
                activeProduct(product)
            }
        }
    }
    
    // MARK: Private
    
    private func activeProduct(_ product: ProductOptions) {
        switch product {
        case .advancedSearch:
            keychainManager.purchesedAdvancedSearch = true
        case .saveQuestions:
            keychainManager.purchesedSaveQuestions = true
        case .createTests:
            keychainManager.purchesedCreateTests = true
        case .unlockAll:
            keychainManager.purchesedUnlockAll = true
        }
        delegate?.didBuyProduct(product: product)
        updateObservables()
    }
}

//MARK: SKPaymentTransactionObserver
extension StoreManager: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                if let product = ProductOptions(rawValue: transaction.payment.productIdentifier) {
                    activeProduct(product)
                    queue.finishTransaction(transaction)
                }
                break
            case .failed:
                print("failed")
            case .deferred, .purchasing:
                break
            @unknown default:
                break;
            }
        }
    }
}

//MARK: SKProductsRequestDelegate
extension StoreManager: SKProductsRequestDelegate {
    
    func loadProducts() {
        if SKPaymentQueue.canMakePayments() {
            let products = Set(productOptions.map{ $0.rawValue })
            let request: SKProductsRequest = SKProductsRequest(productIdentifiers: products)
            request.delegate = self
            request.start()
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        updateObservables()
    }
}

extension SKProduct {
    
    var priceString: String? {
        let price = self.price
        if price == NSDecimalNumber(decimal: 0.00) {
            return "Grátis"
        } else {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = priceLocale
            return numberFormatter.string(from: price)
        }
    }
}
