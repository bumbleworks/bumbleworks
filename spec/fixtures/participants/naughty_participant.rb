class NaughtyParticipant
  class StupidError < StandardError; end
  include Bumbleworks::LocalParticipant

  def on_workitem
    raise StupidError, 'Oh crumb.'
  end
end