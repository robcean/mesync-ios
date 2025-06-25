# 📋 meSync App - Development Prompts Documentation

> **Propósito:** Este archivo contiene todos los prompts clave utilizados para desarrollar la aplicación meSync en SwiftUI. Servirá como base reutilizable para la versión Android y futuras iteraciones del proyecto.

---

## 🎯 **Arquitectura General**

### **Sistema de Estilos Centralizados**
```
Implementa un sistema de estilos centralizados tipo CSS para SwiftUI:
- AppColors: colores primarios, secundarios, fondos, textos, estados
- AppSpacing: espaciado xs, sm, md, lg, xl con valores consistentes
- AppTypography: tipografías para títulos, cuerpo, caption
- ViewExtensions: modificadores reutilizables (.primaryTitleStyle(), .sectionCardStyle())
- ButtonStyles: estilos personalizados con efectos de presión
Todos los componentes deben usar estos estilos centralizados, nunca valores hardcodeados.
```

### **Gestión de Estados con Enum**
```
Crea un sistema de navegación centralizado usando enum QuickAddState:
- Estados: hidden, taskForm, habitForm, medicationForm
- Métodos: show(), hide(), toggle()
- Binding compartido entre componentes
- Animaciones suaves entre estados
- Reset automático de formularios al cambiar estado
```

---

## 🏠 **Componentes de UI**

### **TaskFormView - Formulario de Tareas**
```
Crea un formulario completo para tareas con:
- Campos: name (TextField), description (TextField multiline), dueDate (DatePicker), priority (Picker)
- Validación: name no puede estar vacío
- Estados: isEditing (para editar vs crear nueva)
- Acciones: Save, Delete (solo en edición), Cancel
- Auto-focus en campo name al aparecer
- Reset completo de campos al cerrar
- Integración con SwiftData para persistencia
- Estilos centralizados y UX pulida
```

### **HabitFormView - Formulario de Hábitos**
```
Crea un formulario avanzado para hábitos con:
- Campos básicos: name, description, remindAt (time picker)
- Sistema de frecuencias: NoRepetition, Daily, Weekly, Monthly, Custom
- Configuración dinámica por frecuencia:
  * Daily: intervalo de días (cada X días)
  * Weekly: días de la semana + intervalo semanal
  * Monthly: día del mes + intervalo mensual
  * Custom: array de días específicos del mes
- Auto-selección del día actual al elegir Weekly
- Validación completa de campos
- Integración con SwiftData usando @Attribute(.externalStorage) para arrays
- Estados de edición vs creación
- UX intuitiva con selecciones visuales
```

### **ItemsListView - Lista Unificada**
```
Implementa una lista inteligente que combine tasks y habits:
- Protocolo ItemProtocol para unificar tasks y habits
- Sistema de HabitInstance para generar instancias dinámicas por fecha
- Ventana de 3 días (hoy + 2 siguientes) para optimizar performance
- Algoritmos de repetición para cada tipo de frecuencia
- Estados independientes por fecha usando claves "habitID_yyyy-MM-dd"
- Organización: items activos arriba, completados/skipped abajo con divider
- Diferenciación visual: habits con ícono repeat, tasks con prioridad
- Fechas dinámicas: "Today", "Tomorrow", "Dec 16"
- Acciones unificadas: Edit, Skip, Complete para ambos tipos
- Animaciones suaves y UX consistente
```

### **Accordion QuickAdd**
```
Crea un componente accordion expandible:
- Estado colapsado: botón circular con ícono +
- Estado expandido: fila horizontal con 3 botones (Task, Habit, Medication)
- Animaciones suaves de expansión/colapso
- Posición fija en bottom con padding seguro
- Integración con QuickAddState para navegación
- Estilos visuales consistentes con tema de la app
- Feedback táctil y visual en interacciones
```

---

## 🔄 **Lógica de Negocio**

### **Sistema de Repeticiones de Hábitos**
```
Implementa algoritmos de repetición para hábitos:
- Daily: daysDifference % dailyInterval == 0
- Weekly: validar día de semana + weeksDifference % weeklyInterval == 0
- Monthly: validar día del mes + monthsDifference % monthlyInterval == 0
- Custom: validar si día actual está en array customDays
- NoRepetition: solo fecha original
- Conversión de weekdays: Sunday=1 a Monday=1 format
- Manejo de edge cases: meses cortos, años bisiestos
- Generación dinámica en memoria, no en base de datos
```

### **Gestión de Estados de Hábitos**
```
Sistema de estados independientes por fecha:
- Dictionary habitInstanceStates con clave "habitID_yyyy-MM-dd"
- Estados: isCompleted, isSkipped por instancia
- Persistencia en memoria durante sesión
- Sincronización entre HabitInstance y storage
- RefreshTrigger para forzar actualización de vista
- Estados no se afectan entre diferentes fechas del mismo hábito
```

---

## 💾 **Persistencia de Datos**

### **Modelos SwiftData**
```
Define modelos de datos con SwiftData:
- TaskData: id, name, taskDescription, dueDate, priority, isCompleted, isSkipped
- HabitData: id, name, habitDescription, frequency, remindAt, intervalos, arrays de días
- Usar @Attribute(.externalStorage) para arrays complejos
- Relaciones apropiadas entre modelos
- Validaciones y constraints necesarios
- Migración de datos cuando sea necesario
```

### **Operaciones CRUD**
```
Implementa operaciones completas:
- Create: insertar en modelContext con validación
- Read: @Query con sorting apropiado
- Update: modificar propiedades y save context
- Delete: remover del context con confirmación
- Error handling robusto para todas las operaciones
- Feedback visual al usuario sobre el estado de las operaciones
```

---

## 🎨 **Diseño y UX**

### **Principios de Diseño**
```
Aplica principios de diseño consistentes:
- Jerarquía visual clara con tipografías diferenciadas
- Espaciado consistente usando sistema de tokens
- Colores semánticos para estados (verde=success, rojo=error, etc.)
- Animaciones suaves y naturales (0.2s-0.5s)
- Feedback inmediato en todas las interacciones
- Accesibilidad con labels y hints apropiados
- Responsive design que funcione en diferentes tamaños
```

### **Patrones de Interacción**
```
Implementa patrones de UX consistentes:
- Swipe actions para operaciones rápidas
- Long press para opciones adicionales
- Pull to refresh donde sea apropiado
- Loading states y empty states informativos
- Confirmaciones para acciones destructivas
- Auto-save vs manual save según el contexto
- Navigation patterns predecibles
```

---

## 🔧 **Optimización y Performance**

### **Estrategias de Performance**
```
Optimiza el rendimiento de la aplicación:
- Lazy loading para listas largas
- Generación dinámica vs almacenamiento masivo en DB
- Ventanas de tiempo limitadas (3 días) para reducir carga
- Caching inteligente de cálculos complejos
- Debouncing en búsquedas y filtros
- Minimizar re-renders innecesarios
- Profiling regular de memory usage
```

### **Gestión de Memoria**
```
Maneja la memoria eficientemente:
- @State vs @StateObject vs @ObservedObject apropiadamente
- Cleanup de observers y timers
- Weak references donde sea necesario
- Evitar retain cycles en closures
- Monitoring de memory leaks en desarrollo
```

---

## 📱 **Funcionalidades Específicas**

### **Sistema de Notificaciones**
```
Implementa notificaciones locales:
- Permisos de usuario con explicación clara
- Scheduling basado en remind time de hábitos
- Cancelación automática de notificaciones obsoletas
- Personalización de mensajes por tipo de item
- Deep linking desde notificación a item específico
- Configuración granular por usuario
```

### **Filtros y Búsqueda**
```
Sistema de filtros avanzado:
- Filtros por tipo: solo tasks, solo habits, ambos
- Filtros por estado: active, completed, skipped
- Filtros por fecha: today, this week, custom range
- Búsqueda por texto en name y description
- Combinación de múltiples filtros
- Persistencia de preferencias de filtro
- UI intuitiva para aplicar/limpiar filtros
```

### **Estadísticas y Analytics**
```
Dashboard de progreso:
- Streaks de hábitos completados consecutivamente
- Porcentajes de completitud por período
- Gráficos de tendencias temporales
- Comparativas entre diferentes hábitos
- Métricas de productividad personal
- Exportación de datos para análisis externo
```

---

## 🔄 **Patrones de Desarrollo**

### **Arquitectura MVVM**
```
Estructura el código con MVVM:
- Views: solo UI y binding a ViewModels
- ViewModels: lógica de presentación y estado
- Models: datos y lógica de negocio
- Services: operaciones externas (API, storage, etc.)
- Dependency injection para testabilidad
- Separation of concerns clara
```

### **Testing Strategy**
```
Estrategia de testing comprehensiva:
- Unit tests para lógica de negocio
- UI tests para flujos críticos
- Integration tests para persistencia
- Performance tests para operaciones costosas
- Mock objects para dependencies externas
- Test coverage mínimo del 80%
- Automated testing en CI/CD
```

---

## 🚀 **Deployment y Distribución**

### **Build Configuration**
```
Configuración de builds:
- Debug vs Release configurations
- Environment variables para diferentes stages
- Code signing y provisioning profiles
- App Store optimization (metadata, screenshots)
- Crash reporting y analytics integration
- Feature flags para rollout gradual
```

### **Versionado y Updates**
```
Estrategia de versioning:
- Semantic versioning (major.minor.patch)
- Migration scripts para cambios de schema
- Backward compatibility considerations
- Update prompts y force update logic
- Rollback strategies para updates problemáticos
- User communication sobre nuevas features
```

---

## 📋 **Checklist de Implementación**

### **Pre-Development**
- [ ] Definir arquitectura y patrones
- [ ] Configurar sistema de estilos centralizados
- [ ] Establecer estructura de carpetas
- [ ] Configurar herramientas de desarrollo

### **Durante Development**
- [ ] Seguir principios de diseño establecidos
- [ ] Implementar error handling robusto
- [ ] Escribir tests para nueva funcionalidad
- [ ] Documentar decisiones arquitectónicas importantes

### **Pre-Release**
- [ ] Testing comprehensivo en diferentes dispositivos
- [ ] Performance profiling y optimization
- [ ] Accessibility audit completo
- [ ] Security review de datos sensibles

---

## 🔄 **Adaptación para Android**

### **Equivalencias de Tecnologías**
```
SwiftUI → Jetpack Compose
SwiftData → Room Database
@State/@Binding → remember/mutableStateOf
NavigationView → Navigation Compose
Combine → Flow/StateFlow
UserDefaults → SharedPreferences/DataStore
```

### **Consideraciones Específicas de Android**
```
- Material Design 3 guidelines
- Android lifecycle management
- Permission handling differences
- Background processing limitations
- Different screen sizes and densities
- Android-specific UX patterns
- Play Store requirements y policies
```

---

*Documento creado: 14 de Junio, 2025*
*Última actualización: 14 de Junio, 2025 - 02:40*

> **Nota:** Este documento debe actualizarse cada vez que se implementen nuevas funcionalidades o se refinen patrones existentes. Servirá como guía maestra para el desarrollo cross-platform de meSync. 