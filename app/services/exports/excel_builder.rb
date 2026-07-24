module Exports
  # Turns any list of { name:, tables: [{ title:, headers:, rows: }] }
  # sheets (the shape every exporter returns) into one .xlsx workbook.
  class ExcelBuilder
    MAX_SHEET_NAME_LENGTH = 31

    # Detail tables with at least this many rows get their fully-empty columns
    # dropped (e.g. a "Fibres" column that is 0/blank for every food). Summary
    # tables (fewer rows) keep every column, so a legitimate "0" KPI is never
    # hidden.
    MIN_ROWS_FOR_COLUMN_PRUNING = 2

    def initialize(sheets)
      @sheets = sheets
    end

    def build
      package  = Axlsx::Package.new
      workbook = package.workbook
      used_names = Hash.new(0)

      title_style    = workbook.styles.add_style(b: true, sz: 12)
      header_style   = workbook.styles.add_style(b: true, bg_color: "27272A", fg_color: "F4F4F5")
      date_style     = workbook.styles.add_style(format_code: "dd/mm/yyyy")
      datetime_style = workbook.styles.add_style(format_code: "dd/mm/yyyy hh:mm")

      @sheets.each do |sheet|
        workbook.add_worksheet(name: unique_name(sheet[:name], used_names)) do |ws|
          sheet[:tables].each_with_index do |table, index|
            headers, rows = prune_empty_columns(table[:headers], table[:rows])

            ws.add_row [table[:title]], style: title_style if table[:title].present?
            ws.add_row headers, style: header_style
            rows.each { |row| ws.add_row row, style: row_styles(row, date_style, datetime_style) }
            ws.add_row [] if index < sheet[:tables].size - 1
          end
        end
      end

      package.to_stream.read
    end

    private

    # Per-cell style so date/datetime columns render as dd/mm/yyyy (French) and,
    # crucially, keep their time component visible (e.g. fasting start/end) —
    # without an explicit format code the viewer picks its own, often hiding the
    # time or showing a US m/d/y order.
    def row_styles(row, date_style, datetime_style)
      row.map do |value|
        case value
        when Time, DateTime, ActiveSupport::TimeWithZone then datetime_style
        when Date                                        then date_style
        else 0
        end
      end
    end

    # Drops columns that carry no information (every cell nil/blank/zero) from
    # detail tables only. Header-only or tiny (summary) tables are left intact.
    def prune_empty_columns(headers, rows)
      return [headers, rows] if rows.size < MIN_ROWS_FOR_COLUMN_PRUNING

      keep = headers.each_index.reject do |col|
        rows.all? { |row| blank_cell?(row[col]) }
      end
      return [headers, rows] if keep.size == headers.size

      [keep.map { |i| headers[i] }, rows.map { |row| keep.map { |i| row[i] } }]
    end

    def blank_cell?(value)
      value.nil? || value == 0 || value == 0.0 || value.to_s.strip.empty?
    end

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
