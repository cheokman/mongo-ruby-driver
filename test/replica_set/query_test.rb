require 'test_helper'

class ReplicaSetQueryTest < Test::Unit::TestCase

  def setup
    ensure_cluster(:rs)
    @conn = ReplSetConnection.new @rs.repl_set_seeds
    @db = @conn.db(MONGO_TEST_DB)
    @db.drop_collection("test-sets")
    @coll = @db.collection("test-sets")
  end

  def teardown
    @conn.close if @conn
  end

  def self.shutdown
    @@cluster.stop
    @@cluster.clobber
  end

  def test_query
    @coll.save({:a => 20}, :safe => {:w => 3})
    @coll.save({:a => 30}, :safe => {:w => 3})
    @coll.save({:a => 40}, :safe => {:w => 3})
    results = []
    @coll.find.each {|r| results << r}
    [20, 30, 40].each do |a|
      assert results.any? {|r| r['a'] == a}, "Could not find record for a => #{a}"
    end

    #puts "Benchmark before failover: #{benchmark_queries}"

    @rs.primary.stop

    results = []
    rescue_connection_failure do
      @coll.find.each {|r| results << r}
      [20, 30, 40].each do |a|
        assert results.any? {|r| r['a'] == a}, "Could not find record for a => #{a}"
      end

    #puts "Benchmark after failover: #{benchmark_queries}"
    end
  end

  def benchmark_queries
    t1 = Time.now
    10000.times { @coll.find_one }
    Time.now - t1
  end

end
