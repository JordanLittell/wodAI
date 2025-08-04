//
//  WeeklyWorkoutView.swift
//  wodAI
//
//  Weekly workout navigation view for browsing scheduled workouts
//

import SwiftUI
import WodAiAPI

struct WeeklyWorkoutView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @EnvironmentObject var wodSessionManager: WODSessionManager
    @State private var selectedDate = Date()
    @State private var displayedWeekDate = Date() // Tracks which week is shown
    @State private var currentWeekOffset = 0
    @State private var workoutForSelectedDate: Workout?
    @State private var isLoading = false
    @State private var showingWorkout = false
    @State private var errorMessage: String?
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    // Calendar helpers
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
    
    private var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: displayedWeekDate) else {
            return []
        }
        
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var previousWeekDays: [Date] {
        guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: displayedWeekDate),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: previousWeek) else {
            return []
        }
        
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var nextWeekDays: [Date] {
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: displayedWeekDate),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: nextWeek) else {
            return []
        }
        
        let startOfWeek = weekInterval.start
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    private var headerMessage: String {
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        
        if selected == today {
            return "Today's Training"
        } else if selected == calendar.date(byAdding: .day, value: 1, to: today) {
            return "Tomorrow's Training"
        } else if selected == calendar.date(byAdding: .day, value: -1, to: today) {
            return "Yesterday's Training"
        } else {
            return dateFormatter.string(from: selectedDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main Header
                VStack(spacing: 8) {
                    Text(headerMessage)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text("Plan your week, crush your goals")
                        .font(.subheadline)
                        .foregroundColor(Color("SecondaryText"))
                    
                    Text("Swipe to browse weeks • Tap to select day")
                        .font(.caption)
                        .foregroundColor(Color("TertiaryText"))
                        .padding(.top, 2)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Week Navigation
                VStack(spacing: 16) {
                    // Day Selector with enhanced drag interaction
                    ZStack {
                        // Current week
                        HStack(spacing: 8) {
                            ForEach(weekDays, id: \.self) { date in
                                DayButton(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    isToday: calendar.isDateInToday(date),
                                    isDragging: isDragging,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDate = date
                                        }
                                    }
                                )
                            }
                        }
                        .offset(x: dragOffset)
                        .opacity(isDragging ? 0.7 : 1.0)
                        
                        // Previous week (slides in from left)
                        if dragOffset > 0 {
                            HStack(spacing: 8) {
                                ForEach(previousWeekDays, id: \.self) { date in
                                    DayButton(
                                        date: date,
                                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                        isToday: calendar.isDateInToday(date),
                                        isDragging: isDragging,
                                        onTap: { }
                                    )
                                }
                            }
                            .offset(x: dragOffset - UIScreen.main.bounds.width)
                            .opacity(Double(dragOffset / UIScreen.main.bounds.width))
                        }
                        
                        // Next week (slides in from right)
                        if dragOffset < 0 {
                            HStack(spacing: 8) {
                                ForEach(nextWeekDays, id: \.self) { date in
                                    DayButton(
                                        date: date,
                                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                        isToday: calendar.isDateInToday(date),
                                        isDragging: isDragging,
                                        onTap: { }
                                    )
                                }
                            }
                            .offset(x: dragOffset + UIScreen.main.bounds.width)
                            .opacity(Double(-dragOffset / UIScreen.main.bounds.width))
                        }
                    }
                    .padding(.horizontal)
                    .clipped() // Prevents overflow during drag
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    // Haptic feedback on drag start
                                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                                    impactLight.impactOccurred()
                                }
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 100
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    if value.translation.width > threshold {
                                        // Swipe right - go to previous week
                                        navigateToPreviousWeek()
                                        // Haptic feedback on week change
                                        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
                                        impactMedium.impactOccurred()
                                    } else if value.translation.width < -threshold {
                                        // Swipe left - go to next week  
                                        navigateToNextWeek()
                                        // Haptic feedback on week change
                                        let impactMedium = UIImpactFeedbackGenerator(style: .medium)
                                        impactMedium.impactOccurred()
                                    }
                                    
                                    dragOffset = 0
                                    isDragging = false
                                }
                            }
                    )
                }
                .padding(.bottom, 24)
                
                // Workout View
                ScrollView {
                    VStack(spacing: 16) {
                        if isLoading {
                            WeeklyLoadingCard()
                                .padding(.horizontal)
                        } else if let workout = workoutForSelectedDate {
                            WeeklyWorkoutCard(
                                workout: workout,
                                date: selectedDate,
                                onStartWorkout: {
                                    workoutGenerator.workout = workout
                                    showingWorkout = true
                                }
                            )
                            .padding(.horizontal)
                        } else if let error = errorMessage {
                            WeeklyErrorCard(
                                message: error,
                                onRetry: { fetchWorkoutForDate() },
                                onGenerate: { generateWorkoutForDate() }
                            )
                            .padding(.horizontal)
                        } else {
                            EmptyDayCard(
                                date: selectedDate,
                                onGenerateWorkout: { generateWorkoutForDate() }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(Color("Background"))
            .navigationBarHidden(true)
            .onAppear {
                fetchWorkoutForDate()
            }
            .onChange(of: selectedDate) { oldValue, newValue in
                fetchWorkoutForDate()
            }
            .fullScreenCover(isPresented: $showingWorkout) {
                NavigationView {
                    WorkoutView()
                        .environmentObject(workoutGenerator)
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    // MARK: - Navigation Methods
    private func navigateToPreviousWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: displayedWeekDate) {
                displayedWeekDate = newDate
            }
        }
    }
    
    private func navigateToNextWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: displayedWeekDate) {
                displayedWeekDate = newDate
            }
        }
    }
    
    // MARK: - Data Methods
    private func fetchWorkoutForDate() {
        isLoading = true
        errorMessage = nil
        
        // For now, we'll use currentWod query if it's today
        // In a real implementation, you'd have a query that accepts a date parameter
        let isToday = calendar.isDateInToday(selectedDate)
        
        if isToday {
            Network.shared.client.fetch(query: CurrentWODQuery()) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    switch result {
                    case .success(let graphQLResult):
                        if let currentWod = graphQLResult.data?.currentWod {
                            let components = currentWod.components.map { component in
                                Component(
                                    name: component.name,
                                    order: component.order,
                                    definition: component.definition,
                                    description: "",
                                    targetFitnessDomains: nil,
                                    energySystems: nil
                                )
                            }
                            
                            workoutForSelectedDate = Workout(
                                id: currentWod.id,
                                name: currentWod.name,
                                description: currentWod.description,
                                components: components,
                                completedAt: nil,
                                completed: currentWod.completed
                            )
                        } else {
                            workoutForSelectedDate = nil
                        }
                        
                    case .failure(let error):
                        errorMessage = "Failed to load workout"
                        print("Error fetching workout: \(error)")
                    }
                }
            }
        } else {
            // For non-today dates, we don't have a workout yet
            // This is where you'd implement fetching workouts by date
            isLoading = false
            workoutForSelectedDate = nil
        }
    }
    
    private func generateWorkoutForDate() {
        isLoading = true
        errorMessage = nil
        
        Network.shared.client.perform(mutation: GenerateWODMutation()) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let graphQLResult):
                    if let generatedWod = graphQLResult.data?.generateWod {
                        let components = generatedWod.components.map { component in
                            Component(
                                name: component.name,
                                order: component.order,
                                definition: component.definition,
                                description: component.description,
                                targetFitnessDomains: nil,
                                energySystems: nil
                            )
                        }
                        
                        let newWorkout = Workout(
                            id: generatedWod.id,
                            name: generatedWod.name,
                            description: generatedWod.description,
                            components: components,
                            completedAt: nil,
                            completed: false
                        )
                        
                        workoutForSelectedDate = newWorkout
                        workoutGenerator.workout = newWorkout
                        showingWorkout = true
                    }
                    
                case .failure(let error):
                    errorMessage = "Failed to generate workout"
                    print("Error generating workout: \(error)")
                }
            }
        }
    }
}

// MARK: - Day Button Component
struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isDragging: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()
    
    private var dayAbbreviation: String {
        let fullDay = dayFormatter.string(from: date)
        switch fullDay {
        case "Sun": return "Sun"
        case "Mon": return "M"
        case "Tue": return "T"
        case "Wed": return "W"
        case "Thu": return "Th"
        case "Fri": return "F"
        case "Sat": return "Sat"
        default: return String(fullDay.prefix(1))
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(dayAbbreviation)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : Color("SecondaryText"))
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .white : Color("PrimaryText"))
                
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 44, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("BrandPrimary") : Color("Surface"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday && !isSelected ? Color("BrandPrimary") : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isDragging ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Weekly Workout Card
struct WeeklyWorkoutCard: View {
    let workout: Workout
    let date: Date
    let onStartWorkout: () -> Void
    
    @State private var isIntentionExpanded = false
    private let calendar = Calendar.current
    
    private var isCompleted: Bool {
        workout.completed
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "dumbbell.fill")
                            .font(.title3)
                            .foregroundColor(isCompleted ? Color("Success") : Color("BrandPrimary"))
                        
                        Text(workout.name)
                            .font(.headline)
                            .foregroundColor(Color("PrimaryText"))
                    }
                    
                    if isCompleted {
                        Text("Completed")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("Success"))
                    }
                }
                
                Spacer()
                
                if !isCompleted {
                    Button(action: onStartWorkout) {
                        Text("Start")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color("BrandPrimary"))
                            .cornerRadius(20)
                    }
                }
            }
            
            // Components Section - Always visible and prominent
            VStack(alignment: .leading, spacing: 16) {
                // Workout Intention - Expandable section (secondary information)
                if !workout.description.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: { withAnimation(.easeInOut(duration: 0.3)) { isIntentionExpanded.toggle() } }) {
                            HStack {
                                Label("Workout Intention", systemImage: "lightbulb")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("BrandPrimary"))
                                
                                Spacer()
                                
                                Image(systemName: isIntentionExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(Color("BrandPrimary"))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if isIntentionExpanded {
                            Text(workout.description)
                                .font(.callout)
                                .foregroundColor(Color("SecondaryText"))
                                .multilineTextAlignment(.leading)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(12)
                    .background(Color("Surface2").opacity(0.5))
                    .cornerRadius(10)
                }
                
                ForEach(Array(workout.components.enumerated()), id: \.element.id) { index, component in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(component.name)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("PrimaryText"))
                        
                        Text(component.definition)
                            .font(.body)
                            .foregroundColor(Color("PrimaryText"))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                        
                        if !component.description.isEmpty {
                            Text(component.description)
                                .font(.callout)
                                .italic()
                                .foregroundColor(Color("SecondaryText"))
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color("Background"))
                    .cornerRadius(10)
                }
                
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty Day Card
struct EmptyDayCard: View {
    let date: Date
    let onGenerateWorkout: () -> Void
    
    private let calendar = Calendar.current
    
    private var message: String {
        if calendar.isDateInToday(date) {
            return "No programming scheduled for today"
        } else if date < Date() {
            return "No programming was scheduled for this date"
        } else {
            return "Programming unavailable"
        }
    }
    
    private var canGenerate: Bool {
        // Only allow generating for today and future dates
        return calendar.isDateInToday(date) || date > Date()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(Color("SecondaryText").opacity(0.5))
            
            VStack(spacing: 8) {
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("PrimaryText"))
                
                Text("Hang tight! Programming for this date will be released soon.")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
                
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Border"), lineWidth: 1)
        )
    }
}

// MARK: - Loading Card
struct WeeklyLoadingCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color("Surface2"))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Surface2"))
                        .frame(width: 150, height: 14)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color("Surface2"))
                        .frame(width: 100, height: 12)
                }
                
                Spacer()
            }
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("Surface2"))
                .frame(height: 60)
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Error Card
struct WeeklyErrorCard: View {
    let message: String
    let onRetry: () -> Void
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(Color("Warning"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unable to load workout")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("PrimaryText"))
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Retry")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(Color("TertiaryText"))
                
                Button(action: onGenerate) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                        Text("Generate New")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color("BrandPrimary"))
                }
            }
        }
        .padding()
        .background(Color("Surface"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("Warning").opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    WeeklyWorkoutView()
        .environmentObject(EnhancedWorkoutGeneratorViewModel())
        .environmentObject(WODSessionManager.shared)
}
