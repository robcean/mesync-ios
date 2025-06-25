//
//  AppTheme.swift
//  meSync
//
//  Design System - Colores, Espaciado y Constantes
//

import SwiftUI

// MARK: - App Colors
struct AppColors {
    // Colores principales
    static let primary = Color.accentColor
    static let secondary = Color.secondary
    
    // Fondos
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let cardBackground = Color(.systemGray6)
    
    // Textos
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let tertiaryText = Color(.tertiaryLabel)
    
    // Estados
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // Materiales
    static let headerMaterial = Material.regularMaterial
    static let cardMaterial = Material.thinMaterial
}

// MARK: - App Spacing
struct AppSpacing {
    // Espaciado base
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    
    // Espaciado específico
    static let cardPadding: CGFloat = lg
    static let sectionSpacing: CGFloat = xxl
    static let buttonSpacing: CGFloat = md
    
    // Bordes y radios
    static let cornerRadius: CGFloat = 12
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 10
}

// MARK: - App Typography
struct AppTypography {
    // Títulos
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.medium)
    static let title3 = Font.title3.weight(.medium)
    
    // Cuerpo
    static let body = Font.body
    static let bodyMedium = Font.body.weight(.medium)
    static let callout = Font.callout
    
    // Pequeños
    static let caption = Font.caption
    static let caption2 = Font.caption2
    static let footnote = Font.footnote
}

// MARK: - App Icons
struct AppIcons {
    // Tab Bar
    static let home = "house"
    static let habit = "repeat"
    static let task = "checkmark.square"
    static let medication = "pills"
    static let progress = "chart.line.uptrend.xyaxis"
    
    // Quick Add
    static let habitCircle = "repeat.circle"
    static let taskCircle = "checkmark.circle"
    static let medicationCircle = "pills.circle"
    
    // Comunes
    static let plus = "plus"
    static let edit = "pencil"
    static let delete = "trash"
    static let chevronRight = "chevron.right"
    static let chevronDown = "chevron.down"
}

// MARK: - App Dimensions
struct AppDimensions {
    // Alturas
    static let headerHeight: CGFloat = 100
    static let tabBarHeight: CGFloat = 80
    static let buttonHeight: CGFloat = 50
    
    // Anchos
    static let maxContentWidth: CGFloat = 400
    
    // Tamaños de íconos
    static let smallIcon: CGFloat = 16
    static let mediumIcon: CGFloat = 20
    static let largeIcon: CGFloat = 24
    static let xlIcon: CGFloat = 32
} 