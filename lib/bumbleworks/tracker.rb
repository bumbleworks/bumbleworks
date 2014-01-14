module Bumbleworks
  class Tracker
    attr_reader :id, :original_hash

    def initialize(id, original_hash = nil)
      @id = id
      @original_hash = original_hash || Bumbleworks.dashboard.get_trackers[id]
    end

    def wfid
      wfid = fei ? fei['wfid'] : @original_hash['wfid']
    end

    def process
      if wfid_from_hash = wfid
        Bumbleworks::Process.new(wfid_from_hash)
      end
    end

    def global?
      @original_hash['wfid'].nil?
    end

    def conditions
      @original_hash['conditions'] || {}
    end

    def tags
      [conditions['tag']].flatten.compact
    end

    def action
      @original_hash['action']
    end

    def waiting_expression
      return nil unless fei
      process.expressions.detect { |e| e.fei.expid == fei['expid'] }.tree
    end

    def where_clause
      we = waiting_expression
      return nil unless we
      we[1]['where']
    end

  private

    def fei
      @original_hash['msg']['fei']
    end
  end
end
