# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RaftAlgorithmRuby::Partition do
  let(:cluster) { RaftAlgorithmRuby::Cluster.new(3) }
  let(:node1) { cluster.nodes[0] }
  let(:node2) { cluster.nodes[1] }
  let(:node3) { cluster.nodes[2] }
  let(:partition) { cluster.partitions.first }

  describe '#initialize' do
    it 'initializes with nodes, cluster and leader' do
      expect(partition.nodes).to include(node1, node2, node3)
      expect(partition.cluster).to eq(cluster)
      expect(partition.leader).not_to be_nil
    end

    it 'assigns peers to the nodes in the partition' do
      expect(node1.peers).to include(node2, node3)
      expect(node2.peers).to include(node1, node3)
      expect(node3.peers).to include(node1, node2)
    end
  end

  describe '#add_node' do
    let(:new_node) { RaftAlgorithmRuby::Node.new(4) }

    it 'adds a node to the first partition and updates peers' do
      partition.add_node(new_node)
      expect(partition.nodes).to include(new_node)
      expect(new_node.peers).to include(node1, node2, node3)
      expect(node1.peers).to include(new_node)
    end
  end

  describe '#monitor_elections_and_heartbeats' do
    it 'elects a leader based on the lowest heartbeat timer' do
      allow(node1).to receive(:heartbeat_timer).and_return(0.2)
      allow(node2).to receive(:heartbeat_timer).and_return(0.3)
      allow(node3).to receive(:heartbeat_timer).and_return(0.4)

      allow(node1).to receive(:start_heartbeat_timer)
      allow(node2).to receive(:start_heartbeat_timer)
      allow(node3).to receive(:start_heartbeat_timer)

      allow(node1).to receive(:start_election).and_call_original
      allow(node1).to receive(:state).and_return(:leader)

      partition.monitor_elections_and_heartbeats
      expect(partition.leader).to eq(node1)
    end
  end

  describe '#partition_info' do
    it 'prints partition and leader information' do
      expect { partition.partition_info }.to output(/Node 1: State: follower/).to_stdout
    end
  end
end
