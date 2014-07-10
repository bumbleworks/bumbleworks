module Bumbleworks
  class Schedule
    attr_reader :id, :original_hash

    class << self
      def all
        Bumbleworks.dashboard.schedules.map do |hsh|
          new(hsh)
        end
      end

      def count
        all.count
      end
    end

    def initialize(schedule_hash)
      @original_hash = schedule_hash
      @id = @original_hash['_id']
    end

    def ==(other)
      @id == other.id
    end

    def wfid
      @original_hash['wfid']
    end

    def process
      Bumbleworks::Process.new(wfid)
    end

    def expression
      Bumbleworks::Expression.from_fei(@original_hash['owner'])
    end

    def repeating?
      ['cron', 'every'].include? expression.tree[0]
    end

    def once?
      !repeating?
    end

    def next_at
      Time.parse(@original_hash['at'])
    end

    def original_plan
      @original_hash['original']
    end

    def test_clause
      expression.tree[1]['test']
    end
  end
end
