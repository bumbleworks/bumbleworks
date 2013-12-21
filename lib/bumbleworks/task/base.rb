module Bumbleworks
  class Task
    module Base
      def before_update(params); end
      def after_update(params); end

      def before_complete(params); end
      def after_complete(params); end

      def before_claim(token); end
      def after_claim(token); end

      def before_release(token); end
      def after_release(token); end

      def after_dispatch; end

      def completable?
        true
      end

      def not_completable_error_message
        "This task is not currently completable."
      end
    end
  end
end