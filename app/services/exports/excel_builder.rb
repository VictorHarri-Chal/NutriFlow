module Exports
  # Turns any list of { name:, tables: [{ title:, headers:, rows: }] }
  # sheets (the shape every exporter returns) into one .xlsx workbook.
  class ExcelBuilder
    MAX_SHEET_NAME_LENGTH = 31

    def initialize(sheets)
      @sheets = sheets
    end

    def build
      package  = Axlsx::Package.new
      workbook = package.workbook
      used_names = Hash.new(0)

      title_style  = workbook.styles.add_style(b: true, sz: 12)
      header_style = workbook.styles.add_style(b: true, bg_color: "27272A", fg_color: "F4F4F5")

      @sheets.each do |sheet|
        workbook.add_worksheet(name: unique_name(sheet[:name], used_names)) do |ws|
          sheet[:tables].each_with_index do |table, index|
            ws.add_row [table[:title]], style: title_style if table[:title].present?
            ws.add_row table[:headers], style: header_style
            table[:rows].each { |row| ws.add_row row }
            ws.add_row [] if index < sheet[:tables].size - 1
          end
        end
      end

      package.to_stream.read
    end

    private

    # Excel sheet names are capped at 31 chars and must be unique — truncate,
    # then append " (2)", " (3)"... on any repeat (two exporters could in
    # theory produce the same sheet name if the registry ever grows).
    def unique_name(raw_name, used_names)
      base = raw_name.to_s[0, MAX_SHEET_NAME_LENGTH]
      used_names[base] += 1
      return base if used_names[base] == 1

      suffix = " (#{used_names[base]})"
      "#{base[0, MAX_SHEET_NAME_LENGTH - suffix.length]}#{suffix}"
    end
  end
end
