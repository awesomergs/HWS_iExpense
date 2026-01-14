import SwiftUI
import Charts

// Range options: rolling windows + calendar windows
enum StatsRange: String, CaseIterable, Identifiable {
    case last7 = "Last 7 days"
    case last30 = "Last 30 days"
    case last365 = "Last 365 days"
    case thisWeek = "This week"
    case thisMonth = "This month"
    case thisYear = "This year"

    var id: String { rawValue }
}

struct StatRow: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

// ✅ For trends
struct MonthPoint: Identifiable {
    let id = UUID()
    let start: Date
    let label: String
    let total: Double
}

struct WeekPoint: Identifiable {
    let id = UUID()
    let start: Date
    let label: String
    let total: Double
}

// ✅ Pie slice model
struct PieSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

// ✅ Time of day buckets (includes your 11–2 afternoon example)
enum TimeBucket: String, CaseIterable, Identifiable {
    case lateNight = "Late Night (12–4)"
    case morning = "Morning (5–10)"
    case afternoon = "Afternoon (11–2)"
    case evening = "Evening (3–8)"
    case night = "Night (9–11)"

    var id: String { rawValue }

    static func bucket(for hour: Int) -> TimeBucket {
        switch hour {
        case 0...4: return .lateNight
        case 5...10: return .morning
        case 11...14: return .afternoon     // 11–2
        case 15...20: return .evening       // 3–8
        default: return .night              // 9–11
        }
    }
}

struct StatsView: View {
    var expenses: Expenses
    @State private var range: StatsRange = .last30

    // ISO calendar starts week on Monday
    private var isoCalendar: Calendar { Calendar(identifier: .iso8601) }
    private var now: Date { Date() }

    private var startDate: Date {
        switch range {
        case .last7:
            return isoCalendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .last30:
            return isoCalendar.date(byAdding: .day, value: -30, to: now) ?? now
        case .last365:
            return isoCalendar.date(byAdding: .day, value: -365, to: now) ?? now
        case .thisWeek:
            return isoCalendar.date(from: isoCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        case .thisMonth:
            let comps = isoCalendar.dateComponents([.year, .month], from: now)
            return isoCalendar.date(from: DateComponents(year: comps.year, month: comps.month, day: 1)) ?? now
        case .thisYear:
            let y = isoCalendar.component(.year, from: now)
            return isoCalendar.date(from: DateComponents(year: y, month: 1, day: 1)) ?? now
        }
    }

    private var filteredItems: [ExpenseItem] {
        expenses.items
            .filter { $0.date >= startDate && $0.date <= now }
            .sorted { $0.date > $1.date }
    }

    private var currenciesInRange: [String] {
        Array(Set(filteredItems.map { $0.currency })).sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Range", selection: $range) {
                        ForEach(StatsRange.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                } header: {
                    Text("Time Range")
                } footer: {
                    Text("Showing expenses from \(startDate, format: .dateTime.month().day().year()) to \(now, format: .dateTime.month().day().year()).")
                }

                if filteredItems.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No expenses in this range",
                            systemImage: "tray",
                            description: Text("Try a wider range like Last 30 days.")
                        )
                    }
                } else {
                    ForEach(currenciesInRange, id: \.self) { code in
                        let itemsForCurrency = filteredItems.filter { $0.currency == code }

                        let monthTrend = monthByMonthTrend(itemsForCurrency)
                        let weekTrend = weekByWeekTrend(itemsForCurrency)

                        let byStore = pieByStore(itemsForCurrency, topN: 8)
                        let byCategory = pieByCategory(itemsForCurrency)
                        let byTime = pieByTimeBucket(itemsForCurrency)

                        Section {
                            HStack {
                                Text("Total")
                                Spacer()
                                Text(itemsForCurrency.reduce(0) { $0 + $1.amount }, format: .currency(code: code))
                                    .font(.headline)
                            }
                            HStack {
                                Text("Transactions")
                                Spacer()
                                Text("\(itemsForCurrency.count)")
                                    .foregroundStyle(.secondary)
                            }
                        } header: {
                            Text("Overview (\(code))")
                        }

                        Section {
                            TrendChartsView(
                                currencyCode: code,
                                monthPoints: monthTrend,
                                weekPoints: weekTrend
                            )
                        } header: {
                            Text("Trends (\(code))")
                        }

                        // ✅ Pie charts
                        Section {
                            PieOrFallbackView(
                                title: "Spending by Company",
                                slices: byStore,
                                currencyCode: code
                            )
                        }

                        Section {
                            PieOrFallbackView(
                                title: "Spending by Category",
                                slices: byCategory,
                                currencyCode: code
                            )
                        }

                        Section {
                            PieOrFallbackView(
                                title: "Spending by Time of Day",
                                slices: byTime,
                                currencyCode: code
                            )
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Trends (same as before)

    private func monthByMonthTrend(_ items: [ExpenseItem]) -> [MonthPoint] {
        let startOfThisMonth = isoCalendar.date(from: isoCalendar.dateComponents([.year, .month], from: now)) ?? now
        let start = isoCalendar.date(byAdding: .month, value: -11, to: startOfThisMonth) ?? startOfThisMonth

        var buckets: [Date: Double] = [:]
        var monthStarts: [Date] = []

        for i in 0..<12 {
            let mStart = isoCalendar.date(byAdding: .month, value: i, to: start) ?? start
            monthStarts.append(mStart)
            buckets[mStart] = 0
        }

        for item in items {
            let monthStart = isoCalendar.date(from: isoCalendar.dateComponents([.year, .month], from: item.date)) ?? item.date
            if monthStart >= start, monthStart <= startOfThisMonth {
                buckets[monthStart, default: 0] += item.amount
            }
        }

        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM")

        return monthStarts.map { mStart in
            MonthPoint(start: mStart, label: df.string(from: mStart), total: buckets[mStart, default: 0])
        }
    }

    private func weekByWeekTrend(_ items: [ExpenseItem]) -> [WeekPoint] {
        let startOfThisWeek = isoCalendar.date(from: isoCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let start = isoCalendar.date(byAdding: .weekOfYear, value: -11, to: startOfThisWeek) ?? startOfThisWeek

        var buckets: [Date: Double] = [:]
        var weekStarts: [Date] = []

        for i in 0..<12 {
            let wStart = isoCalendar.date(byAdding: .weekOfYear, value: i, to: start) ?? start
            weekStarts.append(wStart)
            buckets[wStart] = 0
        }

        for item in items {
            let weekStart = isoCalendar.date(from: isoCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: item.date)) ?? item.date
            if weekStart >= start, weekStart <= startOfThisWeek {
                buckets[weekStart, default: 0] += item.amount
            }
        }

        let df = DateFormatter()
        df.locale = .current
        df.setLocalizedDateFormatFromTemplate("MMM d")

        return weekStarts.map { wStart in
            WeekPoint(start: wStart, label: df.string(from: wStart), total: buckets[wStart, default: 0])
        }
    }
    
    

    // MARK: - Pie aggregations

    private func pieByStore(_ items: [ExpenseItem], topN: Int) -> [PieSlice] {
        let dict = Dictionary(grouping: items, by: { $0.store })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        let sorted = dict
            .map { PieSlice(label: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }

        guard sorted.count > topN else { return sorted }

        let head = Array(sorted.prefix(topN))
        let otherTotal = sorted.dropFirst(topN).reduce(0) { $0 + $1.value }
        return head + [PieSlice(label: "Other", value: otherTotal)]
    }

    private func pieByCategory(_ items: [ExpenseItem]) -> [PieSlice] {
        let dict = Dictionary(grouping: items, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        return dict
            .map { PieSlice(label: "\($0.key.emoji) \($0.key.rawValue)", value: $0.value) }
            .sorted { $0.value > $1.value }
    }

    private func pieByTimeBucket(_ items: [ExpenseItem]) -> [PieSlice] {
        let cal = Calendar.current

        var totals: [TimeBucket: Double] = [:]
        for item in items {
            let h = cal.component(.hour, from: item.date)
            let bucket = TimeBucket.bucket(for: h)
            totals[bucket, default: 0] += item.amount
        }

        // Keep a stable bucket order, but still sort by value desc if you prefer:
        // return TimeBucket.allCases.map { ... }.filter { ... }
        return TimeBucket.allCases.compactMap { b in
            let v = totals[b, default: 0]
            return v > 0 ? PieSlice(label: b.rawValue, value: v) : nil
        }
    }
}

// MARK: - Trend Charts (unchanged)

struct TrendChartsView: View {
    let currencyCode: String
    let monthPoints: [MonthPoint]
    let weekPoints: [WeekPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Month-by-month (last 12 months)")
                    .font(.headline)

                Chart(monthPoints) { p in
                    BarMark(
                        x: .value("Month", p.label),
                        y: .value("Total", p.total)
                    )
                }
                .frame(height: 180)

                HStack {
                    Text("Total last 12 months")
                    Spacer()
                    Text(monthPoints.reduce(0) { $0 + $1.total }, format: .currency(code: currencyCode))
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Week-by-week (last 12 weeks)")
                    .font(.headline)

                Chart(weekPoints) { p in
                    LineMark(
                        x: .value("Week", p.label),
                        y: .value("Total", p.total)
                    )
                    PointMark(
                        x: .value("Week", p.label),
                        y: .value("Total", p.total)
                    )
                }
                .frame(height: 180)

                HStack {
                    Text("Total last 12 weeks")
                    Spacer()
                    Text(weekPoints.reduce(0) { $0 + $1.total }, format: .currency(code: currencyCode))
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Pie chart + fallback

struct PieOrFallbackView: View {
    let title: String
    let slices: [PieSlice]
    let currencyCode: String

    var body: some View {
        if slices.isEmpty {
            Text("No data.")
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)

                if #available(iOS 17.0, *) {
                    PieChartView(slices: slices)
                        .frame(height: 220)

                    PieLegendView(slices: slices, currencyCode: currencyCode)
                } else {
                    // iOS 16 fallback (keeps the app compiling/running)
                    StatTableFallbackView(rows: slices.map { StatRow(label: $0.label, value: $0.value) },
                                          currencyCode: currencyCode)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

@available(iOS 17.0, *)
struct PieChartView: View {
    let slices: [PieSlice]

    var body: some View {
        Chart(slices) { s in
            SectorMark(
                angle: .value("Amount", s.value),
                innerRadius: .ratio(0.55) // donut style (looks nicer)
            )
        }
        .chartLegend(.hidden)
    }
}

struct PieLegendView: View {
    let slices: [PieSlice]
    let currencyCode: String

    var body: some View {
        let total = slices.reduce(0) { $0 + $1.value }

        VStack(spacing: 8) {
            ForEach(slices) { s in
                HStack {
                    Text(s.label)
                        .lineLimit(1)
                    Spacer()
                    Text(s.value, format: .currency(code: currencyCode))
                        .foregroundStyle(.secondary)
                    Text(total > 0 ? "  \(Int((s.value / total) * 100))%" : "")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
    }
}

// iOS 16 fallback “table” view (simple + clean)
struct StatTableFallbackView: View {
    let rows: [StatRow]
    let currencyCode: String

    var body: some View {
        let sorted = rows.sorted { $0.value > $1.value }
        let maxVal = sorted.map(\.value).max() ?? 1

        VStack(alignment: .leading, spacing: 10) {
            ForEach(sorted) { row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(row.label).lineLimit(1)
                        Spacer()
                        Text(row.value, format: .currency(code: currencyCode))
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        let width = geo.size.width * (row.value / maxVal)
                        RoundedRectangle(cornerRadius: 6)
                            .frame(width: max(width, 4), height: 10)
                            .foregroundStyle(.tint)
                    }
                    .frame(height: 10)
                }
            }
        }
    }
}
