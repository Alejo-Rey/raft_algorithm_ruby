# frozen_string_literal: true

require "spec_helper"

RSpec.describe RaftAlgorithmRuby::Cluster do
  let(:cluster) { described_class.new(3) }
  let(:nodes) { cluster.nodes }
  let(:node1) { nodes.first }
  let(:node2) { nodes[1] }
  let(:node3) { nodes.last }

  describe "#initialize" do
    it "initializes the cluster with partitions, nodes, and leaders" do
      expect(cluster.partitions).not_to be_empty
      expect(cluster.nodes.size).to eq(3)
      expect(cluster.leaders).not_to be_empty
    end
  end

  describe "#create_nodes" do
    it "creates the specified number of nodes" do
      cluster.create_nodes(2)
      expect(cluster.nodes.size).to eq(5) # 3 existing nodes + 2 new
    end
  end

  describe "#create_partition" do
    it "creates a new partition with specified nodes" do
      partition_nodes = [node1, node2]
      partition = cluster.create_partition(partition_nodes)

      expect(cluster.partitions).to include(partition)
      expect(partition.nodes).to match_array(partition_nodes)
    end

    it "removes peer connections between partitions" do
      partition_nodes = [node1, node2]
      cluster.create_partition(partition_nodes)

      expect(node3.peers).not_to include(node1, node2)
      expect(node1.peers).not_to include(node3)
    end
  end

  describe "#leaders" do
    it "retrieves leaders from all partitions" do
      partition = cluster.partitions.first
      allow(partition).to receive(:leader).and_return(node1)

      cluster.leaders
      expect(cluster.leaders).to include(node1)
    end
  end

  describe "#propose" do
    context "when there is no leader" do
      it "logs an error and returns false" do
        expect(RaftAlgorithmRuby.logger).to receive(:error).with("No leader to propose the command.")
        expect(cluster.propose("command")).to eq(false)
      end
    end

    context "when there are leaders" do
      before do
        partition1 = cluster.partitions.first
        partition2 = cluster.partitions.last

        allow(partition1).to receive(:leader).and_return(node1)
        allow(partition2).to receive(:leader).and_return(node3)

        allow(node1).to receive(:state).and_return(:leader)
        allow(node3).to receive(:state).and_return(:leader)
        allow(node1).to receive(:propose).and_return(true)
        allow(node3).to receive(:propose).and_return(true)

        cluster.leaders
      end

      it "proposes the command to all leaders and returns true" do
        result = cluster.propose("command")
        expect(result).to eq(true)
      end
    end
  end

  describe "#cluster_info" do
    it "displays information about all partitions" do
      partition = cluster.partitions.first
      allow(partition).to receive(:partition_info).and_return(true)

      expect(cluster.cluster_info).to be true
    end
  end
end
