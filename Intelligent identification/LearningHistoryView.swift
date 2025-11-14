import SwiftUI

struct LearningHistoryView: View {
    @EnvironmentObject private var learningStore: LearningRecordStore
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Group {
            if learningStore.records.isEmpty {
                EmptyState()
            } else {
                List {
                    ForEach(learningStore.records) { record in
                        LearningHistoryRow(record: record, dateFormatter: dateFormatter)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteRecords)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(AppTheme.appBackground.ignoresSafeArea())
            }
        }
        .navigationTitle("学习记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !learningStore.records.isEmpty {
                EditButton()
            }
        }
        .background(AppTheme.appBackground.ignoresSafeArea())
    }
    
    private func deleteRecords(at offsets: IndexSet) {
        for index in offsets {
            let record = learningStore.records[index]
            learningStore.remove(record)
        }
    }
    
    private struct EmptyState: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.accent)
                Text("还没有学习记录")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text("识别物体后，我们会把词汇、翻译等信息自动保存到这里。")
                    .font(.body)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.appBackground.ignoresSafeArea())
        }
    }
}

private struct LearningHistoryRow: View {
    let record: LearningRecord
    let dateFormatter: DateFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.learningTranslation)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(record.nativeTranslation)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(record.objectName.capitalized)
                        .font(.caption)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                Spacer()
                Text(dateFormatter.string(from: record.createdAt))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                .stroke(AppTheme.divider.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: AppTheme.shadowColor.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

