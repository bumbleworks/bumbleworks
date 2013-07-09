module Bumbleworks
  module Tasks
    module Base
      def before_update(params)
      end

      def after_update(params)
      end

      def before_complete(params)
      end

      def after_complete(params)
      end

      def after_dispatch
      end

      def completable?
        true
      end
    end
  end
end