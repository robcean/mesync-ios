//
//  ViewExtensions.swift
//  meSync
//
//  Extensiones de View para estilos reutilizables
//

import SwiftUI

// MARK: - Text Styles
extension View {
    
    /// Estilo para títulos principales
    func primaryTitleStyle() -> some View {
        self
            .font(AppTypography.largeTitle)
            .foregroundStyle(AppColors.primaryText)
    }
    
    /// Estilo para títulos de sección
    func sectionTitleStyle() -> some View {
        self
            .font(AppTypography.title2)
            .foregroundStyle(AppColors.primaryText)
    }
    
    /// Estilo para subtítulos
    func subtitleStyle() -> some View {
        self
            .font(AppTypography.callout)
            .foregroundStyle(AppColors.secondaryText)
    }
    
    /// Estilo para texto de fecha
    func dateTextStyle() -> some View {
        self
            .font(AppTypography.callout)
            .foregroundStyle(AppColors.secondaryText)
    }
    
    /// Estilo para texto de caption
    func captionStyle() -> some View {
        self
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.tertiaryText)
    }
}

// MARK: - Container Styles
extension View {
    
    /// Estilo para tarjetas de sección
    func sectionCardStyle() -> some View {
        self
            .padding(AppSpacing.cardPadding)
            .background(AppColors.cardMaterial, in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
            .padding(.horizontal, AppSpacing.lg)
    }
    
    /// Estilo para header fijo
    func headerContainerStyle() -> some View {
        self
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.md)
            .background(AppColors.headerMaterial)
    }
    
    /// Estilo para footer/tab bar
    func tabBarContainerStyle() -> some View {
        self
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.headerMaterial)
    }
    
    /// Estilo para contenedor principal
    func mainContainerStyle() -> some View {
        self
            .background(AppColors.background)
    }
}

// MARK: - Button Styles
extension View {
    
    /// Estilo para botón principal
    func primaryButtonStyle() -> some View {
        self
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: AppSpacing.buttonCornerRadius))
    }
    
    /// Estilo para botón secundario
    func secondaryButtonStyle() -> some View {
        self
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: AppSpacing.buttonCornerRadius))
    }
    
    /// Estilo para botón de texto simple
    func textButtonStyle() -> some View {
        self
            .buttonStyle(.plain)
    }
}

// MARK: - Dynamic Height TextEditor
struct DynamicHeightTextEditor: View {
    @Binding var text: String
    let placeholder: String
    @State private var textHeight: CGFloat = 40
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(AppColors.tertiaryText)
                    .padding(.horizontal, AppSpacing.sm + 4)
                    .padding(.vertical, AppSpacing.sm + 8)
            }
            
            // Invisible text to calculate height
            Text(text.isEmpty ? " " : text)
                .font(AppTypography.body)
                .lineSpacing(4)
                .padding(.horizontal, AppSpacing.sm + 4)
                .padding(.vertical, AppSpacing.sm + 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GeometryReader { geometry in
                    Color.clear.preference(
                        key: TextHeightPreferenceKey.self,
                        value: geometry.size.height
                    )
                })
                .onPreferenceChange(TextHeightPreferenceKey.self) { height in
                    textHeight = max(40, height)
                }
                .opacity(0) // Make the text invisible
            
            // Actual TextEditor
            TextEditor(text: $text)
                .font(AppTypography.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xs)
                .frame(minHeight: textHeight, maxHeight: textHeight)
        }
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }
}

struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Layout Helpers
extension View {
    
    /// Padding estándar horizontal
    func standardHorizontalPadding() -> some View {
        self.padding(.horizontal, AppSpacing.lg)
    }
    
    /// Padding estándar vertical
    func standardVerticalPadding() -> some View {
        self.padding(.vertical, AppSpacing.md)
    }
    
    /// Padding completo estándar
    func standardPadding() -> some View {
        self.padding(AppSpacing.lg)
    }
    
    /// Espaciado entre secciones
    func sectionSpacing() -> some View {
        self.padding(.bottom, AppSpacing.sectionSpacing)
    }
}

// MARK: - Animation Helpers
extension View {
    
    /// Animación estándar suave
    func standardAnimation() -> some View {
        self.animation(.easeInOut(duration: 0.3), value: UUID())
    }
    
    /// Animación rápida
    func quickAnimation() -> some View {
        self.animation(.easeInOut(duration: 0.2), value: UUID())
    }
    
    /// Animación lenta
    func slowAnimation() -> some View {
        self.animation(.easeInOut(duration: 0.5), value: UUID())
    }
} 