class DataExportJob < ApplicationJob
  queue_as :default

  # If the DataExport was pruned before the job ran, there's nothing to build —
  # drop the job quietly instead of logging a failed execution.
  discard_on ActiveJob::DeserializationError

  # Builds the .xlsx off the request cycle so a heavy export (thousands of rows)
  # never ties up a web thread. Re-filters the stored category keys through the
  # registry so a category the user has since disabled can't slip back in.
  def perform(data_export)
    data_export.update!(status: "processing")

    user = data_export.user
    categories = Exports::CategoryRegistry.visible_for(user)
                                          .select { |c| data_export.categories.include?(c[:key]) }
    sheets = categories.flat_map { |c| c[:exporter].new(user: user, period: data_export.period).sheets }
    xlsx = Exports::ExcelBuilder.new(sheets).build

    data_export.file.attach(
      io: StringIO.new(xlsx),
      filename: "nutriflow-export-#{data_export.created_at.to_date.iso8601}.xlsx",
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    data_export.update!(status: "completed")
  rescue StandardError => e
    data_export.update!(status: "failed", error_message: e.message)
    raise
  end
end
