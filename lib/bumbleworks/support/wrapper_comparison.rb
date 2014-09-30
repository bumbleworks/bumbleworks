module Bumbleworks
  module Support
    module WrapperComparison
      def identifier_for_comparison
        id
      end

      def hash
        identifier_for_comparison.hash
      end

      def ==(other)
        other.is_a?(self.class) &&
          identifier_for_comparison &&
          identifier_for_comparison == other.identifier_for_comparison
      end

      def eql?(other)
        self == other
      end
    end
  end
end
