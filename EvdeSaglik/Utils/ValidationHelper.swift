//
//  ValidationHelper.swift
//  EvdeSaglik
//
//  Created by gkhkaya on 17.09.2025.
//

import Foundation

/// Centralized validation helper for consistent error handling across the app
final class ValidationHelper {
    
    // MARK: - Email Validation
    
    /// Validates email format and returns appropriate error if invalid
    /// - Parameter email: Email to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateEmail(_ email: String) -> ValidationError? {
        guard !email.isEmpty else {
            return .emptyField("Email")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return .emailInvalid
        }
        
        return nil
    }
    
    // MARK: - Password Validation
    
    /// Validates password strength and returns appropriate error if invalid
    /// - Parameter password: Password to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validatePassword(_ password: String) -> ValidationError? {
        guard !password.isEmpty else {
            return .emptyField("Password")
        }
        
        guard password.count >= 6 else {
            return .passwordTooWeak
        }
        
        return nil
    }
    
    // MARK: - Name Validation
    
    /// Validates name format and returns appropriate error if invalid
    /// - Parameter name: Name to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateName(_ name: String) -> ValidationError? {
        guard !name.isEmpty else {
            return .emptyField("Name")
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 else {
            return .nameTooShort
        }
        
        return nil
    }
    
    // MARK: - Age Validation
    
    /// Validates age and returns appropriate error if invalid
    /// - Parameter age: Age to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateAge(_ age: Int) -> ValidationError? {
        guard age > 0 && age <= 150 else {
            return .ageInvalid
        }
        
        return nil
    }
    
    /// Validates password confirmation
    /// - Parameters:
    ///   - password: Original password
    ///   - confirmPassword: Password confirmation
    /// - Returns: ValidationError if invalid, nil if valid
    static func validatePasswordConfirmation(password: String, confirmPassword: String) -> ValidationError? {
        guard password == confirmPassword else {
            return .passwordMismatch
        }
        return nil
    }
    
    // MARK: - Drug/Food Name Validation
    
    /// Validates drug or food name
    /// - Parameter name: Drug or food name to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateDrugFoodName(_ name: String, type: String) -> ValidationError? {
        guard !name.isEmpty else {
            return .emptyField(type)
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 2 else {
            return .invalidFormat(type)
        }
        
        return nil
    }
    
    // MARK: - Multiple Field Validation
    
    /// Validates multiple fields at once
    /// - Parameter validations: Array of validation closures
    /// - Returns: First ValidationError found, or nil if all valid
    static func validateMultiple(_ validations: [() -> ValidationError?]) -> ValidationError? {
        for validation in validations {
            if let error = validation() {
                return error
            }
        }
        return nil
    }
    
    // MARK: - Form Validation Helpers
    
    /// Validates login form fields
    /// - Parameters:
    ///   - email: Email to validate
    ///   - password: Password to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateLoginForm(email: String, password: String) -> ValidationError? {
        return validateMultiple([
            { validateEmail(email) },
            { validatePassword(password) }
        ])
    }
    
    /// Validates registration form fields
    /// - Parameters:
    ///   - email: Email to validate
    ///   - password: Password to validate
    ///   - confirmPassword: Password confirmation to validate
    ///   - name: Name to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateRegistrationForm(email: String, password: String, confirmPassword: String, name: String) -> ValidationError? {
        return validateMultiple([
            { validateEmail(email) },
            { validatePassword(password) },
            { validatePassword(confirmPassword) },
            { validateName(name) },
            { password == confirmPassword ? nil : .invalidFormat("Password confirmation") }
        ])
    }
    
    /// Validates drug-food interaction form fields
    /// - Parameters:
    ///   - drugName: Drug name to validate
    ///   - foodName: Food name to validate
    /// - Returns: ValidationError if invalid, nil if valid
    static func validateDrugFoodForm(drugName: String, foodName: String) -> ValidationError? {
        return validateMultiple([
            { validateDrugFoodName(drugName, type: "Drug") },
            { validateDrugFoodName(foodName, type: "Food") }
        ])
    }
}
