# frozen_string_literal: true

require_relative "raft_algorithm_ruby/version"
require_relative "raft_algorithm_ruby/node"
require_relative "raft_algorithm_ruby/cluster"
require 'logger'

module RaftAlgorithmRuby
  class Error < StandardError; end

  def self.logger
    @logger ||= Logger.new($stdout)
  end

  logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}] #{severity}: #{msg}\n"
  end
end
