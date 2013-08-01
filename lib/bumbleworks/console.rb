require 'text-table'
require 'bumbleworks/console/process'
require 'bumbleworks/console/task'

module Bumbleworks
  class Console
    delegate :ps, :show, :tree, :to => :@process
    delegate :tasks, :to => :@task

    def initialize
      @process = Process.new
      @task = Task.new
    end

    def help
      puts <<-PROMPT
    Process commands:
      ps: List status for all processes
      show wfid: Show process details by wfid
      tree wfid: Show expression tree for selected process
      tasks {wfid}: Show all tasks or tasks for specific wfid
      db: dashboard
      sp: storage participant
    PROMPT
    end

    def db
      Bumbleworks.dashboard
    end

    def sp
      db.storage_participant
    end
  end
end
