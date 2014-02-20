module Bumbleworks
  module User
    class NoRoleIdentifiersMethodDefined < StandardError; end
    class NoClaimTokenMethodDefined < StandardError; end
    class UnauthorizedClaimAttempt < StandardError; end
    class UnauthorizedReleaseAttempt < StandardError; end

    # The return value from this method is used as the "claimant" token on
    # tasks, both for claiming a task and for checking if the user is the
    # current claimant.
    #
    # By default, claim_token will first check for `username`, then `email`, and
    # finally raise an exception if neither method exists.  Including classes
    # should override this method if using something other than username or
    # email (or if both respond, but email should be preferred).
    def claim_token
      [:username, :email].each do |token_method|
        return send(token_method) if respond_to?(token_method)
      end
      raise NoClaimTokenMethodDefined,
        "If your user class does not respond to :username or :email, define a `claim_token` method"
    end

    # The return value from this method is used when determining which tasks in
    # the queue this user should be authorized for.  Must return an array of
    # strings.
    def role_identifiers
      raise NoRoleIdentifiersMethodDefined,
        "Define a `role_identifiers` method that returns an array of role names"
    end

    # Returns true if the array returned by #role_identifiers includes the given
    # name.  Can be used to determine authority to perform actions on a task,
    # for example.
    def has_role?(role_name)
      role_identifiers.include? role_name
    end

    # Attempts to set self as the claimant of the given task.  If not authorized
    # to claim the task, raises exception.  Also bubbles exception from Task
    # when task is already claimed by a different claimant.
    def claim(task, force = false)
      raise UnauthorizedClaimAttempt unless has_role?(task.role)
      release!(task) if force
      task.claim(claim_token)
    end

    # Same as #claim, but first releases (by force) the task, to avoid an
    # AlreadyClaimed exceptions.  Note that this may still raise an
    # UnauthorizedClaimAttempt exception - this method does not allow a user
    # to claim a task they are not authorized for.  Should only be made
    # available to supervisory roles.
    def claim!(task)
      claim(task, true)
    end

    # If we are the current claimant of the given task, release the task. Does
    # nothing if the task is not claimed, but raises exception if the task is
    # currently claimed by someone else.
    def release(task, force = false)
      return unless task.claimed?
      raise UnauthorizedReleaseAttempt unless force || task.claimant == claim_token
      task.release
    end

    # Same as #release, but releases the task even if we're not the current
    # claimant.  Allows an administrator, for example, to wrench a task away
    # from an employee who is lagging.  Should only be made available to
    # supervisory roles.
    def release!(task)
      release(task, true)
    end

    # Returns Task::Finder instance filtered by roles assigned to this user.
    def authorized_tasks
      Bumbleworks::Task.for_roles(role_identifiers)
    end

    # Returns Task::Finder instance filtered by user roles and availability
    # (unclaimed and completable).
    def available_tasks
      authorized_tasks.available
    end

    # Returns Task::Finder instance filtered by claimant - only tasks this user
    # has claimed (and not released or completed).
    def claimed_tasks
      Bumbleworks::Task.for_claimant(claim_token)
    end
  end
end