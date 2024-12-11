# frozen_string_literal: true

class RaftAlgorithmRuby::Cluster

  attr_accessor :nodes, :leader

  # @param [Integer] size: Number of nodes to create in the cluster
  def initialize(size = 1)
    @nodes = []
    @leader = nil

    create_nodes(size)
    assign_peers
    monitor_heartbeat_and_elect_leader
  end

  # Create nodes and add them to the cluster
  # @param [Integer] size: Number of nodes to create
  def create_nodes(size)
    (1..size).each do |id|
      @nodes << RaftAlgorithmRuby::Node.new(id)
    end
  end

  # Add a node to the cluster
  # @param [RaftAlgorithmRuby::Node] node: Node to add
  def add_node(node)
    @nodes << node
    assign_peers # Update peers after adding a node
  end

  # Assign peers to all nodes in the cluster
  # @return [Array]
  def assign_peers
    @nodes.each do |node|
      node.peers = @nodes.reject { |n| n == node }
    end
  end

  # Start a leader election process
  def monitor_heartbeat_and_elect_leader
    @nodes.each do |node|
      Thread.new do
        node.start_heartbeat_timer
      end
    end

    # todo: check threads start_heartbeat_timer
    # this is a simulation of the first node with the minor time
    node_with_min_timer = @nodes.min_by(&:heartbeat_timer)
    node_with_min_timer.start_election

    RaftAlgorithmRuby.logger.info "node_with_min_timer: #{node_with_min_timer.total_votes}"
    loop do
      sleep(0.1)
      @leader = determine_leader_from_votes

      if @leader
        # todo: add log in nodes
        RaftAlgorithmRuby.logger.info "Node #{@leader.id} has been elected as the leader."
        break
      end
    end
  end

  ### Leader Election ###
  def determine_leader_from_votes
    node_with_most_votes = @nodes.max_by(&:total_votes)

    if node_with_most_votes.total_votes > (@nodes.size / 2)
      @nodes.each { |node| node.transition_to(:follower) unless node == node_with_most_votes }
      node_with_most_votes.transition_to(:leader)
      node_with_most_votes

      puts "Node #{node_with_most_votes.id} has been elected as the leader with #{node_with_most_votes.total_votes} votes."
      node_with_most_votes
    else
      puts "No leader elected. Votes: #{@nodes.map { |node| [node.id, node.total_votes] }.to_h}"
      nil
    end
  end

  def propose(command)
    if @leader.nil?
      puts "No leader to propose the command."
      return false
    end

    @leader.propose(command)
  end

  # Display information about the cluster
  def cluster_info
    @nodes.each do |node|
      puts "Node #{node.id}: State: #{node.state}, Term: #{node.current_term}, Peers: #{node.peers.map(&:id)}, logs: #{node.log}"
    end
    puts "Current Leader: #{@leader&.id || 'No leader'}"
  end

  def cluster_nodes_logs
    @nodes.each do |node|
      puts "Node #{node.id}: Term: #{node.current_term}, logs: #{node.log}"
    end
    puts "Current Leader: #{@leader&.id || 'No leader'}"
  end
end
