# frozen_string_literal: true

class RaftAlgorithmRuby::Node
  attr_accessor :id, :state, :log, :peers, :current_term, :voted_for, :total_votes, :heartbeat_timer

  # Initialize the node
  # @param [Integer] id: Unique identifier for the node
  def initialize(id)
    @id = id
    @peers = []
    @state = :follower
    @current_term = 1
    @total_votes = 0
    @voted_for = nil
    @log = []
    @election_timer = nil
    @heartbeat_timer = nil
  end

  ### Peer Management ###

  # Add a peer to the node
  # @param [Node] peer: Another node to add as a peer
  def add_peer(peer)
    @peers << peer unless @peers.include?(peer)
  end

  # Remove a peer from the node
  # @param [Node] peer: Node to remove
  def remove_peer(peer)
    @peers.delete(peer)
  end

  ### State Management ###

  # Transition to a new state
  # @param [Symbol] new_state: The new state (:follower, :candidate, :leader)
  def transition_to(new_state)
    old_state = @state

    append_to_log("Node: #{@id} transitioning from #{old_state} to #{new_state}")

    @state = new_state
    if new_state == :leader
      start_heartbeat_timer
    else
      reset_timers
    end
  end

  ### Election Methods ###

  # Start an election for leadership
  def start_election
    RaftAlgorithmRuby.logger.info "start_election Node: #{@id}, state: #{@state}"
    @current_term += 1
    transition_to(:candidate)
    @total_votes = 1

    RaftAlgorithmRuby.logger.info "Node #{@id}: Starting election for term #{@current_term}."

    @peers.each do |peer|
      if peer.request_votes_from_peer(peer)
        @total_votes += 1
      end
    end

    if @total_votes > (@peers.size + 1) / 2
      RaftAlgorithmRuby.logger.info  "Node #{@id}: Won the election with #{@total_votes} votes."
      transition_to(:leader)
    else
      RaftAlgorithmRuby.logger.error "Node #{@id}: Election failed with #{@total_votes} votes."
      transition_to(:follower) if @state == :candidate
    end
  end

  # send a vote request to peer
  def request_votes_from_peer(peer)
    puts "Node #{@id}: Requesting votes to peer:#{peer.id}, term #{@current_term}."
    reset_timers
    peer.receive_vote_request(peer.id, peer.current_term)
  end

  # Receive a vote request from another node
  # @param [Integer] candidate_id: The ID of the candidate
  # @param [Integer] term: The candidate's term
  # @return [Boolean] True if the vote is granted
  def receive_vote_request(candidate_id, term)
    RaftAlgorithmRuby.logger.info "receive_vote_request, Node: #{@id }, term: #{term}, current_term: #{@current_term}"

    if term > @current_term
      @current_term = term
      @voted_for = nil
    end

    if (@voted_for.nil? || @voted_for == candidate_id) && term >= @current_term
      @voted_for = candidate_id
      puts "Node #{@id}: Voted for Node #{candidate_id} in term #{term}."
      true
    else
      puts "Node #{@id}: Rejected vote for Node #{candidate_id}."
      false
    end
  end

  ### Log Management ###

  # Append a new entry to the log (leader only)
  # @param [String] command: The command to append
  def append_to_log(command)
    RaftAlgorithmRuby.logger.info command
    entry = { term: @current_term, command: command }
    @log << entry
  end

  def propose(command)
    if @state != :leader
      RaftAlgorithmRuby.logger.error "Node #{@id}: Cannot propose, not the leader."
      return false
    end
    @current_term += 1
    append_to_log(command)

    RaftAlgorithmRuby.logger.info "Node #{@id}: Created proposal: #{command}."

    replicate_log(command)
    true
  end

  # reply log for peer
  def replicate_log(command)
    @peers.each do |peer|
      send_append_entries(peer, command)
    end
  end

  # Send AppendEntries RPC to peer
  def send_append_entries(peer, command)
    success = peer.receive_append_entries(@current_term, command)
    if success
      append_to_log(command)
      RaftAlgorithmRuby.logger.info "Node #{@id}: Successfully replicated log to Node #{peer.id}."
    else
      RaftAlgorithmRuby.logger.error "Node #{@id}: Failed to replicate log to Node #{peer.id}. Retrying..."
      false
    end
  end

  # Receive AppendEntries RPC
  def receive_append_entries(term, command)
    if term >= @current_term
      @current_term = term

      append_to_log(command)
      true
    else
      false
    end
  end

  ### Timer Methods ###

  # Start a timer to send heartbeats
  def start_heartbeat_timer
    timeout = rand(0.15..0.3)
    RaftAlgorithmRuby.logger.info "Node #{@id}: Starting heartbeat timer for #{(timeout * 1000).round}ms."

    begin
      if @state != :leader
        puts "Node #{@id}: No heartbeat received within #{(timeout * 1000).round}ms. Starting election."
        @heartbeat_timer = timeout
      else
        puts "Node #{@id}: Timer stopped as the node is now a leader."
      end
    rescue StandardError => e
      RaftAlgorithmRuby.logger.error "In Node #{@id}: #{e.message}"
      RaftAlgorithmRuby.logger.error e.backtrace
    end
  end

  # Reset timers
  def reset_timers
    @election_timer&.kill
    @election_timer = nil
    # @heartbeat_timer&.kill
  end

  # Display information about the node
  def node_info
    puts "Node #{@id}: State: #{@state}, Term: #{@current_term}, Voted For: #{@voted_for || 'None'}, " \
         "Peers: #{@peers.map(&:id).join(', ') || 'No peers'}, " \
         "Logs: #{@log.map { |entry| entry[:command] }.join(', ') || 'No logs'}"
  end
end
