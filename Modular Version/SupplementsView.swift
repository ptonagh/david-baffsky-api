import SwiftUI

struct SupplementsView: View {
    @EnvironmentObject var recoveryViewModel: RecoveryViewModel
    @State private var selectedTimeSlot: String? = nil
    @State private var showingProtocolDetails = false
    @State private var berberineWeek = UserDefaults.standard.integer(forKey: "berberineWeek") == 0 ? 1 : UserDefaults.standard.integer(forKey: "berberineWeek")
    @State private var trackingEnabled = UserDefaults.standard.bool(forKey: "supplementTracking")
    @State private var takenSupplements: Set<String> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Recovery-Based Protocol Card
                    recoveryProtocolCard
                    
                    // Quick Actions
                    quickActionsCard
                    
                    // Time-Based Supplement Schedule
                    timeBasedSchedule
                    
                    // Genetic Optimizations
                    geneticOptimizationsCard
                    
                    // Berberine Protocol
                    berberineProtocolCard
                    
                    // Weekly Schedule
                    weeklyScheduleCard
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Supplements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingProtocolDetails.toggle() }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingProtocolDetails) {
            ProtocolDetailsView()
        }
        .onAppear {
            loadTakenSupplements()
        }
    }
    
    var recoveryProtocolCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("Today's Protocol")
                    .font(.headline)
                Spacer()
                Text("\(Int(recoveryViewModel.calculatedRecovery))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(recoveryColor)
            }
            
            Text(recoveryMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if recoveryViewModel.calculatedRecovery < 60 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Focus on recovery supplements today")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    var quickActionsCard: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "alarm",
                title: "Set Reminders",
                color: .blue,
                action: { setupReminders() }
            )
            
            QuickActionButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Track Progress",
                color: .green,
                action: { trackingEnabled.toggle() }
            )
            
            QuickActionButton(
                icon: "doc.text",
                title: "Export Log",
                color: .purple,
                action: { exportSupplementLog() }
            )
        }
    }
    
    var timeBasedSchedule: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Schedule")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(supplementSchedule, id: \.time) { timeSlot in
                TimeSlotCard(
                    timeSlot: timeSlot,
                    isExpanded: selectedTimeSlot == timeSlot.time,
                    takenSupplements: takenSupplements,
                    onTap: {
                        withAnimation(.spring()) {
                            selectedTimeSlot = selectedTimeSlot == timeSlot.time ? nil : timeSlot.time
                        }
                    },
                    onToggleSupplement: { supplementId in
                        toggleSupplement(supplementId)
                    }
                )
            }
        }
    }
    
    var geneticOptimizationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dna")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Genetic Optimizations")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                GeneticOptimizationRow(
                    gene: "CYP24A1 AA",
                    optimization: "5000 IU Vitamin D3 (higher need)",
                    icon: "sun.max.fill",
                    color: .yellow
                )
                
                GeneticOptimizationRow(
                    gene: "ACE GG",
                    optimization: "6g L-Citrulline pre-workout",
                    icon: "bolt.heart.fill",
                    color: .red
                )
                
                GeneticOptimizationRow(
                    gene: "APOE E3/E3",
                    optimization: "2-3g Omega-3s for lipids",
                    icon: "drop.fill",
                    color: .blue
                )
                
                GeneticOptimizationRow(
                    gene: "SLC23A1 GA",
                    optimization: "1000mg Vitamin C (split doses)",
                    icon: "leaf.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    var berberineProtocolCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Berberine Protocol")
                    .font(.headline)
                Spacer()
                Text("Week \(berberineWeek)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(berberinePhaseDescription)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text(berberineTiming)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Button(action: { advanceBerberineWeek() }) {
                    Text("Mark Week Complete")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    var weeklyScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("Weekly Protocols")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                WeeklyProtocolRow(
                    day: "Sunday Evening",
                    protocol: "Rapamycin 6mg",
                    icon: "pills.fill",
                    color: .purple
                )
                
                WeeklyProtocolRow(
                    day: "Daily",
                    protocol: "CJC/Ipamorelin (per physician)",
                    icon: "syringe.fill",
                    color: .blue
                )
                
                WeeklyProtocolRow(
                    day: "Every 8 Weeks",
                    protocol: "1-week supplement break",
                    icon: "pause.circle.fill",
                    color: .gray
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    
    var recoveryColor: Color {
        if recoveryViewModel.calculatedRecovery >= 75 { return .green }
        if recoveryViewModel.calculatedRecovery >= 60 { return .blue }
        if recoveryViewModel.calculatedRecovery >= 40 { return .yellow }
        return .red
    }
    
    var recoveryMessage: String {
        if recoveryViewModel.calculatedRecovery >= 75 {
            return "Excellent recovery - full protocol with pre-workout stack"
        } else if recoveryViewModel.calculatedRecovery >= 60 {
            return "Good recovery - standard protocol applies"
        } else if recoveryViewModel.calculatedRecovery >= 40 {
            return "Moderate recovery - focus on recovery supplements"
        } else {
            return "Low recovery - minimize stimulants, maximize recovery support"
        }
    }
    
    var supplementSchedule: [TimeSlot] {
        var schedule: [TimeSlot] = []
        
        // Pre-Workout (5:45 AM)
        if recoveryViewModel.calculatedRecovery >= 60 {
            schedule.append(TimeSlot(
                time: "5:45 AM - Pre-Workout",
                supplements: [
                    Supplement(id: "citrulline", name: "L-Citrulline", dose: "6g", reason: "eNOS3 genetic support", icon: "bolt.heart"),
                    Supplement(id: "creatine-pre", name: "Creatine", dose: "5g", reason: "ATP production", icon: "battery.100"),
                    Supplement(id: "theanine-am", name: "L-Theanine", dose: "100mg", reason: "Calm focus", icon: "brain")
                ]
            ))
        }
        
        // Post-Workout (7:00 AM)
        schedule.append(TimeSlot(
            time: "7:00 AM - Post-Workout",
            supplements: [
                Supplement(id: "protein", name: "Protein", dose: "25-30g", reason: "Muscle recovery", icon: "figure.strengthtraining.traditional", isOptional: true),
                Supplement(id: "creatine-post", name: "Creatine", dose: "5g", reason: "Recovery support", icon: "battery.100"),
                Supplement(id: "vitc-post", name: "Vitamin C", dose: "500mg", reason: "Antioxidant support", icon: "leaf")
            ]
        ))
        
        // Breakfast (10:00 AM)
        schedule.append(TimeSlot(
            time: "10:00 AM - Breakfast",
            supplements: [
                Supplement(id: "nad", name: "NAD+ Booster", dose: "250mg", reason: "Mitochondrial support", icon: "battery.100.bolt"),
                Supplement(id: "coq10", name: "CoQ10", dose: "200mg", reason: "Cardiovascular support", icon: "heart"),
                Supplement(id: "berberine-am", name: "Berberine", dose: "500mg", reason: "Glucose management", icon: "chart.line.downtrend"),
                Supplement(id: "vitd3", name: "Vitamin D3", dose: "5000 IU", reason: "CYP24A1 AA variant", icon: "sun.max"),
                Supplement(id: "vitk2", name: "Vitamin K2", dose: "200mcg", reason: "With D3", icon: "shield"),
                Supplement(id: "omega3", name: "Omega-3", dose: "2-3g", reason: "Lipid management", icon: "drop"),
                Supplement(id: "ashwa-am", name: "Ashwagandha", dose: "300mg", reason: "Cortisol rhythm", icon: "leaf.arrow.triangle.circlepath"),
                Supplement(id: "bcomplex", name: "B-Complex", dose: "1 cap", reason: "COMT GA support", icon: "bolt"),
                Supplement(id: "sterols", name: "Plant Sterols", dose: "2g", reason: "Cholesterol", icon: "leaf.circle")
            ]
        ))
        
        // Lunch (12:30 PM)
        schedule.append(TimeSlot(
            time: "12:30 PM - Lunch",
            supplements: [
                Supplement(id: "berberine-lunch", name: "Berberine", dose: "500mg", reason: "Glucose management", icon: "chart.line.downtrend"),
                Supplement(id: "vitc-lunch", name: "Vitamin C", dose: "500mg", reason: "Complete 1000mg daily", icon: "leaf")
            ]
        ))
        
        // Dinner (6:00 PM)
        schedule.append(TimeSlot(
            time: "6:00 PM - Dinner",
            supplements: [
                Supplement(id: "berberine-dinner", name: "Berberine", dose: "500mg", reason: "Glucose management", icon: "chart.line.downtrend"),
                Supplement(id: "ryr", name: "Red Yeast Rice", dose: "1200mg", reason: "Cholesterol (after 4 weeks)", icon: "heart.text.square", isOptional: true)
            ]
        ))
        
        // Before Bed (9:00 PM)
        schedule.append(TimeSlot(
            time: "9:00 PM - Before Bed",
            supplements: [
                Supplement(id: "ashwa-pm", name: "Ashwagandha", dose: "300mg", reason: "Sleep support", icon: "moon"),
                Supplement(id: "theanine-pm", name: "L-Theanine", dose: "200mg", reason: "Sleep quality", icon: "moon.stars"),
                Supplement(id: "magnesium", name: "Magnesium Glycinate", dose: "400-600mg", reason: "2.5h after dinner", icon: "moon.zzz")
            ]
        ))
        
        return schedule
    }
    
    var berberinePhaseDescription: String {
        switch berberineWeek {
        case 1...2:
            return "Tolerance Building: Take with first bites of meals"
        case 3...4:
            return "Optimization: Take 5-10 min before meals"
        default:
            return "Maximum Benefit: Take 15 min before meals"
        }
    }
    
    var berberineTiming: String {
        switch berberineWeek {
        case 1...2:
            return "With first bites of each meal"
        case 3...4:
            return "5-10 minutes before meals"
        default:
            return "15 minutes before meals (monitor GI tolerance)"
        }
    }
    
    // MARK: - Helper Methods
    
    func toggleSupplement(_ supplementId: String) {
        if takenSupplements.contains(supplementId) {
            takenSupplements.remove(supplementId)
        } else {
            takenSupplements.insert(supplementId)
        }
        saveTakenSupplements()
    }
    
    func saveTakenSupplements() {
        let today = dateKey(for: Date())
        UserDefaults.standard.set(Array(takenSupplements), forKey: "supplements_\(today)")
    }
    
    func loadTakenSupplements() {
        let today = dateKey(for: Date())
        if let saved = UserDefaults.standard.array(forKey: "supplements_\(today)") as? [String] {
            takenSupplements = Set(saved)
        }
    }
    
    func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func advanceBerberineWeek() {
        berberineWeek += 1
        UserDefaults.standard.set(berberineWeek, forKey: "berberineWeek")
    }
    
    func setupReminders() {
        // Implementation for notification setup
    }
    
    func exportSupplementLog() {
        // Implementation for exporting supplement history
    }
}

// MARK: - Supporting Views

struct TimeSlotCard: View {
    let timeSlot: TimeSlot
    let isExpanded: Bool
    let takenSupplements: Set<String>
    let onTap: () -> Void
    let onToggleSupplement: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(timeSlot.time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if !isExpanded {
                        Text("\(completedCount)/\(timeSlot.supplements.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(timeSlot.supplements) { supplement in
                        SupplementRow(
                            supplement: supplement,
                            isTaken: takenSupplements.contains(supplement.id),
                            onToggle: { onToggleSupplement(supplement.id) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    var completedCount: Int {
        timeSlot.supplements.filter { takenSupplements.contains($0.id) }.count
    }
}

struct SupplementRow: View {
    let supplement: Supplement
    let isTaken: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: supplement.icon)
                    .foregroundColor(isTaken ? .green : .gray)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(supplement.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(isTaken)
                        
                        if supplement.isOptional {
                            Text("Optional")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack {
                        Text(supplement.dose)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(supplement.reason)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: isTaken ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isTaken ? .green : .gray)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

struct GeneticOptimizationRow: View {
    let gene: String
    let optimization: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(gene)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(optimization)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct WeeklyProtocolRow: View {
    let day: String
    let protocol: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(protocol)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ProtocolDetailsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    warningsSection
                    monitoringSection
                    timingSection
                    successMetricsSection
                }
                .padding()
            }
            .navigationTitle("Protocol Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Critical Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 8) {
                WarningRow(text: "NO iron supplements (overload detected)")
                WarningRow(text: "Check all multivitamins for iron")
                WarningRow(text: "CGM required for berberine monitoring")
                WarningRow(text: "Creatine cycling: 4 weeks on, 1 week off")
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    var monitoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monitoring Requirements", systemImage: "chart.line.uptrend.xyaxis")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                MonitoringRow(metric: "Glucose", frequency: "Continuous (CGM)")
                MonitoringRow(metric: "HRV", frequency: "Daily via Whoop")
                MonitoringRow(metric: "Vitamin D", frequency: "8 weeks")
                MonitoringRow(metric: "Lipid Panel", frequency: "12 weeks")
                MonitoringRow(metric: "Iron Levels", frequency: "Monthly")
            }
        }
    }
    
    var timingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Timing Optimization", systemImage: "clock")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TimingRow(supplement: "Pre-workout", timing: "15 min before training")
                TimingRow(supplement: "Fat-soluble vitamins", timing: "With breakfast fats")
                TimingRow(supplement: "Berberine", timing: "See gradual protocol")
                TimingRow(supplement: "Magnesium", timing: "2.5h after last meal")
                TimingRow(supplement: "Vitamin C", timing: "Split AM/PM doses")
            }
        }
    }
    
    var successMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Success Metrics", systemImage: "target")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                MetricRow(metric: "HbA1c", target: "<5.4%", current: "5.8%")
                MetricRow(metric: "LDL", target: "<130 mg/dL", current: "155")
                MetricRow(metric: "Vitamin D", target: "50-80 ng/mL", current: "34")
                MetricRow(metric: "Recovery", target: ">70%", current: "Variable")
            }
        }
    }
}

// MARK: - Supporting Types

struct TimeSlot {
    let time: String
    let supplements: [Supplement]
}

struct Supplement: Identifiable {
    let id: String
    let name: String
    let dose: String
    let reason: String
    let icon: String
    var isOptional: Bool = false
}

struct WarningRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(text)
                .font(.caption)
        }
    }
}

struct MonitoringRow: View {
    let metric: String
    let frequency: String
    
    var body: some View {
        HStack {
            Text(metric)
                .font(.subheadline)
            Spacer()
            Text(frequency)
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

struct TimingRow: View {
    let supplement: String
    let timing: String
    
    var body: some View {
        HStack {
            Text(supplement)
                .font(.subheadline)
            Spacer()
            Text(timing)
                .font(.caption)
                .foregroundColor(.green)
        }
    }
}

struct MetricRow: View {
    let metric: String
    let target: String
    let current: String
    
    var body: some View {
        HStack {
            Text(metric)
                .font(.subheadline)
            Spacer()
            VStack(alignment: .trailing) {
                Text("Target: \(target)")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("Current: \(current)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Preview

struct SupplementsView_Previews: PreviewProvider {
    static var previews: some View {
        SupplementsView()
            .environmentObject(RecoveryViewModel())
    }
}