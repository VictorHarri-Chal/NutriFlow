module Exports
  # Every exporter returns an array of sheets shaped as
  # { name:, tables: [{ title:, headers:, rows: }] }. Most exporters only
  # ever need one table per sheet — this builds that common shape so they
  # don't all repeat the same wrapping hash.
  class Sheet
    def self.simple(name:, headers:, rows:)
      { name: name, tables: [{ title: nil, headers: headers, rows: rows }] }
    end
  end
end
