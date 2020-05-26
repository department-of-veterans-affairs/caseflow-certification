# frozen_string_literal: true

describe "SQLHelpers" do
  include SQLHelpers

  context "#to_sql_query_hash" do
    let(:statements) { ["-- @QUERY_NAME: some_unique_name \n  SELECT * FROM 'appeals'"] }
    context "one unique query name" do
      it "identifies query with specified @QUERY_NAME" do
        query_hash = to_sql_query_hash(statements)
        expect(query_hash["some_unique_name"]).to eq statements.first
      end
    end
    context "queries with the same query name" do
      let(:statements) do
        [
          "-- @QUERY_NAME: some_unique_name\n  SELECT * FROM 'appeals'",
          "-- @QUERY_NAME: some_unique_name \n  SELECT * FROM 'request_issues'"
        ]
      end
      it "identifies last query with specified @QUERY_NAME" do
        query_hash = to_sql_query_hash(statements)
        expect(query_hash.count).to eq 1
        expect(query_hash["some_unique_name"]).to eq statements.last
      end
    end
    context "query name does not occur" do
      it "returns nil" do
        query_hash = to_sql_query_hash(statements)
        expect(query_hash.count).to eq 1
        expect(query_hash["non_existent_name"]).to eq nil
      end
    end
  end
end
