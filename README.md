# RaftAlgorithmRuby

**RaftAlgorithmRuby** is an implementation of the Raft consensus algorithm in Ruby. This gem allows simulating a distributed system with nodes that can elect leaders, replicate logs, and handle network failures.

---

## Installation

### Requirements
1. **Ruby** version 3.0 or higher.
2. **Bundler** installed globally (`gem install bundler`).

### Steps
1. Clone this repository or download the compressed file.
2. Navigate to the project directory:
   ```bash
   cd raft_algorithm_ruby
   bundle install
3. **Start the Console**:
    ```bash
   ruby bin/console
   
## Explanation
    The `bin/console` script is designed to provide an interactive environment to test and visualize how the Raft consensus algorithm works within the implemented gem. 

    When you run the script, the following actions are performed:

1. **Cluster Initialization**:
    - A cluster of nodes is created with a random size between 1 and 10:
      ```ruby
        @cluster = RaftAlgorithmRuby::Cluster.new(rand(1..10))
      ```
    - This simulates a distributed system with nodes capable of communicating and participating in leader election processes.

2. **Leader Election**:
    - The cluster automatically elects a leader. The leader is responsible for managing the system's state and ensuring consistency across nodes:
      ```ruby
        @leader = @cluster.leader
      ```
    - This showcases the election phase of the Raft algorithm, which ensures a single leader exists at any given time.

3. **Proposing Commands**:
    - The leader can propose commands to the cluster. These commands are replicated across all nodes:
      ```ruby
        @cluster.propose("Set x = #{rand(1..50)}")
      ```
    - This demonstrates the log replication phase of the algorithm, ensuring all nodes agree on a shared state.

4. **Interactive Experimentation**:
    - After the script runs, you can explore the cluster's state, view the nodes' logs, and simulate system behaviors such as node failures or re-elections.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/raft_algorithm_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/raft_algorithm_ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RaftAlgorithmRuby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/raft_algorithm_ruby/blob/main/CODE_OF_CONDUCT.md).
