# frozen_string_literal: true

class RaftAlgorithmRuby::Partition
  attr_accessor :nodes, :leader, :cluster

  def initialize(nodes, cluster)
    @nodes = nodes
    @cluster = cluster
    @leader = nil

    assign_peers
    monitor_elections_and_heartbeats
  end

  def assign_peers
    @nodes.each do |node|
      node.peers = @nodes.reject { |n| n == node }
    end
  end

  # Add a node to the cluster
  # @param [RaftAlgorithmRuby::Node] node: Node to add
  def add_node(node)
    @partitions.first.nodes << node
    @partitions.first.assign_peers
  end


  # Start a leader election process
  def monitor_elections_and_heartbeats
    threads = []
    @nodes.each do |node|
      threads << Thread.new do
        node.start_heartbeat_timer
      end
    end
    threads.each(&:join)

    # TODO: check threads start_heartbeat_timer
    # this is a simulation of the first node with the lowest time
    node_with_min_timer = @nodes.min_by(&:heartbeat_timer)

    RaftAlgorithmRuby.logger.info "Lowest time Nodo: #{node_with_min_timer.id}, time: #{node_with_min_timer.heartbeat_timer}"

    node_with_min_timer.start_election

    # RaftAlgorithmRuby.logger.info "node_with_min_timer: #{node_with_min_timer.total_votes}"
    loop do
      sleep(0.1)

      @leader = @nodes.find { |node| node.state == :leader }
      # @leader = determine_leader_from_votes

      if @leader
        RaftAlgorithmRuby.logger.info "Node #{@leader.id} has been elected as the leader."
        break
      end
    end
    @leader
  end

  def partition_info
    @nodes.each do |node|
      puts "Node #{node.id}: State: #{node.state}, Term: #{node.current_term}, Peers: #{node.peers.map(&:id)}, Logs: #{node.log}"
    end
    puts "Current Leader: #{@leader&.id || 'No leader'}"
  end
end
