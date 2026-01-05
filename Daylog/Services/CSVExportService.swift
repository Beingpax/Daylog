//
//  CSVExportService.swift
//  Daylog
//

import Foundation

struct CSVExportService {

    func exportLogs(_ logs: [HourLog]) -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var csvContent = "date,hour,category_group,category,notes,mood,extra_details\n"

        for log in logs {
            let dateString = dateFormatter.string(from: log.date)
            let hour = log.hour
            let categoryGroup = log.category?.group?.name ?? ""
            let category = log.category?.name ?? ""
            let notes = escapeCSVField(log.notes)
            let mood = log.mood?.rawValue ?? ""
            let extraDetails = escapeCSVField(log.extraDetails)

            csvContent += "\(dateString),\(hour),\(categoryGroup),\(category),\(notes),\(mood),\(extraDetails)\n"
        }

        let fileName = "daylog_export_\(dateFormatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    private func escapeCSVField(_ field: String) -> String {
        var escaped = field
        if escaped.contains("\"") || escaped.contains(",") || escaped.contains("\n") {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
}
