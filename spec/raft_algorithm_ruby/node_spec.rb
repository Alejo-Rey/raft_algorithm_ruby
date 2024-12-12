# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RaftAlgorithmRuby::Node do
  let(:node) { described_class.new(1) }
  let(:peer1) { described_class.new(2) }
  let(:peer2) { described_class.new(3) }

  describe '#initialize' do
    it 'initializes with the correct default values' do
      expect(node.id).to eq(1)
      expect(node.state).to eq(:follower)
      expect(node.current_term).to eq(1)
      expect(node.total_votes).to eq(0)
      expect(node.voted_for).to be_nil
      expect(node.log).to eq([])
      expect(node.peers).to eq([])
    end
  end

  describe '#add_peer' do
    it 'adds a peer to the node' do
      node.add_peer(peer1)
      expect(node.peers).to include(peer1)
    end

    it 'does not add the same peer twice' do
      node.add_peer(peer1)
      node.add_peer(peer1)
      expect(node.peers.size).to eq(1)
    end
  end

  describe '#remove_peer' do
    it 'removes a peer from the node' do
      node.add_peer(peer1)
      node.remove_peer(peer1)
      expect(node.peers).not_to include(peer1)
    end
  end

  describe '#transition_to' do
    it 'transitions the node to a new state' do
      node.transition_to(:candidate)
      expect(node.state).to eq(:candidate)
    end

    it 'starts the heartbeat timer when transitioning to leader' do
      expect(node).to receive(:start_heartbeat_timer)
      node.transition_to(:leader)
    end

    it 'resets timers when transitioning away from leader' do
      expect(node).to receive(:reset_timers)
      node.transition_to(:follower)
    end
  end

  describe '#append_to_log' do
    it 'appends a command to the log' do
      command = 'Set x = 10'
      node.append_to_log(command)
      expect(node.log.last[:command]).to eq(command)
    end
  end

  describe '#propose' do
    it 'does not propose if not the leader' do
      expect(node.propose('Set y = 20')).to be false
    end

    it 'proposes a command if the node is the leader' do
      node.transition_to(:leader)
      expect(node.propose('Set y = 20')).to be true
      expect(node.log.last[:command]).to eq('Set y = 20')
    end
  end

  describe '#replicate_log' do
    it 'sends log entries to all peers' do
      node.transition_to(:leader)
      node.add_peer(peer1)
      node.add_peer(peer2)
      expect(peer1).to receive(:receive_append_entries).with(node.current_term, 'Set z = 30')
      expect(peer2).to receive(:receive_append_entries).with(node.current_term, 'Set z = 30')
      node.replicate_log('Set z = 30')
    end
  end

  describe '#receive_vote_request' do
    it 'votes for the candidate if conditions are met' do
      expect(node.receive_vote_request(2, 2)).to be true
      expect(node.voted_for).to eq(2)
    end

    it 'rejects the vote if the term is less than current term' do
      expect(node.receive_vote_request(2, 0)).to be false
    end
  end

  describe '#receive_append_entries' do
    it 'accepts and appends entries if term is valid' do
      expect(node.receive_append_entries(2, 'Command1')).to be true
      expect(node.log.last[:command]).to eq('Command1')
    end

    it 'rejects entries if term is outdated' do
      node.current_term = 3
      expect(node.receive_append_entries(2, 'Command2')).to be false
    end
  end

  describe '#node_info' do
    it 'prints the node information' do
      expect { node.node_info }.to output(/Node 1: State: follower/).to_stdout
    end
  end
end
