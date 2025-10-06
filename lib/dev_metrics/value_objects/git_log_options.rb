# frozen_string_literal: true

module DevMetrics
  module ValueObjects
    # Value object for git log command options
    class GitLogOptions
      attr_reader :format, :since, :until_date, :author, :grep, :file,
                  :numstat, :name_only, :oneline, :all

      def initialize(
        format: nil,
        since: nil,
        until_date: nil,
        author: nil,
        grep: nil,
        file: nil,
        numstat: false,
        name_only: false,
        oneline: false,
        all: false
      )
        @format = format
        @since = since
        @until_date = until_date
        @author = author
        @grep = grep
        @file = file
        @numstat = numstat
        @name_only = name_only
        @oneline = oneline
        @all = all
      end

      def self.from_hash(hash)
        return new if hash.nil? || hash.empty?

        new(
          format: hash[:format],
          since: hash[:since],
          until_date: hash[:until_date],
          author: hash[:author],
          grep: hash[:grep],
          file: hash[:file],
          numstat: hash[:numstat] || false,
          name_only: hash[:name_only] || false,
          oneline: hash[:oneline] || false,
          all: hash[:all] || false
        )
      end
    end
  end
end
