module Bumbleworks
  class Console
    class Process
      def ps
        rows = [ %w(name entity position wfid wi-storage) ]

        Bumbleworks.dashboard.ps.each do |ps|
          rows << [
            ps.definition_name,
            entity(ps),
            position(ps),
            ps.wfid,
            ps.stored_workitems.size
          ]
        end

        puts rows.to_table
      end

      def show(wfid)
        ap process(wfid)
      end

      def tree(wfid)
        ap process(wfid).current_tree
      end

      private
      def process(wfid)
        Bumbleworks.dashboard.process(wfid)
      end

      def position(ps)
        ps.position.map do |pos|
          text = "#{pos[1]} #{pos[2]['task']}"
        end.join(',')
      end

      def entity(ps)
        return "" unless ps.workitems && (workitem = ps.workitems.first)

        "%s: %s" % [workitem['entity_type'], workitem['entity_id']]
      end
    end
  end
end
