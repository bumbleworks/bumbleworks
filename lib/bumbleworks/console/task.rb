module Bumbleworks
  class Console
    class Task
      def tasks(wfid=nil)
        grouped_by_wfid(wfid).each do |wfid, list|
          puts "\nTasks for WFID: %s" % wfid
          rows =  [%w(participant entity task)]
          list.each do |task|
            rows << [
              task.participant_name,
              entity(task),
              task.nickname
            ]
          end
          puts rows.to_table(:first_row_is_head => true)
        end
        nil
      end

      private
      def grouped_by_wfid(wfid=nil)
        list = Bumbleworks::Task.all
        list.select!{|t| t.wfid == wfid} if wfid
        list.group_by(&:wfid)
      end

      def entity(task)
        "%s: %s" % [task['entity_type'], task['entity_id']]
      end
    end
  end
end
