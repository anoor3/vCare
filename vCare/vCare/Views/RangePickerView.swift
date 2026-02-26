import SwiftUI

struct RangePickerView: View {
    @Binding var selectedRange: InsightsRange

    var body: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(InsightsRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
}
