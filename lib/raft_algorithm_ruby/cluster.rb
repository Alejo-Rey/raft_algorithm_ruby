# frozen_string_literal: true

require_relative "partition"
class RaftAlgorithmRuby::Cluster

  attr_accessor :nodes, :leaders, :partitions

  # @param [Integer] size: Number of nodes to create in the cluster
  def initialize(size = 1)
    @partitions = []
    @nodes = []
    @leaders = []

    create_nodes(size)
  end

  # Create nodes and add them to the cluster
  # @param [Integer] size: Number of nodes to create
  def create_nodes(size)
    nodes = (1..size).map { |id| RaftAlgorithmRuby::Node.new(id) }
    create_partition(nodes)
  end

  def propose(command)
    if @leaders.empty?
      RaftAlgorithmRuby.logger.error "No leader to propose the command."
      return false
    end

    @leaders.all? { |leader| leader.propose(command) }
  end

  # @param [Array[nodes]] nodes
  # @return [Object<Partition>]
  def create_partition(nodes)
    # remove previous connections
    unless @partitions.empty?
      @partitions.each do |partition|
        partition_nodes = partition.nodes.to_set
        new_nodes = nodes.to_set

        partition.nodes.each do |node|
          node.peers.reject! { |peer| new_nodes.include?(peer) }
        end

        nodes.each do |node|
          node.peers.reject! { |peer| partition_nodes.include?(peer) }
        end

        partition.nodes.reject! { |node| new_nodes.include?(node) }
      end
    end

    partition = RaftAlgorithmRuby::Partition.new(nodes, self)
    @partitions.map(&:monitor_elections_and_heartbeats)
    @partitions << partition

    partition
  rescue StandardError => e
    RaftAlgorithmRuby.logger.error "Fail creating partition: #{e.message}"
    RaftAlgorithmRuby.logger.error e.backtrace
  end

  # @return [Array[nodes]] with state :leader
  def leaders
    @leaders = partitions.map(&:leader)
    RaftAlgorithmRuby.logger.info "Leaders: #{@leaders.map(&:id)}"
    @leaders
  end

  # @return [Array[nodes]]
  def nodes
    @partitions.flat_map(&:nodes)
  end

  # Display information about the cluster
  def cluster_info
    @partitions.each_with_index do |partition, index|
      puts "Partition #{index + 1}:"
      partition.partition_info
    end
    true
  end

  def cluster_nodes_logs
    nodes.each do |node|
      puts "Node #{node.id}: Term: #{node.current_term}, logs: #{node.log}"
    end
    @leaders.each do |leader|
      puts "Current Leader: #{leader.id}" if leader
    end
    puts "No leader" if @leaders.empty?
  end
end
