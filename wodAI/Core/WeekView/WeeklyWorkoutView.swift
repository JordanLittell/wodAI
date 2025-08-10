//
//  WeeklyWorkoutView.swift
//  wodAI
//
//  Weekly workout navigation view with 7-day async workout generation support
import SwiftUI
import WodAiAPI

struct WeeklyWorkoutView: View {
    @EnvironmentObject var workoutGenerator: EnhancedWorkoutGeneratorViewModel
    @EnvironmentObject var wodSessionManager: WODSessionManager
    @StateObject private var weeklyViewModel = WeeklyWorkoutViewModel()
    
    @State private var displayedWeekDate = Date() // Tracks which week is shown
    @State private var showingWorkout = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    // Calendar helpers - ensure consistent timezone handling
    private let calendar = DateUtility.deviceCalendar
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - Week Generation Methods
    
    private var weekDays: [Date] {
        return DateUtility.generateWeekDays(containing: displayedWeekDate)
    }
    
    private var previousWeekDays: [Date] {
        guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: displayedWeekDate) else {
            return []
        }
        return DateUtility.generateWeekDays(containing: previousWeek)
    }
    
    private var nextWeekDays: [Date] {
        guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: displayedWeekDate) else {
            return []
        }
        return DateUtility.generateWeekDays(containing: nextWeek)
    }
    
    private var headerMessage: String {
        let today = DateUtility.startOfDay(for: Date())
        let selected = DateUtility.startOfDay(for: weeklyViewModel.selectedDate)
        
        if selected == today {
            return "Today's Training"
        } else if selected == calendar.date(byAdding: .day, value: 1, to: today) {
            return "Tomorrow's Training"
        } else if selected == calendar.date(byAdding: .day, value: -1, to: today) {
            return "Yesterday's Training"
        } else {
            return dateFormatter.string(from: weeklyViewModel.selectedDate)
        }
    }
    
    // MARK: - Helper Methods
    private func getDayButtonStatus(for date: Date) -> DayButtonStatus {
        let dateKey = DateUtility.startOfDay(for: date)
        
        print("getting status for date key \(dateKey)")
        // Debug logging
        if weeklyViewModel.workouts.isEmpty {
            print("ℹ️ No workouts loaded yet")
        } else {
            print("📊 \(weeklyViewModel.workouts.count) workouts loaded")
            weeklyViewModel.workouts.forEach { (key: Date, value: Workout) in
                print("  • \(DateUtility.shortDateFormatter.string(from: key)): \(value.name) (\(value.status.displayName))")
            }
        }
        
        
        
        
        // First priority: Check if there's already a workout for this date
        if let workout = weeklyViewModel.workouts[dateKey] {
            return .workoutScheduled(workout.status)
        }
        
        // Second priority: If no workout exists and we're loading, show loading state
        if weeklyViewModel.isLoading {
            return .loading
        }
        
        // Default: No workout scheduled for this date
        return .noWorkout
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
                                    isSelected: DateUtility.isSameDay(date, weeklyViewModel.selectedDate),
                                    isToday: DateUtility.isToday(date),
                                    isDragging: isDragging,
                                    status: getDayButtonStatus(for: date),
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            weeklyViewModel.selectedDate = date
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
                                        isSelected: DateUtility.isSameDay(date, weeklyViewModel.selectedDate),
                                        isToday: DateUtility.isToday(date),
                                        isDragging: isDragging,
                                        status: .loading, // Show loading for preview week
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
                                        isSelected: DateUtility.isSameDay(date, weeklyViewModel.selectedDate),
                                        isToday: DateUtility.isToday(date),
                                        isDragging: isDragging,
                                        status: .loading, // Show loading for preview week
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
                        if weeklyViewModel.isLoadingWorkoutForSelectedDate {
                            if let workout = weeklyViewModel.workoutForSelectedDate, workout.status.isGenerating {
                                WorkoutLoadingView(workout: workout)
                                    .padding(.horizontal)
                            } else {
                                WeeklyLoadingCard()
                                    .padding(.horizontal)
                            }
                        } else if let workout = weeklyViewModel.workoutForSelectedDate {
                            if workout.status == .failed {
                                WeeklyErrorCard(
                                    message: "Failed to generate workout",
                                    onRetry: { weeklyViewModel.retryFailedWorkout() },
                                    onGenerate: { weeklyViewModel.generateWorkoutSchedule() }
                                )
                                .padding(.horizontal)
                            } else {
                                WeeklyWorkoutCard(
                                    workout: workout,
                                    date: weeklyViewModel.selectedDate,
                                    onStartWorkout: {
                                        workoutGenerator.workout = workout
                                        showingWorkout = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        } else if let error = weeklyViewModel.errorMessage {
                            WeeklyErrorCard(
                                message: error,
                                onRetry: { weeklyViewModel.loadWorkoutForDate(weeklyViewModel.selectedDate) },
                                onGenerate: { weeklyViewModel.generateWorkoutSchedule() }
                            )
                            .padding(.horizontal)
                        } else {
                            EmptyDayCard(
                                date: weeklyViewModel.selectedDate,
                                onGenerateWorkout: { weeklyViewModel.generateWorkoutSchedule() }
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
                print("🚀 WeeklyWorkoutView appeared, loading workouts for week containing: \(weeklyViewModel.selectedDate)")
                DateUtility.logTimezoneInfo() // Log timezone info for debugging
                DateUtility.debugWeekGeneration(for: weeklyViewModel.selectedDate) // Debug week calculation
                weeklyViewModel.loadWorkoutsForWeek(containing: weeklyViewModel.selectedDate)
            }
            .onChange(of: weeklyViewModel.selectedDate) { oldValue, newValue in
                weeklyViewModel.loadWorkoutForDate(newValue)
                
                #if DEBUG
                // Debug workout data when date changes - especially useful for navigation issues
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    weeklyViewModel.debugWorkoutData(for: newValue)
                }
                #endif
            }
            .onChange(of: displayedWeekDate) { oldValue, newValue in
                weeklyViewModel.loadWorkoutsForWeek(containing: newValue)
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
}


// MARK: - Preview
#Preview {
    WeeklyWorkoutView()
        .environmentObject(EnhancedWorkoutGeneratorViewModel())
        .environmentObject(WODSessionManager.shared)
}
