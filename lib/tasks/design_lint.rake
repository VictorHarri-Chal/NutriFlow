namespace :design do
  desc "Fail if raw Tailwind colors or hex values leak into views/components"
  task lint: :environment do
    raw_color = /\b(?:bg|text|border|from|to|via|ring)-(?:zinc|gray|slate|neutral|stone|yellow|amber|red|green|blue|emerald|sky|orange|teal|violet|purple)-\d{2,3}\b/
    exceptions = [
      "app/views/home/index.html.erb",
      "app/views/layouts/mailer.html.erb",
      %r{app/views/devise/mailer/},
      %r{app/views/foods/(?:_form|show)\.html\.erb},
    ]
    offenders = Dir.glob("app/{views,components}/**/*.erb").reject do |f|
      exceptions.any? { |e| e.is_a?(Regexp) ? f.match?(e) : f == e }
    end.select { |f| File.read(f).match?(raw_color) }
    if offenders.any?
      abort "Raw colors found in:\n#{offenders.join("\n")}"
    else
      puts "design:lint clean"
    end
  end
end
