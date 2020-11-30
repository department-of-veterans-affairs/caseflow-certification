# frozen_string_literal: true

namespace :sql do
  desc "validate SQL queries against Rails queries"
  task validate: :environment do
    puts "TODO: query Metabase queries"
    query_dir = "tmp/railsSqlComparison"
    puts "TODO: populate query_dir with relevant queries"
    diff_queries = ValidateSqlQueries.process(query_dir)
    puts "Diffs: #{diff_queries}"
  end
end
